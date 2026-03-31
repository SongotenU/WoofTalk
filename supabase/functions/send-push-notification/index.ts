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

    if (!fcmServerKey) throw new Error('FCM_SERVER_KEY not configured');

    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: pending, error: fetchError } = await supabase
      .from('push_notifications')
      .select('*')
      .eq('status', 'pending')
      .limit(100);

    if (fetchError) throw fetchError;
    if (!pending || pending.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: 'No pending notifications' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let sentCount = 0;
    for (const notification of pending) {
      try {
        const payload = {
          to: notification.fcm_token,
          notification: { title: notification.title, body: notification.body },
          data: notification.data || {},
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
        const status = result.failure === 0 ? 'sent' : 'failed';

        await supabase.from('push_notifications').update({
          status,
          sent_at: status === 'sent' ? new Date().toISOString() : null,
        }).eq('id', notification.id);

        if (status === 'sent') sentCount++;
      } catch (_err) {
        await supabase.from('push_notifications').update({
          status: 'failed',
        }).eq('id', notification.id);
      }
    }

    return new Response(JSON.stringify({ sent: sentCount, total: pending.length }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
