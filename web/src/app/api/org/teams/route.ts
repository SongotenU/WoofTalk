import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function GET() {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { data: userOrg } = await supabase
      .from('organization_members')
      .select('org_id')
      .eq('status', 'active')
      .limit(1)
      .single();

    if (!userOrg) {
      return NextResponse.json({ teams: [] });
    }

    const { data: teams, error } = await supabase
      .from('teams')
      .select('*')
      .eq('org_id', userOrg.org_id)
      .order('created_at', { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    return NextResponse.json({ teams: (teams || []).map(t => ({
      ...t,
      member_count: 0, // TODO: join with team_members for count
    })) });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { name } = await req.json();

    if (!name) {
      return NextResponse.json({ error: 'Team name required' }, { status: 400 });
    }

    const { data: userOrg } = await supabase
      .from('organization_members')
      .select('org_id')
      .eq('status', 'active')
      .limit(1)
      .single();

    if (!userOrg) {
      return NextResponse.json({ error: 'No organization found' }, { status: 404 });
    }

    const { data, error } = await supabase
      .from('teams')
      .insert({ org_id: userOrg.org_id, name })
      .select()
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    return NextResponse.json({ team: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
