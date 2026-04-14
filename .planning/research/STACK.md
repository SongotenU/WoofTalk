# Stack Research: M009 Subscription & Payments

**Project:** WoofTalk
**Scope:** RevenueCat subscription integration across iOS, Android, Web
**Researched:** 2026-04-14
**Confidence:** HIGH

---

## Executive Summary

WoofTalk needs cross-platform subscription monetization. RevenueCat provides a unified SDK for iOS (StoreKit 2), Android (Google Play Billing), and Web (Stripe). The core stack addition is the RevenueCat SDK on each platform + a Supabase Edge Function for server-side entitlement verification. No new infrastructure — RevenueCat handles receipt validation, subscription lifecycle, and cross-platform identity.

---

## 1. SDK Additions

### iOS (Swift/SwiftUI)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **RevenueCat** | 5.43.0+ | Core purchase/entitlement SDK |
| **RevenueCatUI** | 5.43.0+ | Pre-built paywall templates (optional but recommended) |

**Installation:** Swift Package Manager
```swift
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.43.0")
```

**Integration points:**
- Initialize `Purchases.configure(withAPIKey:appUserID:)` in `@main` App struct
- Use `Purchases.shared.getCustomerInfo()` for entitlement checks
- Use `Purchases.shared.getOfferings()` for paywall data
- `RevenueCatUI` provides `PaywallView` for SwiftUI

### Android (Kotlin/Compose)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **com.revenuecat.purchases:purchases** | 9.9.0+ | Core purchase/entitlement SDK |
| **com.revenuecat.purchases:purchases-ui** | 9.9.0+ | Pre-built paywall templates |

**Installation:** Gradle
```kotlin
implementation("com.revenuecat.purchases:purchases:9.9.0")
implementation("com.revenuecat.purchases:purchases-ui:9.9.0")
```

**Integration points:**
- Initialize `Purchases.configure(withAPIKey:appUserID:)` in Application class
- Same API pattern as iOS: `getCustomerInfo()`, `getOfferings()`

### Web (Next.js/React)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **@revenuecat/purchases-js** | 1.0+ | RevenueCat JS SDK for web purchases |
| **stripe-js** | latest | Stripe Checkout for web payment flow |

**Installation:** npm
```bash
npm install @revenuecat/purchases-js
```

**Integration points:**
- RevenueCat Web Purchases uses Stripe as the payment processor
- Configure Stripe in RevenueCat dashboard (not directly in code)
- Use RevenueCat JS SDK for entitlement checking on web
- Purchase flow: RevenueCat-hosted checkout OR Stripe Checkout redirect

**Key difference:** Web purchases go through Stripe (not Apple/Google). RevenueCat acts as the unified entitlement layer.

---

## 2. Backend Additions

### Supabase Edge Function: Entitlement Verification

| Component | Purpose |
|-----------|---------|
| **`supabase/functions/entitlement-check/index.ts`** | Server-side entitlement verification using RevenueCat REST API |
| **`supabase/functions/entitlement-webhook/index.ts`** | Webhook handler for RevenueCat events (trial started, subscription renewed, cancelled) |

**Why server-side verification?** Client-side entitlement checks can be spoofed. Server-side checks ensure API gateway and admin dashboard respect actual subscription status.

**RevenueCat REST API (called from Edge Functions):**
- `GET /v1/subscribers/{app_user_id}` — Check entitlements server-side
- Webhook events: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`, `TRIAL_STARTED`

### Database Changes

| Migration | Purpose |
|-----------|---------|
| **Add `revenuecat_id` column to `user_profiles`** | Link Supabase users to RevenueCat customer IDs |
| **Add `subscription_status` table** | Cache entitlement state, reduce API calls to RevenueCat |

```sql
CREATE TABLE subscription_status (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  revenuecat_id TEXT NOT NULL UNIQUE,
  entitlements JSONB DEFAULT '{}',
  subscription_tier TEXT DEFAULT 'free',
  trial_ends_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### RLS Policies for Subscription Gating

```sql
-- Premium features only accessible to paid subscribers
CREATE POLICY "Premium features require active subscription"
  ON translation_requests
  FOR INSERT
  WITH CHECK (
    -- Free tier: limited translations per day
    (SELECT subscription_tier FROM subscription_status WHERE user_id = auth.uid()) != 'free'
    OR (
      (SELECT subscription_tier FROM subscription_status WHERE user_id = auth.uid()) = 'free'
      AND (SELECT COUNT(*) FROM translation_requests WHERE user_id = auth.uid() AND created_at > now() - interval '1 day') < 3
    )
  );
```

---

## 3. RevenueCat Dashboard Configuration

| Config Item | Value |
|-------------|-------|
| **Project** | WoofTalk |
| **Apps** | iOS (App Store Connect), Android (Google Play Console), Web (Stripe) |
| **Entitlements** | `pro` (unlocks all features) |
| **Offerings** | `default` — contains monthly + annual offerings |
| **Products** | `$4.99/mo` (wooftalk_monthly), `$39.99/yr` (wooftalk_annual) |
| **Free Trial** | 7-day intro offer on both plans |

---

## 4. Environment Variables

### New secrets needed

| Variable | Where | Purpose |
|----------|-------|---------|
| `REVENUECAT_API_KEY` | Supabase Edge Functions secrets | Server-side RevenueCat API calls |
| `REVENUECAT_WEBHOOK_AUTH` | Supabase Edge Functions secrets | Verify webhook authenticity |
| `REVENUECAT_IOS_API_KEY` | iOS app config | Client-side SDK initialization |
| `REVENUECAT_ANDROID_API_KEY` | Android app config | Client-side SDK initialization |
| `STRIPE_SECRET_KEY` | RevenueCat dashboard (not in app code) | Web payment processing |

### Existing variables (no changes)
- All existing Supabase, Vercel, and Upstash variables remain unchanged.

---

## 5. What NOT to Add

| Item | Why Not |
|------|---------|
| **No custom payment processor** | RevenueCat + Stripe handles all payment infrastructure. Building custom is wasted effort. |
| **No separate subscription database** | RevenueCat is the source of truth for subscriptions. Cache locally, don't duplicate. |
| **No PayPal integration** | RevenueCat's Stripe integration covers web payments. PayPal adds complexity without meaningful conversion lift for this app type. |
| **No IAP bypass for web** | Apple requires iOS purchases through StoreKit. Google requires Android through Play Billing. RevenueCat handles the routing — don't try to use Stripe on mobile. |
| **No custom receipt validation** | RevenueCat validates all receipts server-side. Rolling your own is error-prone and duplicates RevenueCat's core feature. |
| **No Shopify/other e-commerce** | WoofTalk is a subscription SaaS, not an e-commerce product. |

---

## Sources

- RevenueCat Getting Started: https://www.revenuecat.com/docs/getting-started (HIGH — official docs)
- RevenueCat SDK Reference: https://www.revenuecat.com/docs/sdk (HIGH — official docs)
- RevenueCat Web Purchases: https://www.revenuecat.com/docs/web (HIGH — official docs)
- RevenueCat REST API: https://www.revenuecat.com/docs/api-v1 (HIGH — official docs)
- StoreKit 2 Documentation: https://developer.apple.com/documentation/storekit (HIGH — Apple official)
- Google Play Billing: https://developer.android.com/google/play/billing (HIGH — Google official)
