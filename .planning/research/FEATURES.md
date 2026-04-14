# Feature Research: M009 Subscription & Payments

**Domain:** Subscription monetization for multi-platform dog translation app
**Researched:** 2026-04-14
**Confidence:** HIGH

---

## Table Stakes (Must Have)

### Entitlement Management

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Free trial with 7-day full access** | Standard for freemium mobile apps — users need to experience value before paying | LOW | RevenueCat intro offers. Both monthly and annual plans include trial. |
| **Subscription status checking** | App must know if user is on free, trial, or paid tier at all times | LOW | `CustomerInfo.activeEntitlements` from RevenueCat SDK. Cached locally. |
| **Paywall screen** | Users need a way to see plans and subscribe | MEDIUM | RevenueCatUI provides pre-built paywalls, or custom SwiftUI/Compose UI. |
| **Restore purchases** | Required by Apple for all subscription apps | LOW | `Purchases.shared.restorePurchases()`. RevenueCatUI paywalls include restore button by default. |
| **Subscription management** | Users must be able to cancel or change plan | LOW | Deep link to OS settings (iOS: `App Store subscriptions`, Android: `Google Play subscriptions`). No in-app cancellation — platform handles it. |
| **Cross-platform entitlement sync** | User subscribes on iOS, entitlements work on Android/Web | MEDIUM | RevenueCat handles this via shared `appUserID` linked to Supabase auth. Requires login. |
| **Offline grace period** | App must work if network unavailable and cached entitlement is valid | LOW | RevenueCat SDK caches `CustomerInfo`. Allow access if last known state was active. |

### Free Tier / Soft Paywall

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Limited free translations per day** | Soft paywall — 3 translations/day after trial expires. Retains users, drives upgrade. | MEDIUM | Server-side counter in `translation_requests` table + RLS policy. Client displays remaining count. |
| **Free tier feature access** | Some features remain free (basic translation, view history) while premium features require subscription | LOW | Feature flags based on entitlement check. Premium: unlimited translations, AI translation, community phrases, export. |
| **Upgrade prompts** | When free user hits limit, prompt to upgrade | LOW | Non-blocking banner or modal after 3rd translation. Link to paywall. |

### Backend

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Server-side entitlement verification** | Client-side checks can be bypassed. API gateway and Edge Functions must verify. | MEDIUM | Edge Function calls RevenueCat REST API `GET /v1/subscribers/{id}`. Cache result for 5 min. |
| **Webhook handler** | RevenueCat events (trial started, renewal, cancellation) must update local state | MEDIUM | Edge Function receives RevenueCat webhooks, updates `subscription_status` table. |
| **Free tier enforcement in RLS** | Translation limit must be enforced at database level, not just client-side | MEDIUM | RLS policy checks `subscription_tier` + daily translation count before allowing INSERT. |

---

## Differentiator Features (Nice to Have)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Annual plan discount highlight** | "Save 33%" badge on annual plan — drives higher LTV | LOW | RevenueCat offerings metadata. UI shows savings calculation. |
| **Win-back offers** | Lapsed subscribers get discounted re-subscription offer | MEDIUM | Requires iOS 18+ / specific Play Console setup. RevenueCat supports it. |
| **Family sharing** | Family members share subscription without separate purchase | MEDIUM | iOS Family Sharing requires App Store Connect configuration. RevenueCat handles entitlement propagation. |
| **Usage analytics dashboard** | Track conversion rate, trial-to-paid, churn, MRR | LOW | RevenueCat dashboard provides this out-of-the-box. No custom code needed. |
| **A/B test paywall variants** | Test different paywall designs for conversion optimization | MEDIUM | RevenueCat Experiments feature. Requires multiple offering configurations. |
| **Deferred trials** | Trial starts only when user first uses the app, not on download | LOW | RevenueCat supports trial start date configuration. |
| **Grace period for payment failures** | User keeps access for 3-7 days after payment failure | LOW | RevenueCat Billing Grace Period (Google Play). iOS handles via StoreKit retry. |

---

## Anti-Features (Skip These)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Custom payment UI** | RevenueCatUI provides pre-built, App Store-compliant paywalls. Custom UI risks App Store rejection for violating subscription guidelines. | Use RevenueCatUI paywalls. Customize via RevenueCat dashboard templates. |
| **Lifetime deals** | One-time purchase defeats recurring revenue model. Hard to sustain server costs. | Monthly + annual subscriptions only. No lifetime option. |
| **Ad-supported free tier** | Dog translation app users expect clean UX. Ads degrade the experience and conflict with premium positioning. | Soft paywall with limited free translations. No ads. |
| **Multiple subscription tiers** (Basic/Pro/Enterprise) | App has one clear value proposition — translation. Tiered plans add complexity without proportional revenue for this app type. | Single "Pro" tier with monthly/annual billing. |
| **In-app subscription cancellation** | Apple and Google require cancellation through their native settings. Implementing in-app cancellation risks rejection. | Deep link to platform subscription management. |
| **Cryptocurrency payments** | Adds massive complexity, regulatory risk, and tiny conversion benefit for a dog translation app. | Stripe via RevenueCat for web. StoreKit/Play Billing for mobile. |
| **Custom receipt validation server** | RevenueCat validates all receipts. Building your own is error-prone, duplicates RevenueCat's core value, and adds operational burden. | Trust RevenueCat as source of truth. |

---

## Complexity Notes

### Platform-Specific Complexity

| Platform | Purchase Flow | Entitlement Check | Paywall | Key Risk |
|----------|---------------|-------------------|---------|----------|
| **iOS** | StoreKit 2 → RevenueCat | `CustomerInfo.activeEntitlements` | RevenueCatUI / Custom SwiftUI | App Store review 3.1.1 — must use StoreKit, no external payment links |
| **Android** | Google Play Billing → RevenueCat | Same API | RevenueCatUI / Custom Compose | Play Console review — subscription pricing must match |
| **Web** | Stripe Checkout → RevenueCat | RevenueCat JS SDK | Custom React component or RevenueCat web paywall | Stripe account setup required, PCI compliance via Stripe |

### Integration Dependencies on Existing Features

| Existing Feature | Subscription Impact |
|------------------|-------------------|
| **Translation flow** | Free tier: limited to 3/day. Premium: unlimited. Must check entitlement before each translation. |
| **AI translation** | Premium-only feature. Free users see upgrade prompt when tapping AI. |
| **Community phrases** | View free, contribute requires subscription (anti-spam + premium feature). |
| **Translation history** | View limited (last 10) for free, unlimited for premium. |
| **Export/share** | Premium-only feature. |
| **Watch app** | Inherits phone subscription status. No separate purchase. |
| **AR/VR** | Premium-only features (given niche market, all AR/VR users likely pay). |
| **Admin dashboard** | Needs subscription status column in user management. |
| **API gateway** | Must check entitlement server-side before serving premium endpoints. |

---

## Sources

- RevenueCat Getting Started: https://www.revenuecat.com/docs/getting-started
- RevenueCat Entitlements: https://www.revenuecat.com/docs/entitlements
- RevenueCat Paywalls: https://www.revenuecat.com/docs/paywalls
- Apple App Store Review Guidelines 3.1.1: https://developer.apple.com/app-store/review/guidelines/#payments
- Google Play Billing: https://developer.android.com/google/play/billing
