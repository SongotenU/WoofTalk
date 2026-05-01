# Android Platform Feature Gaps

## Current State

The WoofTalk Android app (compileSdk 35, minSdk 26, targetSdk 35) has the following platform features already implemented:

- **Splash Screen API** — `MainActivity.kt` uses `installSplashScreen()` via `androidx.core:core-splashscreen:1.0.1`.
- **Home Screen Widget** — `QuickTranslateWidget.kt` is a Glance-based app widget with a configuration activity (`WidgetConfigActivity`). Receiver registered in `AndroidManifest.xml`.
- **Background Audio Service** — `VoiceTranslationService.kt` is a foreground `Service` with a notification channel and binder interface for in-app use.
- **Offline Write Queue** — `OfflineWriteQueue.kt` + `SyncManager.kt` implement a Room-backed offline queue with network-aware sync, exponential backoff, and retry logic.
- **Wear OS Companion App** — `/android/WoofTalk/wear/` has a standalone Wear OS app (minSdk 30, targetSdk 34) with Compose for Wear OS, a splash screen, and Supabase integration.
- **Dynamic Color / Material You** — `Theme.kt` conditionally uses `dynamicLightColorScheme` / `dynamicDarkColorScheme` (available on Android 12+/API 31+), falling back to fixed color schemes.
- **Edge-to-Edge** — `MainActivity.kt` calls `enableEdgeToEdge()`.
- **Hilt DI** — Full Dagger Hilt setup with `@AndroidEntryPoint` on `MainActivity`.
- **Compose Material 3** — UI is built with `androidx.compose.material3`.

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact |
|---|---------|----------|--------|--------|
| 1 | **Push Notifications (FCM)** | High | Medium | High — offline sync alerts, translation ready, social notifications |
| 2 | **App Shortcuts (Static + Dynamic)** | Medium | Low | Medium — quick "Translate Dog" / "Translate Cat" actions from long-press |
| 3 | **Quick Settings Tile** | Medium | Low | Medium — one-tap toggle for translation listening from notification shade |
| 4 | **Lock Screen Widgets** | Medium | Low | Medium — Android 15+ lock screen widget support (new API) |
| 5 | **Foldable / Tablet Layouts** | Medium | Medium | Medium — no `sw600dp` or `windowSizeClass` aware layouts; 8 screens grep for but don't implement responsive layouts |
| 6 | **Android 15/16 New APIs** | Medium | Medium | Medium — `Notification.Style` updates, predictive back, Privacy Sandbox, Health Connect |
| 7 | **Google Assistant Integration** | Low | Medium | Medium — voice intent filters (`VOICE_COMMAND`), Assistant shortcuts |
| 8 | **Picture-in-Picture Mode** | Low | Low | Low — useful for translation overlay on other apps; needs `supportsPictureInPicture` + `onPictureInPictureModeChanged` |
| 9 | **Samsung Galaxy Integration** | Low | High | Low-Medium — Samsung-specific: Good Lock, Edge Panels, DeX desktop mode support |
| 10 | **Android Auto Support** | Low | High | Medium — `CarAppService` + `androidx.car.app` for in-car translation |
| 11 | **Wear OS Feature Gap** — The Wear app is minimal (single `TranslationScreen`, no offline queue sync, no RevenueCat, no Hilt, older Compose/BOM versions) | Medium | Medium | Medium — Wear app lags behind main app capabilities |
| 12 | **BroadcastReceiver for System Events** | Low | Low | Low — no `BroadcastReceiver` found for boot, connectivity changes, or locale changes |
| 13 | **WorkManager for Background Sync** | Low | Low | Medium — `SyncManager` uses a manual coroutine loop; `WorkManager` would be more battery-efficient and reliable across doze/restarts |
| 14 | **Adaptive Icon (Vector)** | Low | Low | Low — `mipmap-anydpi-v26` exists but no `res/mipmap-anydpi-v26/ic_launcher.xml` confirmed; no `adaptive-icon` XML verified |

## Recommendations

### 1. Add FCM Push Notifications (Highest Impact)
There is zero FCM integration — no `FirebaseMessagingService`, no `com.google.firebase:firebase-messaging` dependency in `build.gradle.kts`. Adding FCM would enable real-time social notifications (community phrase approvals, friend translations), offline-sync-complete alerts, and subscription/renewal reminders. Estimated effort: 2-3 days including backend webhook setup in Supabase.

### 2. Implement App Shortcuts + Quick Settings Tile (Quick Wins)
- **App Shortcuts**: Add `<meta-data android:name="android.app.shortcuts" ... />` to `AndroidManifest.xml` with static shortcuts for "Translate to Dog" and "Translate to Cat". Add dynamic shortcuts for recently translated languages. Estimated effort: 0.5 day.
- **Quick Settings Tile**: Create a `TileService` subclass that launches the translation screen or toggles the `VoiceTranslationService`. Estimated effort: 0.5 day.

### 3. Add Foldable/Tablet Responsive Layouts
The codebase has 8 screen files that reference but do not implement responsive layouts. Add `windowSizeClass` support (already in `androidx.compose.material3` BOM) to `WoofTalkApp()` composable to switch between phone, tablet, and foldable layouts. Create `res/layout-sw600dp/` and `res/layout-sw840dp/` variants. Estimated effort: 2-3 days.
