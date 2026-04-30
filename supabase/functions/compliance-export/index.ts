import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { user_id, action } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ error: 'user_id is required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'export') {
      // Gather all user data across tables
      const [orgMembers, translations, communityPhrases, apiUsage, subscriptions] = await Promise.all([
        supabase.from('organization_members').select('*').eq('user_id', user_id),
        supabase.from('translations').select('*').eq('user_id', user_id),
        supabase.from('community_phrases').select('*').eq('user_id', user_id),
        supabase.from('api_key_usage').select('*, api_keys!inner(user_id)').eq('api_keys.user_id', user_id),
        supabase.from('subscription_snapshots').select('*').eq('user_id', user_id),
      ]);

      const exportData = {
        user_id,
        exported_at: new Date().toISOString(),
        organization_members: orgMembers.data || [],
        translations: translations.data || [],
        community_phrases: communityPhrases.data || [],
        api_key_usage: apiUsage.data || [],
        subscription_snapshots: subscriptions.data || [],
      };

      // Log compliance action
      await supabase.from('admin_audit_log').insert({
        action: 'COMPLIANCE_EXPORT',
        target_type: 'user',
        target_id: user_id,
        details: { exported_tables: Object.keys(exportData).filter(k => k !== 'user_id' && k !== 'exported_at') },
      });

      return new Response(JSON.stringify({ success: true, data: exportData }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'delete') {
      // Right to be forgotten: delete user data (not auth user itself - that's handled separately)
      const [delOrgMembers, delTranslations, delPhrases, delUsage, delSubscriptions, delKeys] = await Promise.all([
        supabase.from('organization_members').delete().eq('user_id', user_id),
        supabase.from('translations').delete().eq('user_id', user_id),
        supabase.from('community_phrases').delete().eq('user_id', user_id),
        supabase.from('api_key_usage').delete().eq('api_key_id', supabase.from('api_keys').select('id').eq('user_id', user_id)),
        supabase.from('subscription_snapshots').delete().eq('user_id', user_id),
        supabase.from('api_keys').delete().eq('user_id', user_id),
      ]);

      // Log compliance action
      await supabase.from('admin_audit_log').insert({
        action: 'COMPLIANCE_DELETE',
        target_type: 'user',
        target_id: user_id,
        details: { deleted_at: new Date().toISOString() },
      });

      return new Response(JSON.stringify({ success: true, message: 'User data deleted' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Invalid action. Use "export" or "delete"' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
