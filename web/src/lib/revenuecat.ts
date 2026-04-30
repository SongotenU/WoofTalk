import { Purchases, PurchasesConfig } from '@revenuecat/purchases-js';
import { supabase } from './supabase';

const API_KEY = process.env.NEXT_PUBLIC_REVENUECAT_WEB_API_KEY ?? '';

let initialized = false;

export function isRevenueCatInitialized() {
  return initialized;
}

// SDK-01/02/03: Initialize RevenueCat with anonymous user (D-01)
export async function initRevenueCat() {
  if (initialized) return;
  if (!API_KEY) return; // Skip if no key configured (e.g. local dev without RevenueCat)

  const config: PurchasesConfig = {
    apiKey: API_KEY,
    appUserId: Purchases.generateRevenueCatAnonymousAppUserId(),
  };
  Purchases.configure(config);
  initialized = true;

  // D-02: Link identity on auth change
  supabase.auth.onAuthStateChange(async (event, session) => {
    if ((event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') && session?.user) {
      await identifyUserRevenueCat(session.user.id);
    } else if (event === 'SIGNED_OUT') {
      await closeRevenueCat();
    }
  });
}

// D-02: Log in with Supabase auth.uid
export async function identifyUserRevenueCat(userId: string | undefined) {
  try {
    if (userId) {
      await Purchases.getSharedInstance().identifyUser(userId);
    } else {
      await closeRevenueCat();
    }
  } catch {
    // D-05: Trust cached CustomerInfo when offline
  }
}

export async function closeRevenueCat() {
  try {
    Purchases.getSharedInstance().close();
  } catch {
    // Ignore
  }
}

// SDK-05: Force refresh after purchase
export async function refreshEntitlements() {
  try {
    return await Purchases.getSharedInstance().getCustomerInfo();
  } catch {
    return null;
  }
}

export { Purchases };

// Re-export for convenience and type safety
export const purchases = Purchases;
