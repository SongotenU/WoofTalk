import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify authentication - require user JWT and check admin role
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    const token = authHeader.substring(7);
    
    // Verify the JWT and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check if user is an admin or owner
    const { data: membership, error: memberError } = await supabase
      .from('organization_members')
      .select('role')
      .eq('user_id', user.id)
      .eq('status', 'active')
      .single();
    
    if (memberError || !membership || !['owner', 'admin'].includes(membership.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden - admin access required' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { campaign_id } = await req.json();
    if (!campaign_id) throw new Error('campaign_id is required');

    // Get campaign
    const { data: campaign, error: campaignError } = await supabase
      .from('push_campaigns')
      .select('*, user_segments(*)')
      .eq('id', campaign_id)
      .single();

    if (campaignError || !campaign) throw new Error('Campaign not found');

    // Update status to sending
    await supabase.from('push_campaigns').update({ status: 'sending' }).eq('id', campaign_id);

    // Get segment users (or all users if no segment)
    let userQuery = supabase.from('push_tokens').select('fcm_token, user_id');
    // Simple: get all push tokens for now
    const { data: tokens, error: tokenError } = await userQuery;

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) {
      await supabase.from('push_campaigns').update({ status: 'sent', sent_at: new Date().toISOString() }).eq('id', campaign_id);
      return new Response(JSON.stringify({ sent: 0, message: 'No tokens found' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let successCount = 0;
    let failureCount = 0;

    if (fcmServerKey) {
      for (const token of tokens) {
        try {
          const payload = {
            to: token.fcm_token,
            notification: { title: campaign.title, body: campaign.body },
            data: campaign.data || {},
          };
          const response = await fetch(FCM_ENDPOINT, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `key=${fcmServerKey}`,
            },
            body: JSON.stringify(payload),
          });
          const result = await response.json();
          if (result.failure === 0) successCount++; else failureCount++;
        } catch {
          failureCount++;
        }
      }
    }

    await supabase.from('push_campaigns').update({
      status: 'sent',
      sent_at: new Date().toISOString(),
      recipient_count: tokens.length,
      success_count: successCount,
      failure_count: failureCount,
    }).eq('id', campaign_id);

    return new Response(JSON.stringify({ sent: successCount, failed: failureCount, total: tokens.length }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
