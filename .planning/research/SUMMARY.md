# Research Summary: M009 Subscription & Payments

**Milestone:** v1.0 Subscription & Payments
**Synthesized:** 2026-04-14
**Sources:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

---

## Stack Additions

| Platform | SDK | Version | Purpose |
|----------|-----|---------|---------|
| iOS | RevenueCat + RevenueCatUI | 5.43.0+ | StoreKit 2 purchases + pre-built paywalls |
| Android | purchases + purchases-ui | 9.9.0+ | Play Billing purchases + pre-built paywalls |
| Web | @revenuecat/purchases-js + stripe-js | 1.0+ | Web entitlements + Stripe Checkout |
| Backend | 2 Edge Functions | N/A | entitlement-check + entitlement-webhook |
| Database | subscription_status table + RLS policies | N/A | Server-side entitlement cache + free tier enforcement |

**No new infrastructure.** RevenueCat handles receipt validation, subscription lifecycle, cross-platform identity.

---

## Feature Table Stakes

| Feature | Priority | Complexity |
|---------|----------|------------|
| Free trial (7-day full access) | Must | LOW |
| Subscription status checking | Must | LOW |
| Paywall screen | Must | MEDIUM |
| Restore purchases | Must | LOW |
| Subscription management (deep link) | Must | LOW |
| Cross-platform entitlement sync | Must | MEDIUM |
| Offline grace period | Must | LOW |
| Limited free translations (3/day) | Must | MEDIUM |
| Server-side entitlement verification | Must | MEDIUM |
| Webhook handler | Must | MEDIUM |
| RLS free tier enforcement | Must | MEDIUM |
| Upgrade prompts | Must | LOW |

**Nice-to-haves:** Annual discount badge, win-back offers, family sharing, A/B test paywalls, usage analytics.

---

## Architecture Changes

**New:** RevenueCat SDK on 3 platforms, subscription_status table, 2 Edge Functions, EntitlementManager wrapper, PaywallView, RLS policies.

**Modified:** Translation flow (entitlement check before each translation), AI translation (premium-only), Community phrases (contribute requires sub), History (last 10 for free), API Gateway rate limiter (tiered), user_profiles (+ revenuecat_id column).

**Removed:** None. Purely additive.

**Key decisions:**
- Supabase auth.uid as RevenueCat appUserID (single source of truth)
- RevenueCat as entitlement authority, cache locally
- Dual enforcement: RLS (hard gate) + client EntitlementManager (UX layer)
- RevenueCatUI on mobile, custom React paywall on Web

---

## Watch Out For

1. **App Store 3.1.1** — iOS paywall must use StoreKit only. No external payment links or "cheaper on web" text. Will cause rejection.
2. **Stale entitlement cache** — After purchase, call getCustomerInfo() immediately. Show loading until entitlement confirmed.
3. **API bypass** — Free users can call Edge Functions directly. RLS must enforce 3/day limit server-side.
4. **Cross-platform desync** — Use auth.uid as appUserID on ALL platforms. Require login before paywall.
5. **Play Console pricing mismatch** — Create products in App Store Connect/Play Console FIRST, then configure in RevenueCat. Product IDs must match exactly.
6. **Webhook idempotency** — Use event_id as idempotency key. Return 200 OK quickly. Make updates idempotent (UPDATE not INSERT).
7. **Trial abuse** — Low risk for dog translation app. RevenueCat fraud detection sufficient. Don't over-engineer.

---

## Build Order Suggestion

| Phase | Focus | Key Deliverable |
|-------|-------|----------------|
| 50 | RevenueCat SDK Integration | SDK configured, customer created, entitlements readable |
| 51 | Subscription Backend | Webhooks received, entitlement cached, RLS enforces limits |
| 52 | Paywall UI | Paywall displays, purchase flow completes, entitlement updates |
| 53 | Feature Gating & Soft Paywall | Free users limited, premium unrestricted, prompts display |
| 54 | Cross-Platform Sync & Admin | Cross-platform works, admin shows status, restore works |

---

## New Environment Variables

| Variable | Where |
|----------|-------|
| REVENUECAT_API_KEY | Supabase Edge Functions |
| REVENUECAT_WEBHOOK_AUTH | Supabase Edge Functions |
| REVENUECAT_IOS_API_KEY | iOS app config |
| REVENUECAT_ANDROID_API_KEY | Android app config |
| STRIPE_SECRET_KEY | RevenueCat dashboard (not in app) |
