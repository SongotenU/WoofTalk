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

  // RevenueCat JS SDK automatically generates an anonymous ID on configure
  // No need to manually call generateRevenueCatAnonymousAppUserId()
  const config: PurchasesConfig = {
    apiKey: API_KEY,
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

  // If user is already logged in, identify them
  const { data: { session } } = await supabase.auth.getSession();
  if (session?.user) {
    await identifyUserRevenueCat(session.user.id);
  }
}

// D-02: Log in with Supabase auth.uid
export async function identifyUserRevenueCat(userId: string | undefined) {
  try {
    if (userId) {
      // Identify user with RevenueCat - links the anonymous user to the real user
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
    // Log out the user - creates a new anonymous user
    await Purchases.getSharedInstance().logOut();
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
