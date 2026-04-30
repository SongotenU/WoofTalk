"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useEntitlementStore } from "@/lib/entitlement-store";
import { purchases } from "@/lib/revenuecat";
import { supabase } from "@/lib/supabase";

interface RcbillingProduct {
  identifier: string;
  currentPrice: { formattedPrice: string };
  title: string;
  description: string | null;
}

interface PlanOffering {
  identifier: string;
  rcBillingProduct: RcbillingProduct;
}

export default function SubscribePage() {
  const router = useRouter();
  const { isPremium, isTrialActive, isReadyToAccessPaywall, setLoading, isLoading } = useEntitlementStore();
  const [monthly, setMonthly] = useState<PlanOffering | null>(null);
  const [annual, setAnnual] = useState<PlanOffering | null>(null);
  const [selectedPlan, setSelectedPlan] = useState<"monthly" | "annual" | null>(null);
  const [offeringsError, setOfferingsError] = useState(false);
  const [purchaseError, setPurchaseError] = useState("");
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [restoring, setRestoring] = useState(false);
  const [restoreMessage, setRestoreMessage] = useState("");
  const [referralCode, setReferralCode] = useState<string | null>(null);
  const [referralApplied, setReferralApplied] = useState(false);

  // Paywall gate: if user already has access or isn't ready yet, redirect
  useEffect(() => {
    if (isPremium || !isReadyToAccessPaywall) {
      router.push("/translate");
    }
  }, [isPremium, isReadyToAccessPaywall, router]);

  // Fetch offerings on mount (PAY-09)
  useEffect(() => {
    async function loadOfferings() {
      if (!purchases.getSharedInstance) {
        setOfferingsError(true);
        return;
      }
      try {
        const offerings = await purchases.getSharedInstance().getOfferings();
        const current = offerings.current;
        if (!current) {
          setOfferingsError(true);
          return;
        }
        const monthlyOffer = current.availablePackages.find(
          (p) => p.rcBillingProduct.identifier === "wooftalk_monthly"
        );
        const annualOffer = current.availablePackages.find(
          (p) => p.rcBillingProduct.identifier === "wooftalk_annual"
        );
        if (monthlyOffer) {
          setMonthly({
            identifier: monthlyOffer.identifier,
            rcBillingProduct: {
              identifier: monthlyOffer.rcBillingProduct.identifier,
              currentPrice: {
                formattedPrice: monthlyOffer.rcBillingProduct.currentPrice.formattedPrice,
              },
              title: monthlyOffer.rcBillingProduct.title as string,
              description: monthlyOffer.rcBillingProduct.description,
            },
          });
        }
        if (annualOffer) {
          setAnnual({
            identifier: annualOffer.identifier,
            rcBillingProduct: {
              identifier: annualOffer.rcBillingProduct.identifier,
              currentPrice: {
                formattedPrice: annualOffer.rcBillingProduct.currentPrice.formattedPrice,
              },
              title: annualOffer.rcBillingProduct.title as string,
              description: annualOffer.rcBillingProduct.description,
            },
          });
        }
        if (!monthlyOffer && !annualOffer) {
          setOfferingsError(true);
        }
      } catch {
        setOfferingsError(true);
      }
    }
    loadOfferings();
  }, []);

  // Set loading state for paywall
  useEffect(() => {
    setLoading(isLoading);
  }, [isLoading, setLoading]);

  // Apply referral code
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const ref = urlParams.get("ref");
    if (ref) {
      setReferralCode(ref);
      localStorage.setItem("wooftalk_referral", ref);
      setReferralApplied(true);
    }
  }, []);

  const handleSubscribe = async (packageId: string) => {
    if (!checkoutOpen) return;
    const rcOffer = await purchases.getSharedInstance().getOfferings();
    const packageToPurchase = rcOffer.current?.availablePackages.find(
      (p) => p.identifier === packageId
    );
    if (!packageToPurchase) {
      setPurchaseError("Selected plan not found");
      return;
    }

    try {
      setLoading(true);
      await purchases.getSharedInstance().purchasePackage(packageToPurchase);
      router.push("/translate");
    } catch (err: any) {
      setPurchaseError(err.message || "Purchase failed");
    } finally {
      setLoading(false);
    }
  };

  const handleRestore = async () => {
    setRestoring(true);
    setRestoreMessage("");
    try {
      const { restorePurchases } = await import("@/lib/purchases-web");
      await restorePurchases();
      setRestoreMessage("Purchases restored successfully!");
    } catch {
      setRestoreMessage("Failed to restore purchases. Please try again.");
    } finally {
      setRestoring(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50">
      <header className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-primary">WoofTalk</h1>
          </div>
          <button
            onClick={() => router.push("/settings")}
            className="text-muted-foreground hover:text-foreground"
          >
            Settings
          </button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-12">
        {!isReadyToAccessPaywall ? (
          <div className="text-center py-20 space-y-6">
            {offeringsError ? (
              <>
                <div className="text-6xl">🐕</div>
                <h1 className="text-3xl font-bold text-gray-900">Unable to load plans</h1>
                <p className="text-gray-600 max-w-md mx-auto">
                  We couldn't load subscription plans. Please check your connection and try again.
                </p>
                <button
                  onClick={() => window.location.reload()}
                  className="bg-primary text-primary-foreground px-8 py-3 rounded-xl hover:bg-primary/90 transition-colors"
                >
                  Try Again
                </button>
              </>
            ) : (
              <>
                <div className="text-6xl">🐕</div>
                <h1 className="text-3xl font-bold text-gray-900">Upgrade to Pro</h1>
                <p className="text-gray-600 max-w-md mx-auto">
                  Unlock premium translation features with our subscription plan.
                </p>
                <div className="flex gap-4 justify-center mt-8">
                  {monthly && (
                    <button
                      onClick={() => {
                        setSelectedPlan("monthly");
                        setCheckoutOpen(true);
                      }}
                      className="bg-primary text-primary-foreground px-8 py-3 rounded-xl hover:bg-primary/90 transition-colors min-w-[160px]"
                      disabled={isLoading}
                    >
                      {isLoading ? "Loading..." : monthly.rcBillingProduct.currentPrice.formattedPrice}
                    </button>
                  )}
                  {annual && (
                    <button
                      onClick={() => {
                        setSelectedPlan("annual");
                        setCheckoutOpen(true);
                      }}
                      className="border-2 border-primary text-primary px-8 py-3 rounded-xl hover:bg-primary/5 transition-colors min-w-[160px]"
                      disabled={isLoading}
                    >
                      {isLoading ? "Loading..." : annual.rcBillingProduct.currentPrice.formattedPrice}
                    </button>
                  )}
                </div>
                {purchaseError && (
                  <p className="text-red-500 text-sm mt-4">{purchaseError}</p>
                )}
              </>
            )}

            <div className="mt-8">
              <button
                onClick={handleRestore}
                disabled={restoring}
                className="text-sm text-muted-foreground hover:text-foreground transition-colors"
              >
                {restoring ? "Restoring..." : "Restore Purchases"}
              </button>
              {restoreMessage && (
                <p className="text-sm mt-2 text-green-600">{restoreMessage}</p>
              )}
            </div>
          </div>
        ) : (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">🎉</div>
            <h1 className="text-3xl font-bold text-gray-900 mb-4">
              You already have Pro access!
            </h1>
            <p className="text-gray-600 mb-8">
              Your subscription is active. Enjoy all premium features.
            </p>
            <button
              onClick={() => router.push("/translate")}
              className="bg-primary text-primary-foreground px-8 py-3 rounded-xl hover:bg-primary/90 transition-colors"
            >
              Start Translating
            </button>
          </div>
        )}
      </main>

      {/* Checkout Modal */}
      {checkoutOpen && selectedPlan && monthly && annual && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-8 max-w-md w-full">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold">Subscribe to Pro</h2>
              <button
                onClick={() => setCheckoutOpen(false)}
                className="text-muted-foreground hover:text-foreground"
              >
                ✕
              </button>
            </div>

            <div className="mb-6">
              <div className="bg-purple-50 rounded-xl p-4 mb-4">
                <div className="flex justify-between mb-2">
                  <span className="font-medium">
                    {selectedPlan === "monthly" ? "Monthly Plan" : "Annual Plan"}
                  </span>
                  <span className="text-primary font-bold">
                    {selectedPlan === "monthly"
                      ? monthly.rcBillingProduct.currentPrice.formattedPrice
                      : annual.rcBillingProduct.currentPrice.formattedPrice}
                  </span>
                </div>
                <p className="text-sm text-gray-600">
                  {selectedPlan === "monthly"
                    ? monthly.rcBillingProduct.description
                    : annual.rcBillingProduct.description}
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setSelectedPlan("monthly")}
                  className={`flex-1 py-2 rounded-lg transition-colors ${
                    selectedPlan === "monthly"
                      ? "bg-primary text-primary-foreground"
                      : "bg-gray-100 hover:bg-gray-200"
                  }`}
                >
                  Monthly
                </button>
                <button
                  onClick={() => setSelectedPlan("annual")}
                  className={`flex-1 py-2 rounded-lg transition-colors ${
                    selectedPlan === "annual"
                      ? "bg-primary text-primary-foreground"
                      : "bg-gray-100 hover:bg-gray-200"
                  }`}
                >
                  Annual
                </button>
              </div>
            </div>

            <button
              onClick={() =>
                handleSubscribe(
                  selectedPlan === "monthly"
                    ? monthly.identifier
                    : annual.identifier
                )
              }
              disabled={isLoading}
              className="w-full bg-primary text-primary-foreground py-3 rounded-xl hover:bg-primary/90 transition-colors disabled:opacity-50"
            >
              {isLoading
                ? "Processing..."
                : `Subscribe - ${
                    selectedPlan === "monthly"
                      ? monthly.rcBillingProduct.currentPrice.formattedPrice
                      : annual.rcBillingProduct.currentPrice.formattedPrice
                  }`}
            </button>

            {purchaseError && (
              <p className="text-red-500 text-center mt-2 text-sm">
                {purchaseError}
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
