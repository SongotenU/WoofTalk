# iOS Platform Feature Gaps

## Current State

WoofTalk on iOS is a SwiftUI app (WoofTalkApp.swift) with three tabs: Translate, Community, and Offline. The app has:

**Build config:** iOS deployment target 26.2, Swift 5.0, targets iPhone+iPad (family "1,2"), bundle ID `vandopha.WoofTalk`. Uses generated Info.plist (`GENERATE_INFOPLIST_FILE = YES`), no custom `Info.plist` file on disk.

**Existing iOS capabilities:**
- Audio processing via AVAudioEngine (capture, playback, speech recognition) in `/WoofTalk/AudioProcessing/`
- Supabase backend with local CoreData cache and offline write queue (SyncManager in DataSource.swift)
- Push notification infrastructure (NotificationManager.swift) with auth request and local notification scheduling
- Watch sync via WatchConnectivity (WatchSyncManager.swift)
- RevenueCat subscription management (RevenueCatManager.swift)
- Translation caching with disk persistence (TranslationCache.swift)
- GitHub auth stub in AuthManager.swift (not implemented)

**What the app does NOT have:**
- No Widget/Live Activity/Dynamic Island support
- No Siri Intents or Shortcuts integration
- No SharePlay support
- No Spotlight search indexing
- No App Clips
- No background audio mode configuration (no UIBackgroundModes in plist)
- No Control Center / Now Playing integration
- No StandBy mode support
- No iOS 26 Apple Intelligence / on-device AI usage (iOS deployment target is already 26.2, but no Apple Intelligence APIs adopted)
- No .entitlements file for the main iOS target

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact |
|---|---------|----------|--------|--------|
| 1 | Background audio handling (UIBackgroundModes audio) | High | S | High — core translation recording works when app backgrounded |
| 2 | Push notification handling (wiring APNs to Supabase) | High | S | High — community/social features depend on real-time alerts |
| 3 | WidgetKit support (translation stats, quick phrases) | Medium | M | Medium — Android already has QuickTranslateWidget |
| 4 | Siri intents integration (translate shortcut) | Medium | M | Medium — hands-free dog translation is a natural use case |
| 5 | Control Center / Now Playing integration | Medium | S | Medium — shows translation audio in system UI |
| 6 | Offline mode capabilities (expand beyond basic UI) | High | M | High — SyncManager has plumbing, needs full offline UI |
| 7 | Shortcuts integration (Siri + Shortcuts app) | Medium | M | Medium — pairs with Siri intents |
| 8 | Spotlight search indexing (past translations) | Low | S | Medium — quick access to translation history |
| 9 | Live Activity support (translation in progress) | Medium | M | Medium — iOS 16+ real-time updates |
| 10 | Dynamic Island integration | Low | S | Medium — iPhone 14 Pro+ users get translation status |
| 11 | SharePlay support (group translation sessions) | Low | L | Low — niche but unique differentiator |
| 12 | App Clips (quick dog translation without install) | Low | L | Medium — viral acquisition channel |
| 13 | StandBy mode support | Low | S | Low — iOS 17+ nightstand mode |
| 14 | iOS 26 new APIs (Apple Intelligence on-device AI) | Low | L | High — future-proofing (iOS 26 is upcoming) |
| 15 | Lock Screen widgets | Low | S | Low — similar value to Home Screen widgets |

## Recommendations

**1. Background Audio Handling (Priority 1)**
The AudioSessionManager sets category `.playAndRecord` but does not configure `UIBackgroundModes` for audio in Info.plist. Add `audio` to UIBackgroundModes and configure the audio session with `.mixWithOthers` option already present. This is a one-line Info.plist change plus ensuring AudioEngine can resume after interruption. Critical because users expect translation to continue when multitasking.

**2. Push Notification Wiring (Priority 2)**
NotificationManager has the infrastructure but `didRegisterForRemoteNotifications` calls `AuthManager.shared.updateDeviceToken(token)` which doesn't exist yet — the method is not implemented in AuthManager. Wire device tokens to Supabase `profiles` table and handle incoming APNs payloads in AppDelegate (which currently has no `didReceiveRemoteNotification` implementation). This unblocks all social/community features.

**3. WidgetKit + Siri Intents (Priority 3)**
Android already has `QuickTranslateWidget.kt` — iOS should match this with a Widget extension showing recent translations and a quick-translate shortcut. Siri intents (INIntent) for "Translate this to dog" would differentiate WoofTalk on iOS. Combine into one sprint: Widget extension (Medium effort) + Siri intent definition (Medium effort) = high visibility on iOS Home Screen and via voice.
