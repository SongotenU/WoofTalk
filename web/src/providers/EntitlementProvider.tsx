'use client';

import { useEffect, type ReactNode } from 'react';
import Purchases from '@revenuecat/purchases-js';
import { initRevenueCat } from '@/lib/revenuecat';
import { useEntitlementStore } from '@/lib/entitlement-store';
import { supabase } from '@/lib/supabase';

export function EntitlementProvider({ children }: { children: ReactNode }) {
  const fromCustomerInfo = useEntitlementStore((s) => s.fromCustomerInfo);
  const setAuthenticated = useEntitlementStore((s) => s.setAuthenticated);

  useEffect(() => {
    // SDK-01/02/03: Initialize with anonymous user
    initRevenueCat();

    // SDK-04: Listen for CustomerInfo updates
    Purchases.getSharedInstance().on('customerInfoUpdated', (customerInfo) => {
      fromCustomerInfo(customerInfo);
    });

    // Sync auth state
    supabase.auth.getSession().then(({ data: { session } }) => {
      setAuthenticated(!!session?.user);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setAuthenticated(!!session?.user);
    });

    return () => subscription.unsubscribe();
  }, [fromCustomerInfo, setAuthenticated]);

  return <>{children}</>;
}
