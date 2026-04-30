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

  const { user_id } = await req.json();
  if (!user_id) return NextResponse.json({ error: 'user_id required' }, { status: 400 });

  // Get API key IDs for this user first
  const { data: keys } = await supabase.from('api_keys').select('id').eq('user_id', user_id);
  const keyIds = keys?.map(k => k.id) || [];

  // Delete user data in order (respecting FK constraints)
  const deletes = [
    supabase.from('subscription_snapshots').delete().eq('user_id', user_id),
    supabase.from('community_phrases').delete().eq('user_id', user_id),
    supabase.from('translations').delete().eq('user_id', user_id),
    supabase.from('organization_members').delete().eq('user_id', user_id),
  ];
  await Promise.all(deletes);

  // Delete API usage and keys last
  if (keyIds.length > 0) {
    await supabase.from('api_key_usage').delete().in('api_key_id', keyIds);
    await supabase.from('api_keys').delete().eq('user_id', user_id);
  }

  // Log compliance action
  await supabase.from('admin_audit_log').insert({
    action: 'COMPLIANCE_DELETE',
    target_type: 'user',
    target_id: user_id,
    details: { deleted_at: new Date().toISOString(), tables: ['organization_members', 'translations', 'community_phrases', 'api_keys', 'api_key_usage', 'subscription_snapshots'] },
  });

  return NextResponse.json({ success: true, message: 'User data deleted' });
}
