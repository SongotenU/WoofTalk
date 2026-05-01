# Combined Code Review Report - WoofTalk
**Date**: 2026-04-30
**Scope**: Full codebase (iOS, Android, Web, Supabase)
**Depth**: standard
**Phase**: all (116 files)

---

## Executive Summary

Total findings: **48 issues**
- BLOCKER/CRITICAL: **19** (must fix before shipping)
- HIGH: **8**
- MEDIUM/WARNING: **15**
- LOW/INFO: **6**

The codebase has serious security vulnerabilities (service role key exposed in iOS client, missing auth on multiple API routes and edge functions) and functional bugs (TODO() crashes in Android navigation, broken invite flow on web, Race conditions in Supabase). Immediate action required on blockers.

---

## Blocking Issues (Fix Before Ship)

### Security

| # | Platform | File | Issue |
|---|----------|------|-------|
| 1 | iOS | `ErrorTrackingService.swift:27` | **Service role key exposed in client code** — can be extracted from app binary |
| 2 | Web | `api/org/invite/route.ts` | **No auth on org invite route** — any unauthenticated user can create invites |
| 3 | Web | `api/org/teams/[id]/route.ts` | **No auth on team DELETE** — any user can delete any team |
| 4 | Web | `api/admin/errors/route.ts` | **No auth on error logging endpoint** — anyone can POST arbitrary data |
| 5 | Supabase | `migrations/0013_admin_analytics_features.sql` | **No RLS on `ab_experiments`** — any user can manipulate A/B tests |
| 6 | Supabase | `functions/ab-assign/index.ts` | **No webhook signature verification** — RevenueCat webhooks can be forged |
| 7 | Supabase | `functions/collect-error/index.ts` | **No auth on edge function** — sensitive operation exposed |
| 8 | Supabase | `functions/push-campaign-send/index.ts` | **No auth on push campaign function** — anyone can trigger mass push |
| 9 | Supabase | `functions/error-collector/index.ts` | **No auth on error collector** — duplicate function, no auth |

### Bugs

| # | Platform | File | Issue |
|---|----------|------|-------|
| 10 | iOS | `TranslationFeedbackManager.swift:24` | **Core Data viewContext on background thread** — crashes/data corruption |
| 11 | iOS | `CancellationSurveyView.swift:80` | **`Purchases.shared.cancel()` doesn't exist** — will crash at runtime |
| 12 | iOS | `WatchKitExtension/Interface.storyboard` | **Duplicate element IDs** — invalid XML, will fail to load |
| 13 | Android | `AppNavigation.kt:35,42` | **`TODO()` in production navigation** — crashes when user navigates |
| 14 | Android | `FirebaseMessagingService.kt:92-95` | **`sendTokenToServer()` is empty** — FCM tokens never registered |
| 15 | Web | `invite/accept/page.tsx:48-57` | **Invite not linked to accepting user** — broken org membership |
| 16 | Web | `lib/revenuecat.ts:19` | **Wrong API usage** — `Purchases.generateRevenueCatAnonymousAppUserId()` is not a static method |
| 17 | Supabase | `functions/ab-assign/index.ts` | **Race condition in A/B assignment** — concurrent requests cause duplicate assignments |
| 18 | Supabase | `migrations/0014_subscription_enhancements.sql` | **Broken churn calculation** — wrong SQL logic |
| 19 | Supabase | `migrations/0016_subscription_snapshots.sql` | **CHECK constraint never applied** — `CREATE TABLE IF NOT EXISTS` is no-op |

---

## High-Priority Issues

| # | Platform | File | Issue |
|---|----------|------|-------|
| 20 | iOS | `CancellationSurveyView.swift:73-86` | State modified from background thread |
| 21 | iOS | `BarkDetector.swift:37-41` | Incorrect "dominant frequency" algorithm |
| 22 | iOS | `DogEmotionDetector.swift:68-93` | Autocorrelation returns invalid frequency |
| 23 | iOS | `MessagingView.swift:50-53` | Core Data predicate with potentially nil UUID |
| 24 | Android | `AppNavigation.kt:25-27` | Empty composable blocks for Translate/History/Settings |
| 25 | Android | `RevenueCatModule.kt` | SDK configured but never initialized (`Purchases.configure()` never called) |
| 26 | Android | `FirebaseMessagingService.kt:75` | `currentTimeMillis().toInt()` causes notification ID collisions |
| 27 | Web | `hooks/useEntitlementSync.ts:19-41` | Real-time subscription not scoped to current user |
| 28 | Web | `settings/cancel/page.tsx:49-59` | Cancellation doesn't reach payment provider — users still charged |
| 29 | Web | `auth/signin/page.tsx:17-20` | Premium users redirected to subscribe page instead of translate |
| 30 | Web | `lib/entitlement-store.ts:54-56` | Entitlement store not reset on sign out |

---

## Medium-Priority Issues

| # | Platform | File | Issue |
|---|----------|------|-------|
| 31 | iOS | `COPPAAgeVerificationView.swift:63-66,102-104` | COPPA consent is stub — prints only, doesn't send email |
| 32 | iOS | `DogProfileView.swift:70-75` | Misleading variable name/comment (copy-paste error) |
| 33 | iOS | `Widgets/WoofTalkWidget.swift:22-26` | Widget timeline with past dates causes frequent reloads |
| 34 | iOS | `WatchHistoryInterfaceController.swift:34` | Re-translates instead of using stored translation |
| 35 | Android | `CancellationSurveyScreen.kt:20` | Unused `entitlementManager` parameter |
| 36 | Android | `ReferralScreen.kt:20,34-39` | Unused param + referral code hardcoded to `"COMING_SOON"` |
| 37 | Android | `TranslationTileService.kt:10,24` | `isListening` state can desynchronize |
| 38 | Android | `TranslationTileService.kt:51` | Standalone `icon` expression is no-op |
| 39 | Android | `shortcuts.xml:55` | History shortcut uses microphone icon instead of history icon |
| 40 | Web | `components/ThemeInitializer.tsx:10-16` | Duplicate high contrast check in two effects |
| 41 | Web | `admin/ab/page.tsx:31-43` | No user feedback on fetch errors |
| 42 | Web | `settings/page.tsx:17` | Unused `isAuthenticated` variable |
| 43 | Supabase | `functions/mrr-calculator/index.ts` | Incorrect churn calculation + NaN in math |
| 44 | Supabase | `functions/push-campaign-send/index.ts` | Campaign status stuck on error |
| 45 | Supabase | `functions/` | Duplicate error collector functions (`collect-error` + `error-collector`) |

---

## Low-Priority / Info

| # | Platform | File | Issue |
|---|----------|------|-------|
| 46 | iOS | `ErrorTrackingService.swift:42-44` | Silent JSON serialization failures |
| 47 | iOS | `FeatureFlagManager.swift:24` | Defaults to empty user ID |
| 48 | iOS | `TranslationViewController.swift:77` | WCSession used without activation check |
| 49 | Android | `FirebaseMessagingService.kt:55,58` | `setSound()` overridden by `setDefaults(DEFAULT_ALL)` |
| 50 | Android | `FirebaseMessagingService.kt:62-73` | Notification channel recreated on every notification |
| 51 | Web | `public/sw.js:1` | Compiled service worker code smell (build artifact) |
| 52 | Supabase | `functions/win-back-campaign/index.ts` | MagicLink abuse — no rate limiting |
| 53 | Supabase | `migrations/0015_error_logs.sql` | Seed data in migration |
| 54 | Supabase | `migrations/0015,0016` | Redundant migrations |

---

## Per-Platform Detailed Reports

- **iOS**: 4 CRITICAL, 4 HIGH, 4 MEDIUM, 3 LOW → `.planning/reviews/REVIEW-ios.md`
- **Android**: 2 BLOCKER, 11 WARNING → `.planning/reviews/REVIEW-android.md`
- **Web**: 5 CRITICAL, 4 HIGH, 3 MEDIUM, 1 LOW → `.planning/reviews/REVIEW-web.md`
- **Supabase**: 8 BLOCKER, 12 WARNING → `.planning/reviews/REVIEW-supabase.md`

---

## Recommended Action Plan

### Before Shipping (Must Fix)
1. **Remove service role key from iOS client** (`ErrorTrackingService.swift`)
2. **Add auth checks** to all unauthenticated web API routes (`/api/org/invite`, `/api/org/teams/[id]`, `/api/admin/errors`)
3. **Enable RLS + policies** on `ab_experiments` table
4. **Add webhook signature verification** to `ab-assign` edge function
5. **Replace `TODO()`** in Android `AppNavigation.kt` with real `EntitlementManager`
6. **Fix broken invite acceptance flow** on web — link to accepting user's ID
7. **Fix RevenueCat SDK usage** on web (`generateRevenueCatAnonymousAppUserId` import)
8. **Fix iOS Core Data threading** (`TranslationFeedbackManager.swift`)
9. **Remove `Purchases.shared.cancel()`** from iOS — guide user to App Store instead
10. **Fix Supabase race condition** in A/B assignment + broken migrations

### Before Launch (Should Fix)
- Initialize RevenueCat SDK on Android
- Scope real-time entitlement sync to current user
- Fix subscription cancellation to reach payment provider
- Fix premium user redirect logic on sign-in
- Reset entitlement store on sign out
- Fix iOS audio processing algorithms (bark detector, emotion detector)
- Fix iOS storyboard invalid XML

### Backlog (Nice to Have)
- COPPA consent implementation (currently stubs)
- Widget timeline optimization
- Error feedback on admin pages
- FCM notification improvements
- Push campaign batch sending
