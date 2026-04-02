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
    const { action, ids } = await req.json();

    if (!action || !ids || !Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json(
        { error: 'action and ids array are required' },
        { status: 400 },
      );
    }

    const newStatus = action === 'approve' ? 'approved' : 'rejected';

    const { data, error } = await supabase
      .from('community_phrases')
      .update({ status: newStatus })
      .in('id', ids)
      .select('id');

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Log bulk action to audit trail
    await supabase.from('admin_audit_log').insert({
      action: action === 'approve' ? 'BULK_APPROVE' : 'BULK_REJECT',
      target_type: 'community_phrase',
      details: { count: ids.length, ids },
    });

    return NextResponse.json({ success: true, updated: data?.length || 0 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
