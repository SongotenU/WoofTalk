"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Purchases } from "@revenuecat/purchases-js";
import { supabase } from "@/lib/supabase";
import { useEntitlementStore } from "@/lib/entitlement-store";
import { isRevenueCatInitialized } from "@/lib/revenuecat";

interface PlanOffering {
  identifier: string;
  product: {
    identifier: string;
    priceString: string;
    title: string;
    description: string;
  };
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

  // Check for referral code in URL
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const ref = params.get("ref");
    if (ref) {
      setReferralCode(ref);
      // Store referral code for when user subscribes
      localStorage.setItem("wooftalk_referral", ref);
      setReferralApplied(true);
    }
  }, []);

  // Fetch offerings on mount (PAY-09)
  useEffect(() => {
    async function loadOfferings() {
      if (!isRevenueCatInitialized()) {
        setOfferingsError(true);
        return;
      }
      try {
        const offerings = await Purchases.getSharedInstance().getOfferings();
        const current = offerings.current;
        if (!current) {
          setOfferingsError(true);
          return;
        }
        const monthlyOffer = current.availablePackages.find(
          (p) => p.product.identifier === "wooftalk_monthly"
        );
        const annualOffer = current.availablePackages.find(
          (p) => p.product.identifier === "wooftalk_annual"
        );
        if (monthlyOffer) {
          setMonthly({
            identifier: monthlyOffer.identifier,
            product: {
              identifier: monthlyOffer.product.identifier,
              priceString: monthlyOffer.product.priceString,
              title: monthlyOffer.product.title,
              description: monthlyOffer.product.description,
            },
          });
        }
        if (annualOffer) {
          setAnnual({
            identifier: annualOffer.identifier,
            product: {
              identifier: annualOffer.product.identifier,
              priceString: annualOffer.product.priceString,
              title: annualOffer.product.title,
              description: annualOffer.product.description,
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

  // Poll entitlement after checkout (D-06)
  useEffect(() => {
    if (!checkoutOpen) return;
    const interval = setInterval(() => {
      if (useEntitlementStore.getState().isPremium) {
        clearInterval(interval);
        setCheckoutOpen(false);
        router.push("/settings");
      }
    }, 3000);
    const timeout = setTimeout(() => {
      clearInterval(interval);
      setCheckoutOpen(false);
    }, 120000);
    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [checkoutOpen, router]);

  // Redirect if already premium
  useEffect(() => {
    if (isPremium && !checkoutOpen) {
      router.push("/settings");
    }
  }, [isPremium, checkoutOpen, router]);

  const handleSubscribe = useCallback(async () => {
    if (!selectedPlan || !isReadyToAccessPaywall) return;
    setPurchaseError("");
    setLoading(true);

    try {
      const offerings = await Purchases.getSharedInstance().getOfferings();
      const current = offerings.current;
      if (!current) {
        setPurchaseError("Subscription options unavailable. Please try again.");
        setLoading(false);
        return;
      }

      const pkg = selectedPlan === "monthly"
        ? current.availablePackages.find((p) => p.product.identifier === "wooftalk_monthly")
        : current.availablePackages.find((p) => p.product.identifier === "wooftalk_annual");

      if (!pkg) {
        setPurchaseError("Plan not found. Please try again.");
        setLoading(false);
        return;
      }

      // D-06: RevenueCat hosted checkout (Stripe) opens in new tab
      const { url } = await Purchases.getSharedInstance().getWebPurchaseURL(pkg);
      if (url) {
        // Apply referral code if present
        const storedRef = localStorage.getItem("wooftalk_referral");
        if (storedRef) {
          try {
            const { data: { user } } = await supabase.auth.getUser();
            if (user) {
              await supabase.rpc("apply_referral_code", {
                p_user_id: user.id,
                p_code: storedRef
              });
              localStorage.removeItem("wooftalk_referral");
            }
          } catch (err) {
            console.error("Failed to apply referral:", err);
          }
        }
        window.open(url, "_blank");
        setCheckoutOpen(true);
      } else {
        setPurchaseError("Purchase couldn't be completed. Please try again or restore purchases.");
      }
    } catch {
      setPurchaseError("Purchase couldn't be completed. Please try again or restore purchases.");
    } finally {
      setLoading(false);
    }
  }, [selectedPlan, isReadyToAccessPaywall, setLoading]);

  const handleRestore = useCallback(async () => {
    setRestoring(true);
    setRestoreMessage("");
    try {
      const customerInfo = await Purchases.getSharedInstance().restorePurchases();
      const proEntitlement = customerInfo.entitlements.all["pro"];
      if (proEntitlement?.isActive) {
        useEntitlementStore.getState().fromCustomerInfo(customerInfo);
        setRestoreMessage("Subscription restored!");
        setTimeout(() => router.push("/settings"), 1500);
      } else {
        setRestoreMessage("No previous subscription found for this account.");
      }
    } catch {
      setRestoreMessage("No previous subscription found for this account.");
    } finally {
      setRestoring(false);
    }
  }, [router]);

  // Auth gate
  if (!isReadyToAccessPaywall) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center p-8">
          <h1 className="text-xl font-semibold mb-4">Sign In Required</h1>
          <p className="text-muted-foreground mb-4">Please sign in to manage your subscription.</p>
          <Link href="/settings" className="text-primary hover:underline">Back to Settings</Link>
        </div>
      </div>
    );
  }

  // Empty state (PAY-09)
  if (offeringsError) {
    return (
      <div className="min-h-screen bg-background">
        <nav className="border-b">
          <div className="container mx-auto px-4 py-4 flex items-center justify-between">
            <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          </div>
        </nav>
        <div className="container mx-auto px-4 py-16 max-w-3xl text-center">
          <h1 className="text-xl font-semibold mb-2">Subscription Unavailable</h1>
          <p className="text-muted-foreground mb-6">We couldn&apos;t load subscription options. Check your connection and try again.</p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  // Checkout open state (D-06)
  if (checkoutOpen) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center p-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4" />
          <h1 className="text-xl font-semibold mb-2">Complete your purchase in the other tab</h1>
          <p className="text-muted-foreground">This page will update automatically.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-3xl">
        {/* Referral banner */}
        {referralApplied && (
          <div className="bg-primary/10 text-primary px-4 py-3 rounded-lg mb-6 text-center">
            <p className="font-medium">You were referred by a friend!</p>
            <p className="text-sm">Complete your subscription and you'll both get 1 month free.</p>
          </div>
        )}

        <div className="text-center mb-8">
          <h1 className="text-[28px] font-semibold leading-tight">Choose Your Plan</h1>
          <p className="text-sm text-muted-foreground mt-2">7-day free trial on all plans</p>
        </div>

        <div className="flex flex-col md:flex-row gap-6 mb-8">
          {/* Monthly Card */}
          <button
            onClick={() => setSelectedPlan("monthly")}
            className={`flex-1 p-6 bg-card rounded-lg border-2 text-left transition-colors ${
              selectedPlan === "monthly" ? "border-primary" : "border-transparent"
            }`}
          >
            <h2 className="text-xl font-semibold mb-4">Monthly</h2>
            <p className="text-[28px] font-semibold leading-tight">
              {monthly?.product.priceString ?? "$4.99"}/month
            </p>
            <p className="text-sm text-muted-foreground mt-2">7-day free trial</p>
            <p className="text-sm text-muted-foreground">then {monthly?.product.priceString ?? "$4.99"}/month</p>
          </button>

          {/* Annual Card */}
          <button
            onClick={() => setSelectedPlan("annual")}
            className={`flex-1 p-5 bg-card rounded-lg border-2 text-left transition-colors relative ${
              selectedPlan === "annual" ? "border-primary" : "border-transparent"
            }`}
          >
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold">Annual</h2>
              <span className="bg-primary text-primary-foreground rounded-full px-3 py-1 text-sm">
                Save 33%
              </span>
            </div>
            <p className="text-[28px] font-semibold leading-tight">
              {annual?.product.priceString ?? "$39.99"}/year
            </p>
            <p className="text-sm text-muted-foreground mt-2">7-day free trial</p>
            <p className="text-sm text-muted-foreground">then {annual?.product.priceString ?? "$39.99"}/year</p>
          </button>
        </div>

        {selectedPlan && (
          <div className="mb-6">
            <button
              onClick={handleSubscribe}
              disabled={isLoading}
              className="w-full h-12 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 text-sm font-semibold disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <span className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary-foreground" />
                  Verifying subscription...
                </>
              ) : (
                "Start Free Trial"
              )}
            </button>
            {purchaseError && (
              <p className="text-sm text-destructive mt-2">{purchaseError}</p>
            )}
          </div>
        )}

        <div className="text-center">
          <button
            onClick={handleRestore}
            disabled={restoring}
            className="text-sm text-muted-foreground hover:text-foreground hover:underline disabled:opacity-50"
          >
            {restoring ? "Restoring..." : "Restore Purchases"}
          </button>
          {restoreMessage && (
            <p className="text-sm text-muted-foreground mt-1">{restoreMessage}</p>
          )}
        </div>

        {/* Promo Code Section */}
        <div className="max-w-md mx-auto mt-8 pt-8 border-t">
          <PromoCodeInput />
        </div>
      </main>
    </div>
  );
}

function PromoCodeInput() {
  const [code, setCode] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const handleApply = async () => {
    if (!code.trim()) return;
    setLoading(true);
    setMessage("");

    try {
      // RevenueCat doesn't directly expose promo code redemption via JS SDK
      // Show instructions to user
      setMessage("Please enter your promo code during checkout in the payment window.");
    } catch (err: any) {
      setMessage(err.message || "Invalid promo code");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="text-center">
      <p className="text-sm font-medium mb-3">Have a promo code?</p>
      <div className="flex gap-2 max-w-xs mx-auto">
        <input
          type="text"
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          placeholder="PROMO2026"
          className="flex-1 px-3 py-2 rounded-lg border border-border bg-background text-sm uppercase"
        />
        <button
          onClick={handleApply}
          disabled={!code.trim() || loading}
          className="px-4 py-2 bg-secondary text-secondary-foreground rounded-lg text-sm hover:bg-secondary/90 disabled:opacity-50"
        >
          {loading ? "..." : "Apply"}
        </button>
      </div>
      {message && (
        <p className="text-xs text-muted-foreground mt-2">{message}</p>
      )}
    </div>
  );
}
