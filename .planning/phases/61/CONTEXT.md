# Phase 61: End-to-End Testing - Context

**Gathered:** 2026-05-05
**Status:** Ready for execution

<domain>
## Phase Boundary

This phase conducts comprehensive end-to-end testing across all platforms (iOS, Android, Web, Watch) to verify production readiness. Tests cover translation flow, subscription purchase, cross-platform sync, offline mode, and performance. Testing requires deployed apps on test environments (TestFlight, Internal Testing, staging). All critical bugs must be documented and resolved before production release.

**Prerequisites:** Phase 60 (Android Play Store Submission) complete, test environments provisioned.

</domain>

<decisions>

## Implementation Decisions

### Testing Strategy
- Manual testing with structured test cases (automated E2E not in scope)
- Test matrix covers: iOS Simulator + physical device, Android emulator + physical device, Web browsers (Chrome, Safari, Firefox)
- RevenueCat sandbox/test mode for subscription testing
- Supabase staging project for backend testing

### Platform Coverage
- iOS: SwiftUI app with StoreKit testing
- Android: Kotlin app with Play Billing test
- Web: Next.js PWA with Stripe test mode
- Watch: Wear OS app (inherits iPhone subscription)

### Success Criteria
- Translation flow works on all platforms (<2s response time)
- Subscription purchase works (monthly, annual, trial)
- Cross-platform sync verified (entitlements sync within 30 seconds)
- Offline mode tested (queue translations, sync when online)
- Performance benchmarks met (launch <3s, no memory leaks)
- Zero critical/high-priority bugs

</decisions>

<code_context>

## Existing Code Insights

### Test Infrastructure
- `web/package.json` — TypeScript compilation check (`npm run build`)
- `Tests/` directory — Existing unit tests (50+ Android tests)
- `WoofTalkTests/` — iOS unit tests
- `WoofTalkUITests/` — iOS UI tests
- `.github/workflows/` — GitHub Actions uptime monitor (every 5 min)
- `scripts/load-tests/` — k6 load testing scripts

### Translation Flow
- `ios/WoofTalk/TranslationView.swift` — iOS translation UI
- `android/WoofTalk/app/src/main/java/com/wooftalk/ui/` — Android translation UI
- `web/src/components/TranslationPanel.tsx` — Web translation UI
- All use Supabase Edge Function `/translate` with entitlement check

### Subscription Flow
- RevenueCat SDK integrated on all platforms (v5.x iOS, v6.x Android, v8.x Web)
- `ios/WoofTalk/EntitlementManager.swift` — iOS subscription management
- `android/WoofTalk/app/src/main/java/com/wooftalk/billing/` — Android billing
- `web/src/hooks/useRevenueCat.ts` — Web subscription hook

### Cross-Platform Sync
- Supabase realtime subscriptions for entitlement changes
- `supabase/functions/revenuecat-webhook/index.ts` — Webhook handler
- Sync verified via `isPremium` entitlement across platforms

</code_context>

<specifics>

## Specific Ideas

### Test Cases to Create
1. **Translation Flow (E2E-01)**
   - Text input translation (all supported languages)
   - Voice input translation
   - Community phrase browsing/contribution
   - Translation history (free: last 10, premium: unlimited)
   - Share/export functionality (premium only)

2. **Subscription Purchase (E2E-02)**
   - Monthly subscription purchase (sandbox)
   - Annual subscription purchase (sandbox)
   - Trial activation
   - Restore purchases
   - Subscription management (cancel, renew)

3. **Cross-Platform Sync (E2E-03)**
   - Purchase on iOS → verify active on Android, Web, Watch
   - Purchase on Android → verify active on iOS, Web, Watch
   - Purchase on Web → verify active on iOS, Android, Watch
   - Entitlement changes propagate within 30 seconds

4. **Offline Mode (E2E-04)**
   - Offline translation queue (iOS, Android, Watch)
   - Sync when back online
   - Offline limitations (premium features locked without validation)
   - Offline history access

5. **Performance (E2E-05)**
   - Translation response time (<2s target)
   - App launch time (<3s target)
   - Memory usage (no leaks over 30 min)
   - CPU usage during translation
   - Large translation history (1000+ entries)

</specifics>

<deferred>

## Deferred Ideas

- Automated E2E testing with Detox/Appium (Phase 70+)
- Load testing with 1000+ concurrent users (Phase 70+)
- Chaos engineering for resilience testing (Phase 70+)
- A/B testing infrastructure (Phase 70+)

</deferred>
