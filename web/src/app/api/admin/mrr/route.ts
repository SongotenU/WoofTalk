import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { requireAdmin } from '@/lib/supabase/admin-auth';

export async function GET(req: NextRequest) {
  const authCheck = await requireAdmin(req);
  if (authCheck) return authCheck;

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  const months = parseInt(req.nextUrl.searchParams.get('months') || '12');

  // MRR by month from subscription snapshots
  const since = new Date();
  since.setMonth(since.getMonth() - months);
  const sinceStr = since.toISOString();

  const { data: snapshots, error } = await supabase
    .from('subscription_snapshots')
    .select('snapshot_date, status, price_usd, user_id')
    .gte('snapshot_date', sinceStr)
    .order('snapshot_date', { ascending: true });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Group by month
  const byMonth: Record<string, { mrr: number; active: number; trials: number; cancelled: number; users: Set<string> }> = {};

  snapshots?.forEach((s) => {
    const month = s.snapshot_date.slice(0, 7); // YYYY-MM
    if (!byMonth[month]) byMonth[month] = { mrr: 0, active: 0, trials: 0, cancelled: 0, users: new Set() };

    if (s.status === 'active') {
      byMonth[month].mrr += parseFloat(s.price_usd?.toString() || '0');
      byMonth[month].active++;
    } else if (s.status === 'trialing') {
      byMonth[month].trials++;
    } else if (s.status === 'cancelled') {
      byMonth[month].cancelled++;
    }
    byMonth[month].users.add(s.user_id);
  });

  const mrrTrend = Object.entries(byMonth).map(([month, data]) => ({
    month,
    mrr: Math.round(data.mrr * 100) / 100,
    activeSubscriptions: data.active,
    trials: data.trials,
    cancelled: data.cancelled,
    uniqueUsers: data.users.size,
  }));

  // Churn calculation: cancellations / (active + trials) per month
  const churnRate = mrrTrend.map((m, i: number) => {
    const prev = i > 0 ? mrrTrend[i - 1] : null;
    const denominator = (m.activeSubscriptions + m.trials) + (prev ? prev.activeSubscriptions + prev.trials : 0);
    return {
      churnRate: denominator > 0 ? Math.round((m.cancelled / denominator) * 10000) / 100 : 0,
      ...m,
    };
  });

  // Current totals
  const latest = mrrTrend[mrrTrend.length - 1] || { mrr: 0, activeSubscriptions: 0, trials: 0 };

  // Fetch RevenueCat data for current subscriber counts
  let subscriberCount = 0;
  let trialCount = 0;
  let premiumCount = 0;
  try {
    const revenuecatApiKey = process.env.REVENUECAT_API_KEY;
    if (revenuecatApiKey) {
      const appId = process.env.REVENUECAT_APP_ID;
      const rcRes = await fetch(`https://api.revenuecat.com/v1/projects/${appId}/subscribers`, {
        headers: { Authorization: `Bearer ${revenuecatApiKey}` },
        next: { revalidate: 300 },
      });
      if (rcRes.ok) {
        const data = await rcRes.json();
        subscriberCount = data.subscribers?.length ?? 0;
        trialCount = data.subscribers?.filter((s: any) => s.subscription?.status === 'trial').length ?? 0;
        premiumCount = data.subscribers?.filter((s: any) => s.subscription?.status === 'active').length ?? 0;
      }
    }
  } catch { /* ignore */ }

  return NextResponse.json({
    mrrTrend: churnRate,
    current: {
      mrr: latest.mrr,
      activeSubscriptions: latest.activeSubscriptions,
      trials: latest.trials,
      totalSubscribers: subscriberCount,
      trialSubscribers: trialCount,
      premiumSubscribers: premiumCount,
    },
  });
}
