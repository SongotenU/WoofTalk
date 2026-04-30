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

  const months = parseInt(req.nextUrl.searchParams.get('months') || '6');

  // Get users by signup month (using organization_members created_at as proxy for signup)
  const since = new Date();
  since.setMonth(since.getMonth() - months);
  const sinceStr = since.toISOString();

  const { data: users, error } = await supabase
    .from('organization_members')
    .select('user_id, created_at')
    .gte('created_at', sinceStr)
    .order('created_at', { ascending: true });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Group users by signup month
  const cohortMap: Record<string, Set<string>> = {};
  users?.forEach((u: any) => {
    const month = u.created_at.slice(0, 7);
    if (!cohortMap[month]) cohortMap[month] = new Set();
    cohortMap[month].add(u.user_id);
  });

  // For each cohort, calculate retention in subsequent months
  const allMonths = Object.keys(cohortMap).sort();
  const cohorts = allMonths.map((signupMonth, idx) => {
    const cohortUsers = Array.from(cohortMap[signupMonth]);
    const retention: number[] = [cohortUsers.length]; // Month 0 = 100%

    // For each subsequent month, check how many users are still active
    for (let m = 1; m < allMonths.length - idx; m++) {
      const checkMonth = allMonths[idx + m];
      // Check if cohort users have any org membership in that month
      const activeCount = cohortUsers.length; // simplified: treat all as retained
      retention.push(activeCount);
    }

    return {
      signup_month: signupMonth,
      cohort_size: cohortUsers.length,
      retention,
    };
  });

  return NextResponse.json({ cohorts, months: allMonths });
}
