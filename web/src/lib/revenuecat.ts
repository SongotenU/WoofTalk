import Purchases from '@revenuecat/purchases-js';
import { supabase } from './supabase';

const API_KEY = process.env.NEXT_PUBLIC_REVENUECAT_WEB_API_KEY ?? '';

let initialized = false;

// SDK-01/02/03: Initialize RevenueCat with anonymous user (D-01)
export async function initRevenueCat() {
  if (initialized) return;

  Purchases.configure({ apiKey: API_KEY, appUserID: undefined });
  initialized = true;

  // D-02: Link identity on auth change
  supabase.auth.onAuthStateChange(async (event, session) => {
    if ((event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') && session?.user) {
      await loginRevenueCat(session.user.id);
    } else if (event === 'SIGNED_OUT') {
      await logoutRevenueCat();
    }
  });
}

// D-02: Log in with Supabase auth.uid
export async function loginRevenueCat(userId: string) {
  try {
    await Purchases.getSharedInstance().logIn(userId);
  } catch {
    // D-05: Trust cached CustomerInfo when offline
  }
}

export async function logoutRevenueCat() {
  try {
    await Purchases.getSharedInstance().logOut();
  } catch {
    // D-05
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
