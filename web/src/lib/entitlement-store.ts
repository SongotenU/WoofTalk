import { create } from 'zustand';
import type { CustomerInfo } from '@revenuecat/purchases-js';

interface EntitlementState {
  isPremium: boolean;
  isTrialActive: boolean;
  dailyTranslationsUsed: number;
  subscriptionTier: string;
  isLoading: boolean;
  isAuthenticated: boolean;
  // SDK-06: Unauthenticated users cannot access paywall
  isReadyToAccessPaywall: boolean;

  fromCustomerInfo: (customerInfo: CustomerInfo) => void;
  setAuthenticated: (value: boolean) => void;
  setLoading: (value: boolean) => void;
  reset: () => void;
}

const initialState = {
  isPremium: false,
  isTrialActive: false,
  dailyTranslationsUsed: 0,
  subscriptionTier: 'free',
  isLoading: false,
  isAuthenticated: false,
  isReadyToAccessPaywall: false,
};

export const useEntitlementStore = create<EntitlementState>((set) => ({
  ...initialState,

  // SDK-04: Single entitlement source from CustomerInfo
  fromCustomerInfo(customerInfo: CustomerInfo) {
    const proEntitlement = customerInfo.entitlements.all['pro'];
    const isPremiumActive = proEntitlement?.isActive === true;
    const isTrial = isPremiumActive && customerInfo.activeSubscriptions.size === 0;

    set({
      isPremium: isPremiumActive,
      isTrialActive: isTrial,
      subscriptionTier: isPremiumActive && !isTrial ? 'pro' : isPremiumActive && isTrial ? 'trial' : 'free',
    });
  },

  setAuthenticated(value: boolean) {
    set({ isAuthenticated: value, isReadyToAccessPaywall: value });
  },

  setLoading(value: boolean) {
    set({ isLoading: value });
  },

  reset() {
    set(initialState);
  },
}));
