---
phase: 50
slug: revenuecat-sdk-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Multi-platform: XCUITest (iOS), Instrumented tests (Android), Jest (Web) |
| **Config file** | iOS: xcodeproj scheme; Android: build.gradle.kts; Web: jest.config.ts |
| **Quick run command** | Platform-specific (see below) |
| **Full suite command** | Platform-specific (see below) |
| **Estimated runtime** | ~30 seconds (unit), ~120 seconds (full suite) |

**Quick commands:**
- iOS: `xcodebuild test -scheme WoofTalk -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WoofTalkTests/EntitlementManagerTests`
- Android: `./gradlew :app:testDebugUnitTest --tests "*.EntitlementManagerTest"`
- Web: `cd Web && npx jest --testPathPattern=entitlement --passWithNoTests`

---

## Sampling Rate

- **After every task commit:** Run platform-specific quick command
- **After every plan wave:** Run full suite on all platforms
- **Before `/gsd-verify-work`:** Full suite must be green on all platforms
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | SDK-01 | T-50-01 | SDK init with auth.uid, no anonymous | unit | `xcodebuild test -only-testing:WoofTalkTests/RevenueCatInitTests` | ❌ W0 | ⬜ pending |
| 50-01-02 | 01 | 1 | SDK-04 | T-50-01 | Delegate fires on CustomerInfo update | unit | `xcodebuild test -only-testing:WoofTalkTests/EntitlementManagerTests` | ❌ W0 | ⬜ pending |
| 50-02-01 | 02 | 1 | SDK-02 | T-50-02 | SDK init with auth.uid, no anonymous | unit | `./gradlew :app:testDebugUnitTest --tests "*.RevenueCatInitTest"` | ❌ W0 | ⬜ pending |
| 50-02-02 | 02 | 1 | SDK-04 | T-50-02 | Listener fires on CustomerInfo update | unit | `./gradlew :app:testDebugUnitTest --tests "*.EntitlementManagerTest"` | ❌ W0 | ⬜ pending |
| 50-03-01 | 03 | 1 | SDK-03 | T-50-03 | SDK init with auth.uid, no anonymous | unit | `cd Web && npx jest --testPathPattern=revenuecat` | ❌ W0 | ⬜ pending |
| 50-03-02 | 03 | 1 | SDK-04 | T-50-03 | Listener fires on CustomerInfo update | unit | `cd Web && npx jest --testPathPattern=entitlement-store` | ❌ W0 | ⬜ pending |
| 50-04-01 | 04 | 2 | SDK-05 | — | getCustomerInfo() called after purchase | unit | Platform-specific post-purchase tests | ❌ W0 | ⬜ pending |
| 50-04-02 | 04 | 2 | SDK-06 | T-50-04 | Paywall blocked for unauthenticated users | unit | Auth guard tests per platform | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `iOS/WoofTalkTests/EntitlementManagerTests.swift` — stubs for SDK-01, SDK-04
- [ ] `Android/WoofTalk/app/src/test/.../EntitlementManagerTest.kt` — stubs for SDK-02, SDK-04
- [ ] `Web/src/__tests__/entitlement-store.test.ts` — stubs for SDK-03, SDK-04
- [ ] RevenueCat SDK packages installed on all platforms

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| SDK init with real API key | SDK-01, SDK-02, SDK-03 | Requires RevenueCat sandbox credentials | Run app on each platform, verify RevenueCat customer created in dashboard |
| logIn(auth.uid) links identity | SDK-01, SDK-02, SDK-03 | Requires real auth + RevenueCat | Sign in on each platform, verify customer ID matches auth.uid in RevenueCat dashboard |
| Cross-platform identity | SDK-01/02/03 | Requires multi-device testing | Sign in on iOS, then Android, verify same RevenueCat customer |
| Offline entitlement | D-05 | Requires network toggle | Enable airplane mode, verify cached entitlement respected |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
