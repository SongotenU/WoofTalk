import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

function mapStore(store: string): 'ios' | 'android' | 'web' | 'none' {
  switch (store) {
    case 'APP_STORE': return 'ios';
    case 'PLAY_STORE': return 'android';
    case 'STRIPE': return 'web';
    default: return 'none';
  }
}

serve(async (req) => {
  // OPTIONS preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  // POST-only check
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // D-02: Authorization header verification
  const authHeader = req.headers.get('Authorization');
  const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_AUTH');
  if (!authHeader || authHeader !== `Bearer ${webhookSecret}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Create Supabase service role client
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    // Parse request body
    const body = await req.json();
    const event = body.event;
    const eventId = event?.id as string;
    const eventType = event?.type as string;
    const appUserId = event?.app_user_id as string;

    // SUB-04: Idempotency check
    const { data: existing } = await supabase
      .from('webhook_events')
      .select('event_id')
      .eq('event_id', eventId)
      .single();

    if (existing) {
      return new Response(JSON.stringify({ status: 'duplicate' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // D-01: Event type handling — initialize variables before switch
    let tier: 'free' | 'trial' | 'pro' = 'free';
    let trialEndsAt: string | null = null;
    let platform: 'ios' | 'android' | 'web' | 'none' = 'none';
    let cancellationReason: string | null = null;
    let shouldUpsert = false;

    switch (eventType) {
      case 'INITIAL_PURCHASE':
        tier = event.period_type === 'TRIAL' ? 'trial' : 'pro';
        trialEndsAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;
        platform = mapStore(event.store);
        shouldUpsert = true;
        break;
      case 'RENEWAL':
        tier = event.is_trial_conversion ? 'pro' : 'pro';
        platform = mapStore(event.store);
        shouldUpsert = true;
        break;
      case 'TRIAL_STARTED':
        tier = 'trial';
        trialEndsAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;
        platform = mapStore(event.store);
        shouldUpsert = true;
        break;
      case 'TRIAL_CONVERTED':
        tier = 'pro';
        platform = mapStore(event.store);
        shouldUpsert = true;
        break;
      case 'CANCELLATION':
        tier = 'pro'; // Still active until expiration
        cancellationReason = event.cancel_reason || null;
        platform = mapStore(event.store);
        shouldUpsert = true;
        break;
      case 'EXPIRATION':
        tier = 'free';
        cancellationReason = event.expiration_reason || null;
        trialEndsAt = null;
        shouldUpsert = true;
        break;
      case 'UNCANCELATION':
        tier = 'pro';
        cancellationReason = null;
        shouldUpsert = true;
        break;
      // No-op event types — record but don't change tier
      case 'BILLING_ISSUE':
      case 'PRODUCT_CHANGE':
      case 'NON_RENEWING_PURCHASE':
      case 'SUBSCRIPTION_PAUSED':
      case 'SUBSCRIPTION_RESUMED':
      case 'TRANSFER':
      case 'TEST':
        console.log(`Webhook event type ${eventType} recorded (no-op) for user ${appUserId}`);
        break;
      default:
        console.log(`Unknown webhook event type: ${eventType}`);
        break;
    }

    // SUB-05: Upsert subscription_status (idempotent) only for state-changing events
    if (shouldUpsert) {
      const { error: upsertError } = await supabase
        .from('subscription_status')
        .upsert({
          user_id: appUserId,
          revenuecat_id: appUserId,
          entitlements: event.entitlement_ids || [],
          subscription_tier: tier,
          trial_ends_at: trialEndsAt,
          purchase_platform: platform,
          cancellation_reason: cancellationReason,
        }, { onConflict: 'user_id' });

      if (upsertError) {
        console.error('Failed to upsert subscription_status:', upsertError);
      }
    }

    // Record event in webhook_events for idempotency tracking
    const { error: insertError } = await supabase
      .from('webhook_events')
      .insert({
        event_id: eventId,
        event_type: eventType,
        app_user_id: appUserId,
      });

    if (insertError) {
      console.error('Failed to record webhook event:', insertError);
    }

  } catch (err) {
    console.error('Webhook processing error:', err);
    // Still return 200 to prevent RevenueCat retry (SUB-05)
  }

  // SUB-05: Always return 200 OK — outside try/catch so it always executes
  return new Response(JSON.stringify({ status: 'ok' }), {
    status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
