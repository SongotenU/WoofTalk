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
  const platform = req.nextUrl.searchParams.get('platform');
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

  let query = supabase
    .from('error_logs')
    .select('*')
    .gte('created_at', since)
    .order('created_at', { ascending: false });

  if (platform) query = query.eq('platform', platform);

  const { data: errors, error } = await query.limit(500);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Aggregate error rates by day and platform
  const byDay: Record<string, { total: number; platforms: Record<string, number> }> = {};
  const byType: Record<string, number> = {};

  errors?.forEach((e) => {
    const date = e.created_at.slice(0, 10);
    if (!byDay[date]) byDay[date] = { total: 0, platforms: {} };
    byDay[date].total++;
    byDay[date].platforms[e.platform] = (byDay[date].platforms[e.platform] || 0) + 1;
    byType[e.error_type] = (byType[e.error_type] || 0) + 1;
  });

  const trend = Object.entries(byDay).map(([date, d]) => ({ date, ...d, platforms: d.platforms }));

  return NextResponse.json({ errors, summary: { byDay: trend, byType, total: errors?.length || 0 } });
}

export async function POST(req: NextRequest) {
  // Auth check for POST - only authenticated admins can insert error logs via this endpoint
  const authCheck = await requireAdmin(req);
  if (authCheck) return authCheck;

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const body = await req.json();
    const { data, error } = await supabase
      .from('error_logs')
      .insert(body)
      .select('id')
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, id: data.id }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
