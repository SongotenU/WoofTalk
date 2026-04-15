# Roadmap: WoofTalk

## Milestones

- ✅ **v0.1.0 M007 AR/VR Mixed Reality** — Phases 23-27 (shipped 2026-04-04)
- ✅ **v0.2.0 M008 Production Hardening** — Phases 43-49 (shipped 2026-04-07)
- 🚧 **v1.0.0 M009 Subscription & Payments** — Phases 50-54 (in progress)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 50: RevenueCat SDK Integration** - SDK wired on all platforms with auth.uid identity and entitlement cache
- [ ] **Phase 51: Subscription Backend** - Server-side authority: webhooks, RLS enforcement, entitlement verification
- [ ] **Phase 52: Paywall UI** - Platform-native paywalls displaying offerings and completing purchases
- [ ] **Phase 53: Feature Gating & Soft Paywall** - Free tier limits enforced with non-blocking upgrade paths
- [ ] **Phase 54: Cross-Platform Sync & Admin** - Entitlements work across platforms and admins can monitor

## Phase Details

### Phase 50: RevenueCat SDK Integration
**Goal**: RevenueCat SDK is initialized and functional on all platforms, users are identified by Supabase auth.uid, and entitlements are readable and react to changes
**Depends on**: Nothing (first phase of M009)
**Requirements**: SDK-01, SDK-02, SDK-03, SDK-04, SDK-05, SDK-06
**Success Criteria** (what must be TRUE):
  1. iOS app initializes RevenueCat SDK with Supabase auth.uid as appUserID
  2. Android app initializes RevenueCat SDK with Supabase auth.uid as appUserID
  3. Web app initializes RevenueCat JS SDK with Supabase auth.uid as appUserID
  4. PurchasesDelegate/listener fires on CustomerInfo updates across all platforms
  5. After any purchase, getCustomerInfo() is called immediately and entitlement cache refreshes before proceeding
  6. Unauthenticated users cannot reach the paywall — login is required first
**Plans**: 3 plans

Plans:
- [ ] 50-01: iOS — RevenueCatManager + EntitlementManager with PurchasesDelegate
- [ ] 50-02: Android — Hilt SDK module + EntitlementManager with UpdatedCustomerInfoListener
- [ ] 50-03: Web — RevenueCat JS SDK init + Zustand entitlement store + EntitlementProvider

### Phase 51: Subscription Backend
**Goal**: Server-side subscription authority is established — webhooks update status, RLS enforces free tier limits, and Edge Functions verify entitlement before processing premium requests
**Depends on**: Phase 50
**Requirements**: SUB-01, SUB-02, SUB-03, SUB-04, SUB-05, SUB-06, SUB-07, SUB-08, SUB-09, SUB-10
**Success Criteria** (what must be TRUE):
  1. subscription_status table stores user entitlement state and is queryable by user_id, with revenuecat_id linked in user_profiles
  2. RevenueCat webhook events (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, TRIAL_STARTED) update subscription_status in real time with idempotent handling
  3. Edge Functions verify subscription server-side via RevenueCat REST API with 5-minute result caching
  4. Free users cannot INSERT more than 3 translation_requests per day — RLS enforces this as a hard gate regardless of client behavior
  5. Edge Functions reject premium requests from free-tier users before processing
**Plans**: TBD

Plans:
- [ ] 51-01: [TBD]

### Phase 52: Paywall UI
**Goal**: Users can view subscription offerings, complete a purchase through the native payment flow, and see their entitlement confirmed — on all three platforms
**Depends on**: Phase 50, Phase 51
**Requirements**: PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, PAY-06, PAY-07, PAY-08, PAY-09
**Success Criteria** (what must be TRUE):
  1. iOS paywall displays monthly ($4.99/mo) and annual ($39.99/yr) offerings with StoreKit-only purchases — no external payment links
  2. Android paywall displays the same offerings with Play Billing purchases
  3. Web paywall displays the same offerings using RevenueCat hosted checkout via Stripe
  4. Annual plan shows "Save 33%" badge, and iOS paywall is fully compliant with App Store Guideline 3.1.1 (no "cheaper on web" text)
  5. Purchase flow shows loading state until entitlement is confirmed, and restore purchases button is available on all paywalls
  6. Products are verified via getOfferings() before the paywall is displayed — no stale or missing offerings shown
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 52-01: [TBD]

### Phase 53: Feature Gating & Soft Paywall
**Goal**: Free users experience clear limits (3 translations/day, last 10 history, locked premium features) with non-blocking upgrade paths; premium users have unrestricted access
**Depends on**: Phase 51, Phase 52
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04, GATE-05, GATE-06, GATE-07, GATE-08, GATE-09
**Success Criteria** (what must be TRUE):
  1. Free users are limited to 3 translations per day (server-enforced) and can only see last 10 history items; premium users have unlimited history
  2. AI translation, community phrase contribution, and export/share are restricted to premium users — free users see upgrade prompts when attempting these features
  3. EntitlementManager wrapper provides isPremium, isTrialActive, and dailyTranslationsUsed on all platforms
  4. After the 3rd translation, free users see a non-blocking upgrade prompt linking to paywall; premium features display lock icons when user is on free tier
  5. Watch app inherits phone subscription status with no separate purchase required
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 53-01: [TBD]

### Phase 54: Cross-Platform Sync & Admin
**Goal**: Subscriptions purchased on one platform activate entitlements on all others, and admins can monitor subscription health across the user base
**Depends on**: Phase 52, Phase 53
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, ADM-01, ADM-02, ADM-03
**Success Criteria** (what must be TRUE):
  1. A subscription purchased on one platform activates entitlements on all other platforms within 30 seconds
  2. On every app launch, logIn(auth.uid) is called to ensure correct RevenueCat identity, and restore purchases flow is available on all platforms
  3. Subscription management links to platform-native settings (iOS: App Store, Android: Play Store, Web: Stripe portal)
  4. Admin dashboard shows subscription tier, trial status, and cancellation date per user; RevenueCat analytics dashboard is enabled
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 54-01: [TBD]

## Progress

**Execution Order:**
Phases execute in numeric order: 50 → 51 → 52 → 53 → 54

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 50. RevenueCat SDK Integration | 0/3 | Planned | - |
| 51. Subscription Backend | 0/? | Not started | - |
| 52. Paywall UI | 0/? | Not started | - |
| 53. Feature Gating & Soft Paywall | 0/? | Not started | - |
| 54. Cross-Platform Sync & Admin | 0/? | Not started | - |
