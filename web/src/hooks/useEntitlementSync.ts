'use client';

import { useEffect, useRef } from 'react';
import { useEntitlementStore } from '@/lib/entitlement-store';
import { supabase } from '@/lib/supabase';

/**
 * Keeps entitlement store in sync with:
 * 1. Supabase real-time changes to subscription_status (filtered by user)
 * 2. RevenueCat CustomerInfo on window focus (cross-device sync)
 */
export function useEntitlementSync() {
  const fromCustomerInfo = useEntitlementStore((s) => s.fromCustomerInfo);
  const setAuthenticated = useEntitlementStore((s) => s.setAuthenticated);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);

  useEffect(() => {
    let isMounted = true;

    // Get current user ID for filtering
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!isMounted) return;

      const userId = session?.user?.id ?? null;

      if (!userId) {
        setAuthenticated(false);
        return;
      }

      setAuthenticated(true);

      // 1. Supabase real-time subscription to subscription_status changes (filtered by user)
      const channel = supabase
        .channel('entitlement-sync')
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'subscription_status',
            filter: `user_id=eq.${userId}`,
          },
          async () => {
            // Refresh entitlements from RevenueCat when subscription_status changes
            try {
              const { refreshEntitlements } = await import('@/lib/revenuecat');
              const customerInfo = await refreshEntitlements();
              if (customerInfo) {
                fromCustomerInfo(customerInfo);
              }
            } catch {
              // Silent — will retry on next focus
            }
          }
        )
        .subscribe();

      channelRef.current = channel;
    });

    // 2. Poll RevenueCat on window focus (cross-device sync)
    const handleFocus = async () => {
      try {
        const { refreshEntitlements } = await import('@/lib/revenuecat');
        const customerInfo = await refreshEntitlements();
        if (customerInfo) {
          fromCustomerInfo(customerInfo);
        }
      } catch {
        // Silent — offline or not configured
      }
    };

    window.addEventListener('focus', handleFocus);

    // WR-03: Proper cleanup on unmount — unsubscribe from Supabase channel
    return () => {
      isMounted = false;
      window.removeEventListener('focus', handleFocus);
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, [fromCustomerInfo, setAuthenticated]);
}
