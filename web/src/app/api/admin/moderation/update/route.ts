import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { requireAdmin } from '@/lib/supabase/admin-auth';

export async function POST(req: NextRequest) {
  const authCheck = await requireAdmin(req);
  if (authCheck) return authCheck;

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { id, status } = await req.json();

    if (!id || !status) {
      return NextResponse.json(
        { error: 'id and status are required' },
        { status: 400 },
      );
    }

    const { error } = await supabase
      .from('community_phrases')
      .update({ status })
      .eq('id', id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Log to audit trail
    await supabase.from('admin_audit_log').insert({
      action: status === 'approved' ? 'CONTENT_APPROVE' : 'CONTENT_REJECT',
      target_type: 'community_phrase',
      target_id: id,
      details: { new_status: status },
    });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
