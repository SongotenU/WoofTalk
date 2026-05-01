// purchases-web.ts — Restore purchases helper for Web
// RevenueCat JS SDK does not have a dedicated restore function.
// Re-logging in the current user refreshes the CustomerInfo cache.

import { Purchases } from '@revenuecat/purchases-js';

export async function restorePurchases(): Promise<void> {
  try {
    // Refresh CustomerInfo from RevenueCat servers
    await Purchases.getSharedInstance().getCustomerInfo();
  } catch (err) {
    console.error("Failed to restore purchases:", err);
    throw err;
  }
}
