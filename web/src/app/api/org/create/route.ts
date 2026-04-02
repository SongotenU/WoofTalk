import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { name, slug, plan } = await req.json();

    if (!name || !slug) {
      return NextResponse.json({ error: 'Name and slug required' }, { status: 400 });
    }

    // For now, use a placeholder owner_id — in production, extract from session
    const { data: org, error } = await supabase
      .from('organizations')
      .insert({
        name,
        slug,
        plan_type: plan || 'free',
        owner_id: '00000000-0000-0000-0000-000000000000', // TODO: extract from auth
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        return NextResponse.json({ error: 'Slug already taken' }, { status: 409 });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ org });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
