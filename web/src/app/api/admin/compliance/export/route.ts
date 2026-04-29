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

  // Gather user data
  const [orgMembers, translations, communityPhrases, apiKeys, apiUsage, subscriptions] = await Promise.all([
    supabase.from('organization_members').select('*').eq('user_id', user_id),
    supabase.from('translations').select('*').eq('user_id', user_id),
    supabase.from('community_phrases').select('*').eq('user_id', user_id),
    supabase.from('api_keys').select('*').eq('user_id', user_id),
    supabase.from('api_key_usage').select('*, api_keys!inner(user_id)').eq('api_keys.user_id', user_id),
    supabase.from('subscription_snapshots').select('*').eq('user_id', user_id),
  ]);

  const exportData = {
    user_id,
    exported_at: new Date().toISOString(),
    organization_members: orgMembers.data || [],
    translations: translations.data || [],
    community_phrases: communityPhrases.data || [],
    api_keys: apiKeys.data || [],
    api_key_usage: apiUsage.data || [],
    subscription_snapshots: subscriptions.data || [],
  };

  // Log compliance action
  await supabase.from('admin_audit_log').insert({
    action: 'COMPLIANCE_EXPORT',
    target_type: 'user',
    target_id: user_id,
    details: { exported_tables: ['organization_members', 'translations', 'community_phrases', 'api_keys', 'api_key_usage', 'subscription_snapshots'] },
  });

  return NextResponse.json({ success: true, data: exportData });
}
