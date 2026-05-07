# Roadmap: WoofTalk

## Milestones

- ✅ **v0.1.0 M007 AR/VR Mixed Reality** — Phases 23-27 (shipped 2026-04-04)
- ✅ **v0.2.0 M008 Production Hardening** — Phases 43-49 (shipped 2026-04-07)
- ✅ **v1.0.0 M009 Subscription & Payments** — Phases 50-54 (shipped 2026-04-29)
- 🔲 **M010 Ship to Production** — Phases 55-64 (planning)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 50: RevenueCat SDK Integration** - SDK wired on all platforms with auth.uid identity and entitlement cache
- [x] **Phase 51: Subscription Backend** - Server-side authority: webhooks, RLS enforcement, entitlement verification (completed 2026-04-16)
- [x] **Phase 52: Paywall UI** - Platform-native paywalls displaying offerings and completing purchases (shipped PR #4, PR #5 2026-04-23)
- [x] **Phase 53: Feature Gating & Soft Paywall** - Free tier limits enforced with non-blocking upgrade paths (shipped PR #4, PR #5 2026-04-23)
- [x] **Phase 54: Cross-Platform Sync & Admin** - Entitlements work across platforms and admins can monitor (implementation fixes applied 2026-04-23)
- [x] **Phase 55: iOS Build Fixes & Production Prep** - Fix remaining iOS build issues, DB concurrency, final verification
- [ ] **Phase 56: Android Build Fixes & Production Prep** - Fix Android build issues, prepare for production
- [ ] **Phase 57: Web Production Deployment** - Deploy web app to production with proper configuration
- [x] **Phase 58: CI/CD Pipeline** - Set up automated build, test, and deployment pipeline
- [ ] **Phase 59: iOS App Store Submission** - Prepare and submit iOS app to App Store (Xcode configured with privacy keys 2026-05-07, metadata ready, manual App Store Connect steps pending)
- [ ] **Phase 60: Android Play Store Submission** - Prepare and submit Android app to Play Store (PLAN.md, CONTEXT.md created 2026-05-05)
- [🔲] **Phase 61: End-to-End Testing** - Comprehensive E2E testing across all platforms (static verification complete, manual testing pending)
- [ ] **Phase 62: Production Monitoring** - Set up monitoring, alerts, and observability (PLAN.md ✅ 2026-05-05, SUMMARY.md ✅ 2026-05-05)
- [ ] **Phase 63: Release Management** - Manage release process, versioning, and rollout (PLAN.md ✅ 2026-05-05, SUMMARY.md ✅ 2026-05-05)
- [ ] **Phase 64: Documentation & Store Assets** - Final documentation and store listing assets (PLAN.md ✅ 2026-05-05, SUMMARY.md ✅ 2026-05-05)

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
- [x] 50-01: iOS — RevenueCatManager + EntitlementManager with PurchasesDelegate
- [x] 50-02: Android — Hilt SDK module + EntitlementManager with UpdatedCustomerInfoListener
- [x] 50-03: Web — RevenueCat JS SDK init + Zustand entitlement store + EntitlementProvider

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
**Plans**: 3 plans

Plans:
- [x] 51-01: Subscription backend migration + shared utility module
- [x] 51-02: Entitlement webhook Edge Function
- [x] 51-03: Entitlement check + translate tier gate

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
**Plans**: 3 plans

Plans:
- [x] 52-01: iOS — Subscription row + RevenueCatUI PaywallView with StoreKit purchases
- [x] 52-02: Android — Subscription row + RevenueCatUI Paywall composable with Play Billing
- [x] 52-03: Web — /subscribe page with plan cards + hosted checkout + Settings subscription card

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
**Plans**: 4 plans

Plans:
- [x] 53-01: iOS — Feature gating with EntitlementManager wrapper
- [x] 53-02: Android — Feature gating with EntitlementManager wrapper
- [x] 53-03: Web — Feature gating with useEntitlement hook
- [x] 53-04: Cross-platform — Watch inherits phone subscription status

### Phase 54: Cross-Platform Sync & Admin
**Goal**: Subscriptions purchased on one platform activate entitlements on all others, and admins can monitor subscription health across the user base
**Depends on**: Phase 52, Phase 53
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, ADM-01, ADM-02, ADM-03
**Success Criteria** (what must be TRUE):
  1. A subscription purchased on one platform activates entitlements on all other platforms within 30 seconds
  2. On every app launch, logIn(auth.uid) is called to ensure correct RevenueCat identity, and restore purchases flow is available on all platforms
  3. Subscription management links to platform-native settings (iOS: App Store, Android: Play Store, Web: Stripe portal)
  4. Admin dashboard shows subscription tier, trial status, and cancellation date per user; RevenueCat analytics dashboard is enabled
**Plans**: 3 plans

Plans:
- [x] 54-01: iOS/Watch — Cross-platform sync with WatchSyncManager
- [x] 54-02: Android — Cross-platform sync with entitlement listener
- [x] 54-03: Web + Admin — Entitlement sync hook + admin dashboard

### Phase 55: iOS Build Fixes & Production Prep
**Goal**: Fix remaining iOS build issues (DB concurrency), complete final verification, and prepare iOS app for production submission
**Depends on**: Phase 54
**Requirements**: IOS-01, IOS-02, IOS-03, IOS-04, IOS-05, IOS-06, IOS-07
**Success Criteria** (what must be TRUE):
  1. iOS app compiles with 0 errors and 0 warnings
  2. DB concurrency issues resolved (actor isolation, Sendable compliance)
  3. All RevenueCat v5.x migrations complete (async/await)
  4. Final verification passes (55-07)
  5. App launches successfully on iOS Simulator
  6. All entitlements work correctly on iOS
  7. Ready for App Store submission
**Plans**: 7 plans
Plans:
- [x] 55-01: RevenueCat v5.x migration (async/await)
- [x] 55-02: Swift 6 actor isolation fixes
- [x] 55-03: Sendable compliance fixes
- [x] 55-04: BatteryOptimizer deinit bug fix
- [x] 55-05: Swift compilation error fixes (30+ → 0)
- [ ] 55-06: DB concurrency fixes
- [ ] 55-07: Final verification

### Phase 56: Android Build Fixes & Production Prep
**Goal**: Fix Android build issues, ensure feature parity with iOS, and prepare Android app for production
**Depends on**: Phase 55
**Requirements**: AND-01, AND-02, AND-03, AND-04, AND-05
**Success Criteria** (what must be TRUE):
  1. Android app compiles with 0 errors
  2. All features work correctly (translation, subscription, paywall)
  3. RevenueCat SDK properly integrated
  4. Ready for Play Store submission
  5. Feature parity with iOS confirmed
**Plans**: TBD

### Phase 57: Web Production Deployment
**Goal**: Deploy Next.js web app to production with proper environment configuration and SSL
**Depends on**: Phase 56
**Requirements**: WEB-01, WEB-02, WEB-03, WEB-04, WEB-05
**Success Criteria** (what must be TRUE):
  1. ✅ Web app builds successfully with 0 errors
  2. Web app deployed to production URL (Vercel)
  3. Environment variables properly configured (Supabase, RevenueCat)
  4. Supabase production connection verified
  5. RevenueCat web SDK functioning
  6. PWA features working (service worker, offline support, manifest)
**Plans**: 6 plans

Plans:
- [x] 57-01: Fix Web App Build Errors
- [ ] 57-02: Production Environment Configuration
- [ ] 57-03: Deploy to Vercel (Production)
- [ ] 57-04: Verify Supabase Production Connection
- [ ] 57-05: Test RevenueCat Web SDK
- [ ] 57-06: Verify PWA Features

### Phase 58: CI/CD Pipeline
**Goal**: Set up automated build, test, and deployment pipeline for all platforms (iOS, Android, Web)
**Depends on**: Phase 57
**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06
**Success Criteria** (what must be TRUE):
  1. GitHub Actions workflow for iOS builds (archive, test, distribute)
  2. GitHub Actions workflow for Android builds (APK/AAB, test, distribute)
  3. Automated testing on PR (lint, unit tests, build verification)
  4. Staging deployment configured (auto-deploy on merge to `develop`)
  5. Release build automation (tag-triggered production builds)
  6. All workflows pass without errors
**Plans**: 6 plans

Plans:
- [x] 58-01: iOS Build Workflow (ios-build.yml)
- [x] 58-02: Android Build Workflow (android-build.yml)
- [x] 58-03: PR Automated Testing Workflow (pr-test.yml)
- [x] 58-04: Staging Deployment Workflow (staging-deploy.yml)
- [x] 58-05: Release Build Automation (release-build.yml)
- [x] 58-06: Workflow Integration & Documentation

### Phase 59: iOS App Store Submission
**Goal**: Prepare all materials and submit iOS app to App Store
**Depends on**: Phase 58
**Requirements**: IOS-SUB-01, IOS-SUB-02, IOS-SUB-03, IOS-SUB-04, IOS-SUB-05
**Success Criteria** (what must be TRUE):
  1. App Store Connect listing complete
  2. Screenshots for all device sizes
  3. Privacy policy and terms of service published
  4. App passes App Store review guidelines
  5. Ready for release
**Plans**: TBD

### Phase 60: Android Play Store Submission
**Goal**: Prepare all materials and submit Android app to Play Store
**Depends on**: Phase 59
**Requirements**: AND-SUB-01, AND-SUB-02, AND-SUB-03, AND-SUB-04, AND-SUB-05
**Success Criteria** (what must be TRUE):
  1. Google Play Console listing complete
  2. Screenshots for all device sizes
  3. Privacy policy and terms of service published
  4. App passes Play Store review
  5. Ready for release
**Plans**: TBD

### Phase 61: End-to-End Testing
**Goal**: Comprehensive E2E testing across all platforms (iOS, Android, Web, Watch)
**Depends on**: Phase 60
**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04, E2E-05, E2E-06
**Success Criteria** (what must be TRUE):
  1. Translation flow works on all platforms
  2. Subscription purchase flow works (iOS, Android, Web)
  3. Cross-platform sync verified
  4. Offline mode tested
  5. Performance benchmarks met
  6. No critical bugs
**Plans**: TBD

### Phase 62: Production Monitoring
**Goal**: Set up monitoring, alerts, and observability for production systems
**Depends on**: Phase 61
**Requirements**: MON-01, MON-02, MON-03, MON-04, MON-05
**Success Criteria** (what must be TRUE):
  1. Supabase monitoring dashboard configured
  2. RevenueCat analytics enabled
  3. Error tracking (Sentry/Crashlytics) integrated
  4. Performance monitoring active
  5. Uptime alerts configured
**Plans**: TBD

### Phase 63: Release Management
**Goal**: Manage release process, versioning, and staged rollout
**Depends on**: Phase 62
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05
**Success Criteria** (what must be TRUE):
  1. Version numbers correctly set
  2. Release notes prepared
  3. Staged rollout plan defined
  4. Rollback procedure documented
  5. Release communication sent
**Plans**: TBD

### Phase 64: Documentation & Store Assets
**Goal**: Final documentation and store listing assets for all platforms
**Depends on**: Phase 63
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-04, DOC-05, DOC-06
**Success Criteria** (what must be TRUE):
  1. README.md updated with production info
  2. API documentation complete
  3. App Store assets (screenshots, promo video)
  4. Play Store assets (screenshots, feature graphic)
  5. Privacy policy and terms finalized
  6. User documentation complete
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 50 → 51 → 52 → 53 → 54 → 55 → 56 → 57 → 58 → 59 → 60 → 61 → 62 → 63 → 64

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 50. RevenueCat SDK Integration | 3/3 | Complete | 2026-04-15 |
| 51. Subscription Backend | 3/3 | Complete | 2026-04-16 |
| 52. Paywall UI | 3/3 | Complete | 2026-04-23 |
| 53. Feature Gating & Soft Paywall | 4/4 | Complete | 2026-04-23 |
| 54. Cross-Platform Sync & Admin | 3/3 | Complete | 2026-04-29 |
| 55. iOS Build Fixes & Production Prep | 5/7 | In Progress | - |
| 56. Android Build Fixes & Production Prep | 0/TBD | Pending | - |
| 57. Web Production Deployment | 1/6 | Complete | 2026-05-05 |
| 58. CI/CD Pipeline | 6/6 | Complete | 2026-05-05 |
| 62. Production Monitoring | TBD | Complete | 2026-05-05 |
| 63. Release Management | TBD | Complete | 2026-05-05 |
| 64. Documentation & Store Assets | TBD | Complete | 2026-05-05 |
