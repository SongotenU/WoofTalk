import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const today = new Date().toISOString().slice(0, 10);
    const thisMonthStart = today.slice(0, 7) + '-01'; // First day of current month
    
    // Calculate last month's start date
    const lastMonthDate = new Date();
    lastMonthDate.setMonth(lastMonthDate.getMonth() - 1);
    const lastMonthStart = lastMonthDate.toISOString().slice(0, 7) + '-01';

    // Get latest snapshot for each user before this month (end of last month)
    const { data: lastMonthSnapshots, error: lmError } = await supabase
      .rpc('get_latest_snapshots_before_date', { before_date: thisMonthStart });
    
    if (lmError) {
      // Fallback: manually get latest snapshots before this month
      const { data: allSnapshots, error } = await supabase
        .from('subscription_snapshots')
        .select('*')
        .lt('snapshot_date', thisMonthStart)
        .order('snapshot_date', { ascending: false });

      if (error) throw error;
      
      // Get latest snapshot per user
      const seen = new Set();
      const latestBeforeThisMonth = (allSnapshots || []).filter((s: any) => {
        if (seen.has(s.user_id)) return false;
        seen.add(s.user_id);
        return true;
      });
      
      // Get latest snapshot per user up to today (for current MRR)
      const { data: currentSnapshots, error: csError } = await supabase
        .from('subscription_snapshots')
        .select('*')
        .lte('snapshot_date', today)
        .order('snapshot_date', { ascending: false });

      if (csError) throw csError;

      // Get latest snapshot per user for current state
      const seen2 = new Set();
      const latestCurrent = (currentSnapshots || []).filter((s: any) => {
        if (seen2.has(s.user_id)) return false;
        seen2.add(s.user_id);
        return true;
      });

      // Calculate MRR from active subscriptions
      const mrr = latestCurrent
        .filter((s: any) => s.status === 'active')
        .reduce((sum: number, s: any) => sum + parseFloat(s.price_usd || 0), 0);

      // Calculate churn: was active at end of last month, not active now
      const lastMonthActive = new Set(
        latestBeforeThisMonth
          .filter((s: any) => s.status === 'active')
          .map((s: any) => s.user_id)
      );
      
      const thisMonthActive = new Set(
        latestCurrent
          .filter((s: any) => s.status === 'active')
          .map((s: any) => s.user_id)
      );
      
      const churned = [...lastMonthActive].filter((u) => !thisMonthActive.has(u)).length;
      const churnRate = lastMonthActive.size > 0 ? (churned / lastMonthActive.size) * 100 : 0;

      return new Response(
        JSON.stringify({
          success: true,
          date: today,
          mrr: parseFloat(mrr.toFixed(2)),
          activeSubscriptions: latestCurrent.filter((s: any) => s.status === 'active').length,
          churnedSubscriptions: churned,
          churnRate: parseFloat(churnRate.toFixed(2)),
          lastMonthActive: lastMonthActive.size,
          thisMonthActive: thisMonthActive.size,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // If RPC succeeded, use that data
    const lastMonthActive = new Set(
      (lastMonthSnapshots || [])
        .filter((s: any) => s.status === 'active')
        .map((s: any) => s.user_id)
    );

    // Get current state
    const seen = new Set();
    const { data: currentSnapshots } = await supabase
      .from('subscription_snapshots')
      .select('*')
      .lte('snapshot_date', today)
      .order('snapshot_date', { ascending: false });

    const latestCurrent = (currentSnapshots || []).filter((s: any) => {
      if (seen.has(s.user_id)) return false;
      seen.add(s.user_id);
      return true;
    });

    const mrr = latestCurrent
      .filter((s: any) => s.status === 'active')
      .reduce((sum: number, s: any) => sum + parseFloat(s.price_usd || 0), 0);

    const thisMonthActive = new Set(
      latestCurrent
        .filter((s: any) => s.status === 'active')
        .map((s: any) => s.user_id)
    );

    const churned = [...lastMonthActive].filter((u) => !thisMonthActive.has(u)).length;
    const churnRate = lastMonthActive.size > 0 ? (churned / lastMonthActive.size) * 100 : 0;

    return new Response(
      JSON.stringify({
        success: true,
        date: today,
        mrr: parseFloat(mrr.toFixed(2)),
        activeSubscriptions: latestCurrent.filter((s: any) => s.status === 'active').length,
        churnedSubscriptions: churned,
        churnRate: parseFloat(churnRate.toFixed(2)),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
