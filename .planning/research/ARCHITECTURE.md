# Architecture Research: M009 Subscription & Payments

**Domain:** Integrating RevenueCat subscription management into existing WoofTalk multi-platform architecture
**Researched:** 2026-04-14
**Confidence:** HIGH

---

## Integration Points with Existing Systems

### Current Architecture

```
iOS (SwiftUI) ─────┐
Android (Compose) ──┤
Web (Next.js) ──────┼──▶ Supabase (PostgreSQL + Edge Functions + Auth)
Watch (Wear OS) ────┘         │
                              ├─ 8 tables, 30+ RLS policies
                              ├─ 6 Edge Functions
                              ├─ Upstash Redis (rate limiting)
                              └─ REST API Gateway (API key auth)
```

### New Architecture (Subscription Layer Added)

```
iOS ─── StoreKit 2 ──▶ RevenueCat ──▶ Supabase
Android ── Play Billing ──▶ RevenueCat ──▶ Supabase
Web ────── Stripe ──────▶ RevenueCat ──▶ Supabase
                                        │
                                        ├─ subscription_status table
                                        ├─ entitlement-check Edge Function
                                        ├─ entitlement-webhook Edge Function
                                        └─ Updated RLS policies
```

---

## What's New vs Modified vs Removed

### New Components

| Component | Platform | Purpose |
|-----------|----------|---------|
| `Purchases` SDK configuration | iOS, Android, Web | Initialize RevenueCat with API key + Supabase auth user ID |
| `PaywallView` / paywall UI | iOS, Android, Web | Display subscription offerings |
| `EntitlementManager` | iOS, Android, Web | Wrapper around `CustomerInfo` — provides `isPremium`, `isTrialActive`, `dailyTranslationsUsed` |
| `subscription_status` table | Supabase | Cache entitlement state server-side |
| `entitlement-check` Edge Function | Supabase | Server-side entitlement verification |
| `entitlement-webhook` Edge Function | Supabase | Process RevenueCat webhook events |
| `revenuecat_id` column | `user_profiles` table | Link Supabase auth users to RevenueCat customer IDs |
| RLS policies for free tier enforcement | Supabase | Limit `translation_requests` INSERT for free users |
| Subscription status in admin dashboard | Web | Show subscription tier, trial status, cancellation date |

### Modified Components

| Component | Platform | What Changes |
|-----------|----------|-------------|
| `TranslationViewController` / translation flow | iOS | Check entitlement before translation. Show upgrade prompt if free limit reached. |
| `TranslationScreen` / translation flow | Android | Same entitlement check pattern |
| `TranslationPage` / translation flow | Web | Same entitlement check pattern |
| `AITranslationService` | iOS, Android | Premium-only feature. Check entitlement before allowing AI translation. |
| `CommunityPhraseView` | iOS, Android, Web | Contribute requires subscription. View free for all. |
| `HistoryView` | iOS, Android, Web | Free: last 10 items. Premium: unlimited. |
| API Gateway rate limiter | Supabase | Check subscription tier for rate limit tiering (premium = higher limits) |
| `user_profiles` table | Supabase | Add `revenuecat_id` column |

### Removed Components

None. This is purely additive.

---

## Data Flow: Subscription Lifecycle

### 1. New User → Free Trial Start

```
User opens app
  → Supabase Auth sign-up (existing)
  → App initializes RevenueCat with auth.uid as appUserID
  → RevenueCat creates customer
  → User sees paywall with "Start 7-day free trial"
  → User subscribes (StoreKit/Play Billing/Stripe)
  → RevenueCat processes purchase
  → RevenueCat webhook → entitlement-webhook Edge Function
  → Edge Function updates subscription_status (tier: 'trial', trial_ends_at: +7 days)
  → RevenueCat SDK updates CustomerInfo cache
  → App enables all features
```

### 2. Trial Expires → Soft Paywall

```
Trial period ends (7 days)
  → RevenueCat webhook: EXPIRATION event
  → Edge Function updates subscription_status (tier: 'free')
  → App checks entitlement → free tier
  → User can do 3 translations/day
  → After 3rd translation, upgrade prompt appears
  → Premium features (AI, unlimited history, export) show lock icon
```

### 3. Free User Upgrades → Paid

```
User taps "Upgrade" on paywall or lock icon
  → PaywallView presents offerings
  → User selects monthly ($4.99) or annual ($39.99)
  → Purchase completes
  → RevenueCat webhook: INITIAL_PURCHASE event
  → Edge Function updates subscription_status (tier: 'pro')
  → App enables all features
```

### 4. Paid User Cancels

```
User cancels via platform settings
  → RevenueCat webhook: CANCELLATION event
  → Edge Function updates subscription_status (cancelled_at, still active until period end)
  → App shows "Your subscription expires on [date]"
  → At period end: EXPIRATION event → tier becomes 'free'
```

### 5. Server-Side Entitlement Check (API Gateway)

```
Client makes API request with auth token
  → API Gateway / Edge Function checks subscription_status table
  → If tier='free' and daily count >= 3 → 403 with upgrade prompt
  → If tier='pro' or daily count < 3 → allow request
  → Cache entitlement for 5 min (reduce RevenueCat API calls)
```

---

## Suggested Build Order

```
Phase 50: RevenueCat SDK Integration
  → iOS SDK, Android SDK, Web SDK initialization
  → Supabase user → RevenueCat customer ID linking
  → Basic entitlement checking (ClientInfo wrapper)
  → Verify: SDK configured, customer created, entitlements readable

Phase 51: Subscription Backend
  → subscription_status table + migration
  → entitlement-check Edge Function
  → entitlement-webhook Edge Function
  → Updated RLS policies for free tier
  → Verify: Webhooks received, entitlement cached, RLS enforces limits

Phase 52: Paywall UI
  → iOS PaywallView (RevenueCatUI or custom)
  → Android PaywallView
  → Web paywall (React component)
  → Offering configuration in RevenueCat dashboard
  → Verify: Paywall displays, purchase flow completes, entitlement updates

Phase 53: Feature Gating & Soft Paywall
  → EntitlementManager on each platform
  → Translation limit enforcement (3/day free)
  → Premium feature gating (AI, community, export)
  → Upgrade prompts and lock icons
  → History limit (last 10 for free)
  → Verify: Free users limited, premium users unrestricted, prompts display

Phase 54: Cross-Platform Sync & Admin
  → Cross-platform entitlement verification (subscribe on iOS, works on Android/Web)
  → Admin dashboard: subscription status column
  → Restore purchases flow
  → Subscription management deep links
  → RevenueCat analytics setup
  → Verify: Cross-platform works, admin shows status, restore works
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|----------|
| User identity | Supabase auth.uid as RevenueCat appUserID | Single source of truth. No anonymous users — WoofTalk requires auth. |
| Entitlement source of truth | RevenueCat (cache locally) | RevenueCat is the subscription authority. Local cache reduces latency. |
| Free tier enforcement | Server-side (RLS) + client-side (EntitlementManager) | Dual enforcement prevents bypass. RLS is the hard gate. |
| Paywall approach | RevenueCatUI on iOS/Android, custom React on Web | Fastest path on mobile. Web needs custom due to Stripe Checkout flow. |
| Webhook reliability | RevenueCat retries failed webhooks for 72 hours | RevenueCat handles retry. Edge Function must be idempotent. |

---

## Sources

- RevenueCat Architecture: https://www.revenuecat.com/docs/getting-started
- RevenueCat Webhooks: https://www.revenuecat.com/docs/webhooks
- RevenueCat User Identity: https://www.revenuecat.com/docs/user-ids
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
