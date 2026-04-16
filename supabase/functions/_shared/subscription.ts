// Shared subscription types and tier-check helper
// Used by Edge Functions that need subscription verification

export type SubscriptionTier = 'free' | 'trial' | 'pro';

export type PurchasePlatform = 'ios' | 'android' | 'web' | 'none';

export interface SubscriptionStatus {
  user_id: string;
  revenuecat_id: string;
  entitlements: Record<string, any>;
  subscription_tier: SubscriptionTier;
  trial_ends_at: string | null;
  purchase_platform: PurchasePlatform;
  cancellation_reason: string | null;
  updated_at: string;
}

export async function checkSubscriptionTier(
  supabase: any,
  userId: string
): Promise<{ tier: SubscriptionTier; dailyCount: number }> {
  // Query subscription_status for the user
  const { data: status } = await supabase
    .from('subscription_status')
    .select('subscription_tier')
    .eq('user_id', userId)
    .single();

  const tier: SubscriptionTier = status?.subscription_tier || 'free';

  // If free tier, count today's translations
  let dailyCount = 0;
  if (tier === 'free') {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD in UTC
    const { count } = await supabase
      .from('translations')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('created_at', today);
    dailyCount = count || 0;
  }

  return { tier, dailyCount };
}

export const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes (D-08)

export function isEntitlementCacheStale(updatedAt: string | null): boolean {
  if (!updatedAt) return true;
  return new Date(updatedAt) < new Date(Date.now() - CACHE_TTL_MS);
}
