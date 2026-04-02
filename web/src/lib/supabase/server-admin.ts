import { createClient } from '@supabase/supabase-js';

export function getAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

  if (!url || !serviceKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set for admin features',
    );
  }

  return createClient(url, serviceKey);
}

export async function isAdminOrAdminStatus(userId: string): Promise<boolean> {
  const supabase = getAdminClient();

  const { data } = await supabase.rpc('is_admin', undefined);

  if (data) return true;

  const { data: member } = await supabase
    .from('organization_members')
    .select('role')
    .eq('user_id', userId)
    .eq('role', 'owner')
    .eq('status', 'active')
    .single();

  if (member) return true;

  return false;
}
