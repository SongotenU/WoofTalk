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

  const days = parseInt(req.nextUrl.searchParams.get('days') || '7');
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

  // Fetch API usage with key info
  const { data: usage, error } = await supabase
    .from('api_key_usage')
    .select('*, api_keys(name, user_id, rate_limit, is_revoked)')
    .gte('created_at', since)
    .order('created_at', { ascending: false })
    .limit(500);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Aggregate
  const byEndpoint: Record<string, number> = {};
  const byStatus: Record<string, number> = {};
  const topUsers: Record<string, number> = {};

  usage?.forEach((u: any) => {
    byEndpoint[u.endpoint] = (byEndpoint[u.endpoint] || 0) + 1;
    const statusGroup = u.status_code >= 400 ? '4' : '2';
    byStatus[statusGroup] = (byStatus[statusGroup] || 0) + 1;
    const userId = u.api_keys?.user_id || 'unknown';
    topUsers[userId] = (topUsers[userId] || 0) + 1;
  });

  return NextResponse.json({
    usage: usage || [],
    summary: {
      total_calls: usage?.length || 0,
      by_endpoint: byEndpoint,
      by_status: byStatus,
      top_users: topUsers,
    },
  });
}
