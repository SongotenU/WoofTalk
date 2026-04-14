# Requirements: WoofTalk M009 Subscription & Payments

**Defined:** 2026-04-14
**Core Value:** Free trial → paid subscription with soft paywall, using RevenueCat across all platforms

## v1 Requirements

### SDK Integration

- [ ] **SDK-01**: RevenueCat SDK initialized on iOS with Supabase auth.uid as appUserID
- [ ] **SDK-02**: RevenueCat SDK initialized on Android with Supabase auth.uid as appUserID
- [ ] **SDK-03**: RevenueCat JS SDK initialized on Web with Supabase auth.uid as appUserID
- [ ] **SDK-04**: PurchasesDelegate/listener configured to react to CustomerInfo updates on all platforms
- [ ] **SDK-05**: After purchase, getCustomerInfo() called immediately to refresh entitlement cache
- [ ] **SDK-06**: Login required before paywall — no anonymous purchases

### Subscription Backend

- [ ] **SUB-01**: subscription_status table created with user_id, revenuecat_id, entitlements, subscription_tier, trial_ends_at, updated_at
- [ ] **SUB-02**: revenuecat_id column added to user_profiles table
- [ ] **SUB-03**: entitlement-webhook Edge Function handles RevenueCat events (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, TRIAL_STARTED)
- [ ] **SUB-04**: Webhook handler uses event_id as idempotency key — duplicate events ignored
- [ ] **SUB-05**: Webhook handler returns 200 OK quickly, processes updates via idempotent UPDATE (not INSERT)
- [ ] **SUB-06**: entitlement-check Edge Function verifies subscription server-side via RevenueCat REST API
- [ ] **SUB-07**: Server-side entitlement result cached for 5 minutes to reduce API calls
- [ ] **SUB-08**: RLS policy on translation_requests limits free users to 3 INSERTs per day
- [ ] **SUB-09**: RLS policy checks subscription_tier from subscription_status table
- [ ] **SUB-10**: Edge Functions check subscription_status before processing premium requests

### Paywall UI

- [ ] **PAY-01**: iOS PaywallView using RevenueCatUI with StoreKit-only purchases (no external payment links)
- [ ] **PAY-02**: Android PaywallView using RevenueCatUI with Play Billing purchases
- [ ] **PAY-03**: Web paywall using RevenueCat hosted checkout (Stripe)
- [ ] **PAY-04**: Paywall displays two offerings: monthly ($4.99/mo) and annual ($39.99/yr) with 7-day free trial
- [ ] **PAY-05**: Annual plan shows "Save 33%" discount badge
- [ ] **PAY-06**: iOS paywall contains no external payment links or "cheaper on web" text (Guideline 3.1.1 compliant)
- [ ] **PAY-07**: Restore purchases button present on all paywalls
- [ ] **PAY-08**: Loading state shown after purchase until entitlement confirmed
- [ ] **PAY-09**: Products verified via getOfferings() before paywall displayed

### Feature Gating

- [ ] **GATE-01**: Free tier limited to 3 translations per day (server-enforced via RLS)
- [ ] **GATE-02**: Free tier limited to last 10 history items; premium gets unlimited history
- [ ] **GATE-03**: AI translation restricted to premium users — free users see upgrade prompt
- [ ] **GATE-04**: Community phrase contribution restricted to premium users — viewing free for all
- [ ] **GATE-05**: Export/share restricted to premium users
- [ ] **GATE-06**: EntitlementManager wrapper provides isPremium, isTrialActive, dailyTranslationsUsed on all platforms
- [ ] **GATE-07**: After 3rd translation, free users see non-blocking upgrade prompt linking to paywall
- [ ] **GATE-08**: Premium features show lock icon when user is on free tier
- [ ] **GATE-09**: Watch app inherits phone subscription status (no separate purchase)

### Cross-Platform Sync

- [ ] **SYNC-01**: User subscribes on one platform, entitlements active on all platforms within 30 seconds
- [ ] **SYNC-02**: On app launch, Purchases.shared.logIn(auth.uid) called to ensure correct identity
- [ ] **SYNC-03**: Restore purchases flow available on all platforms
- [ ] **SYNC-04**: Subscription management via deep link to platform settings (iOS: App Store, Android: Play Store, Web: Stripe portal)

### Admin & Analytics

- [ ] **ADM-01**: Admin dashboard shows subscription tier column in user management
- [ ] **ADM-02**: Admin dashboard shows trial status and cancellation date per user
- [ ] **ADM-03**: RevenueCat analytics dashboard enabled (out-of-box, no custom code)

## v2 Requirements

### Enhanced Monetization

- **MON-01**: Win-back offers for lapsed subscribers (iOS 18+ / Play Console setup)
- **MON-02**: Family sharing for subscriptions (App Store Connect configuration)
- **MON-03**: A/B test paywall variants via RevenueCat Experiments
- **MON-04**: Deferred trials — trial starts on first app use, not on download

### Advanced Protection

- **PROT-01**: Device-level trial tracking (iOS identifierForVendor) for trial abuse prevention
- **PROT-02**: Email verification required before trial starts

## Out of Scope

| Feature | Reason |
|---------|--------|
| Custom payment UI | RevenueCatUI provides App Store-compliant paywalls. Custom UI risks rejection. |
| Lifetime deals | Defeats recurring revenue model. Hard to sustain server costs. |
| Ad-supported free tier | Degrades UX, conflicts with premium positioning. |
| Multiple subscription tiers | One clear value proposition. Tiered plans add complexity without proportional revenue. |
| In-app subscription cancellation | Apple/Google require cancellation through native settings. In-app cancellation risks rejection. |
| Cryptocurrency payments | Massive complexity, regulatory risk, tiny conversion benefit. |
| Custom receipt validation server | RevenueCat validates all receipts. Duplicates core value. |
| PayPal integration | RevenueCat + Stripe covers web payments. PayPal adds complexity without meaningful lift. |
| Stripe direct integration on mobile | Apple/Google require StoreKit/Play Billing. RevenueCat routes correctly. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SDK-01 | Phase 50 | Pending |
| SDK-02 | Phase 50 | Pending |
| SDK-03 | Phase 50 | Pending |
| SDK-04 | Phase 50 | Pending |
| SDK-05 | Phase 50 | Pending |
| SDK-06 | Phase 50 | Pending |
| SUB-01 | Phase 51 | Pending |
| SUB-02 | Phase 51 | Pending |
| SUB-03 | Phase 51 | Pending |
| SUB-04 | Phase 51 | Pending |
| SUB-05 | Phase 51 | Pending |
| SUB-06 | Phase 51 | Pending |
| SUB-07 | Phase 51 | Pending |
| SUB-08 | Phase 51 | Pending |
| SUB-09 | Phase 51 | Pending |
| SUB-10 | Phase 51 | Pending |
| PAY-01 | Phase 52 | Pending |
| PAY-02 | Phase 52 | Pending |
| PAY-03 | Phase 52 | Pending |
| PAY-04 | Phase 52 | Pending |
| PAY-05 | Phase 52 | Pending |
| PAY-06 | Phase 52 | Pending |
| PAY-07 | Phase 52 | Pending |
| PAY-08 | Phase 52 | Pending |
| PAY-09 | Phase 52 | Pending |
| GATE-01 | Phase 53 | Pending |
| GATE-02 | Phase 53 | Pending |
| GATE-03 | Phase 53 | Pending |
| GATE-04 | Phase 53 | Pending |
| GATE-05 | Phase 53 | Pending |
| GATE-06 | Phase 53 | Pending |
| GATE-07 | Phase 53 | Pending |
| GATE-08 | Phase 53 | Pending |
| GATE-09 | Phase 53 | Pending |
| SYNC-01 | Phase 54 | Pending |
| SYNC-02 | Phase 54 | Pending |
| SYNC-03 | Phase 54 | Pending |
| SYNC-04 | Phase 54 | Pending |
| ADM-01 | Phase 54 | Pending |
| ADM-02 | Phase 54 | Pending |
| ADM-03 | Phase 54 | Pending |

**Coverage:**
- v1 requirements: 37 total
- Mapped to phases: 37
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-14*
*Last updated: 2026-04-14 after initial definition*
