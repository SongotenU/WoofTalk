import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const url = new URL(req.url);
    const period = url.searchParams.get('period') || 'all_time';
    const limit = parseInt(url.searchParams.get('limit') || '50');

    const { data, error } = await supabase
      .from('leaderboard_entries')
      .select(`
        rank,
        score,
        period,
        users (id, display_name, avatar_url, platform)
      `)
      .eq('period', period)
      .order('rank', { ascending: true })
      .limit(Math.min(limit, 100));

    if (error) throw error;

    return new Response(JSON.stringify({ leaderboard: data, period }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
