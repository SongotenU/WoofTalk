import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { validateAuth, corsHeaders } from '../_shared/middleware.ts';
import { isEntitlementCacheStale, SubscriptionTier, SubscriptionStatus } from '../_shared/subscription.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // Only accept GET and POST
    if (req.method !== 'GET' && req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const user = await validateAuth(req, supabaseUrl, supabaseKey);

    // Read subscription_status from DB
    const { data: status, error: statusError } = await supabase
      .from('subscription_status')
      .select('*')
      .eq('user_id', user.id)
      .single();

    // Handle missing row — user never had a webhook event
    if (!status) {
      return new Response(JSON.stringify({
        tier: 'free' as SubscriptionTier,
        entitlements: {},
        trial_ends_at: null,
        purchase_platform: 'none',
        cached: true,
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check if cache is stale (D-08)
    if (!isEntitlementCacheStale(status.updated_at)) {
      return new Response(JSON.stringify({
        tier: status.subscription_tier,
        entitlements: status.entitlements,
        trial_ends_at: status.trial_ends_at,
        purchase_platform: status.purchase_platform,
        cached: true,
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Re-fetch from RevenueCat REST API when stale (SUB-06, D-08)
    let rcResponse: Response;
    try {
      rcResponse = await fetch(
        `https://api.revenuecat.com/v1/subscribers/${user.id}`,
        {
          headers: {
            'Authorization': `Bearer ${Deno.env.get('REVENUECAT_API_KEY')}`,
          },
        }
      );
    } catch (fetchError) {
      console.error('RevenueCat API fetch error:', fetchError);
      // Fall back to stale DB data
      return new Response(JSON.stringify({
        tier: status.subscription_tier,
        entitlements: status.entitlements,
        trial_ends_at: status.trial_ends_at,
        purchase_platform: status.purchase_platform,
        cached: true,
        warning: 'cache_stale',
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // On RevenueCat API error, fall back to stale DB data
    if (!rcResponse.ok) {
      console.error(`RevenueCat API error: ${rcResponse.status} ${rcResponse.statusText}`);
      return new Response(JSON.stringify({
        tier: status.subscription_tier,
        entitlements: status.entitlements,
        trial_ends_at: status.trial_ends_at,
        purchase_platform: status.purchase_platform,
        cached: true,
        warning: 'cache_stale',
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Parse RevenueCat response and determine tier
    const rcData = await rcResponse.json();
    const subscriber = rcData.subscriber;
    const entitlements = subscriber.entitlements || {};

    // Determine tier from active entitlements
    let tier: SubscriptionTier = 'free';
    const hasProEntitlement = Object.values(entitlements).some(
      (e: any) => e.is_active
    );
    if (hasProEntitlement) {
      // Check if it's a trial by looking at period_type of the subscription
      const subscriptions = subscriber.subscriptions || {};
      const activeSub = Object.values(subscriptions).find(
        (s: any) => s.period_type === 'trial'
      );
      tier = activeSub ? 'trial' : 'pro';
    }

    // Update subscription_status with fresh data (D-08)
    const { error: updateError } = await supabase
      .from('subscription_status')
      .update({
        subscription_tier: tier,
        entitlements: entitlements,
        trial_ends_at: tier === 'trial'
          ? Object.values(entitlements).find((e: any) => e.is_active)?.expires_date || null
          : null,
      })
      .eq('user_id', user.id);

    if (updateError) {
      console.error('Failed to update subscription_status:', updateError);
    }

    // Return fresh data with cached: false
    return new Response(JSON.stringify({
      tier,
      entitlements,
      trial_ends_at: status.trial_ends_at,
      purchase_platform: status.purchase_platform,
      cached: false,
    }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
