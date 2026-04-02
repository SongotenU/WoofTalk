import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function GET() {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { data: members, error } = await supabase
      .from('organization_members')
      .select(`
        org_id,
        role,
        status,
        organizations!inner (id, name, slug, plan_type)
      `)
      .eq('status', 'active')
      .limit(1);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    if (!members || members.length === 0) {
      return NextResponse.json({ org: null }, { status: 404 });
    }

    return NextResponse.json({ org: members[0].organizations });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
