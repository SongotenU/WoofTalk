import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function GET(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  const period = req.nextUrl.searchParams.get('period') || '30d';
  const days = period === '7d' ? 7 : period === '90d' ? 90 : 30;
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

  try {
    // Translations by day
    const { data: translationsByDay } = await supabase
      .from('translations')
      .select('created_at')
      .gte('created_at', since);

    const translationsByDayMap: Record<string, number> = {};
    translationsByDay?.forEach((t) => {
      const date = t.created_at.slice(0, 10);
      translationsByDayMap[date] = (translationsByDayMap[date] || 0) + 1;
    });

    // Active users by day
    const { data: activeByDay } = await supabase
      .from('translations')
      .select('user_id, created_at')
      .gte('created_at', since);

    const activeByDayMap: Record<string, number> = {};
    activeByDay?.forEach((t) => {
      const date = t.created_at.slice(0, 10);
      activeByDayMap[date] = activeByDayMap[date] || 0;
      // Count unique users per day - we'll need to group first
    });

    // Group by day then count unique
    const dayUsers: Record<string, Set<string>> = {};
    activeByDay?.forEach((t) => {
      const date = t.created_at.slice(0, 10);
      if (!dayUsers[date]) dayUsers[date] = new Set();
      dayUsers[date].add(t.user_id);
    });
    const activeUsersByDayMap: Record<string, number> = {};
    Object.entries(dayUsers).forEach(([date, users]) => {
      activeUsersByDayMap[date] = users.size;
    });

    // API calls by day
    const { data: apiByDay } = await supabase
      .from('api_key_usage')
      .select('created_at')
      .gte('created_at', since);

    const apiByDayMap: Record<string, number> = {};
    apiByDay?.forEach((a) => {
      const date = a.created_at.slice(0, 10);
      apiByDayMap[date] = (apiByDayMap[date] || 0) + 1;
    });

    // Top endpoints
    const { data: endpointData } = await supabase
      .from('api_key_usage')
      .select('endpoint')
      .gte('created_at', since);

    const endpointCounts: Record<string, number> = {};
    endpointData?.forEach((e) => {
      endpointCounts[e.endpoint] = (endpointCounts[e.endpoint] || 0) + 1;
    });
    const topEndpoints = Object.entries(endpointCounts)
      .map(([endpoint, count]) => ({ endpoint, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    // Totals
    const { count: totalTranslations } = await supabase
      .from('translations')
      .select('*', { count: 'exact', head: true });
    const { count: totalApiCalls } = await supabase
      .from('api_key_usage')
      .select('*', { count: 'exact', head: true });
    const { count: totalUsers } = await supabase
      .from('organization_members')
      .select('*', { count: 'exact', head: true });

    // Build sorted array
    const allDates = Array.from(
      new Set([
        ...Object.keys(translationsByDayMap),
        ...Object.keys(activeUsersByDayMap),
        ...Object.keys(apiByDayMap),
      ]),
    ).sort();

    const translations_by_day = allDates.map((date) => ({ date, count: translationsByDayMap[date] || 0 }));
    const active_users_by_day = allDates.map((date) => ({ date, count: activeUsersByDayMap[date] || 0 }));
    const api_calls_by_day = allDates.map((date) => ({ date, count: apiByDayMap[date] || 0 }));

    return NextResponse.json({
      translations_by_day,
      active_users_by_day,
      api_calls_by_day,
      top_endpoints: topEndpoints,
      total_translations: totalTranslations ?? 0,
      total_api_calls: totalApiCalls ?? 0,
      total_users: totalUsers ?? 0,
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
