import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const body = await req.json();
    const { user_id, org_id, action } = body;

    if (!user_id || !org_id || !action) {
      return NextResponse.json(
        { error: 'user_id, org_id, and action are required' },
        { status: 400 },
      );
    }

    if (action === 'suspend') {
      const { error } = await supabase
        .from('organization_members')
        .update({ status: 'suspended' })
        .eq('user_id', user_id)
        .eq('org_id', org_id);

      if (error) return NextResponse.json({ error: error.message }, { status: 500 });

      // Log to audit trail
      await supabase.from('admin_audit_log').insert({
        action: 'USER_SUSPEND',
        target_type: 'user',
        target_id: user_id,
        details: { org_id, previous_status: 'active' },
      });
    } else if (action === 'reactivate') {
      const { error } = await supabase
        .from('organization_members')
        .update({ status: 'active' })
        .eq('user_id', user_id)
        .eq('org_id', org_id);

      if (error) return NextResponse.json({ error: error.message }, { status: 500 });

      await supabase.from('admin_audit_log').insert({
        action: 'USER_REACTIVATE',
        target_type: 'user',
        target_id: user_id,
        details: { org_id },
      });
    } else {
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
