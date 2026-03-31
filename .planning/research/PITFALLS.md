# Pitfalls Research

**Domain:** iOS to Android Port (SwiftUI/Swift → Kotlin/Jetpack Compose)
**Researched:** 2026-03-31
**Confidence:** HIGH

This document catalogs common pitfalls when porting WoofTalk from iOS to Android, with specific warning signs, prevention strategies, and phase assignments.

---

## Critical Pitfalls

### Pitfall 1: Direct SwiftUI View Translation (Anti-Pattern)

**What goes wrong:**
Translating SwiftUI `@State` and `@ObservedObject` patterns directly to Compose state results in uncontrolled recomposition, UI flickering, and severe performance degradation. Developers often create ViewModels with exact SwiftUI equivalents without understanding Compose's lifecycle.

**Why it happens:**
SwiftUI's property wrappers (`@State`, `@Binding`, `@ObservedObject`) have implicit lifecycle tied to the view. Compose's `remember`, `mutableStateOf`, and `collectAsState` behave differently—composables can restart from any saved state, not just where they left off.

**How to avoid:**
1. Create Android-specific ViewModels using `ViewModel` with `StateFlow` instead of mirroring SwiftUI patterns
2. Use `rememberSaveable` for state that survives configuration changes
3. Implement proper `LaunchedEffect` and `DisposableEffect` for side effects
4. Use `derivedStateOf` to prevent unnecessary recompositions

**Warning signs:**
- ViewModel contains `@State` properties that are mutated directly
- Composable functions call expensive operations on every render
- UI flickers or resets on configuration changes
- Memory leaks from uncollected coroutine scopes

**Phase to address:** Phase 1 (Foundation) — UI pattern architecture must be defined before implementation

---

### Pitfall 2: Core Data to Room Schema Migration Without Testing

**What goes wrong:**
Assuming Core Data entities map 1:1 to Room entities causes data loss, relationship corruption, and failed migrations. Core Data's object graph and relationship handling differs fundamentally from Room's SQLite-based model.

**Why it happens:**
Core Data supports relationships with cascade delete rules, optional vs non-optional, and inverse relationships that don't exist in Room. The iOS Core Data model (Contribution, User with relationships) requires explicit migration strategy.

**How to avoid:**
1. Create Room entities as new implementation, not direct translation
2. Map Core Data models to Room DAOs with explicit migration scripts
3. Export iOS Core Data to JSON for Android import testing
4. Use Room's `Migration` class with `fallbackToDestructiveMigration()` only for development

**Warning signs:**
- Room entity has same property names as Core Data but different nullability
- Relationships not explicitly defined in Room entities
- No migration strategy documented before Phase 2
- Attempting to share Core Data model files with Android

**Phase to address:** Phase 2 (Data Layer) — Database schema must be designed before migration

---

### Pitfall 3: AVFoundation → MediaRecorder/ExoPlayer Permission Gap

**What goes wrong:**
iOS AVFoundation handles permissions and audio session configuration implicitly. Android requires explicit runtime permissions (`RECORD_AUDIO`), foreground service declarations, and audio focus management that are easy to miss, causing runtime crashes.

**Why it happens:**
Swift's `AVAudioSession.sharedInstance().requestRecordPermission` auto-prompts. Android's `Manifest.permission.RECORD_AUDIO` requires manual permission request with rationale, and audio playback in background requires `<uses-permission android:name="android.permission.FOREGROUND_SERVICE">` and service implementation.

**How to avoid:**
1. Implement permission flow using `ActivityResultContracts.RequestPermission`
2. Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE">` for background audio
3. Use `AudioAttributes` and `AudioFocusRequest` for proper audio session management
4. Implement ForegroundService for continuous audio processing

**Warning signs:**
- App crashes on first audio interaction without permission
- Audio stops when app goes to background
- Multiple audio apps conflict (no audio focus handling)
- No service declaration in AndroidManifest.xml

**Phase to address:** Phase 3 (Audio/Video) — Platform-specific permission architecture before implementation

---

### Pitfall 4: Shared Backend Without API Versioning Strategy

**What goes wrong:**
iOS and Android share backend but endpoints lack versioning, causing sync failures when one platform's data format changes. The translation service, community phrases, and user profiles break unexpectedly.

**Why it happens:**
Both platforms use the same API but iOS pushes format changes first. Without backward compatibility, Android receives unparseable responses or crashes.

**How to avoid:**
1. Implement API versioning from Day 1 (`/api/v1/`, `/api/v2/`)
2. Use feature flags for gradual rollout across platforms
3. Create shared API client library used by both iOS and Android
4. Document format contracts and enforce with JSON Schema validation

**Warning signs:**
- Backend changes immediately break Android (or vice versa)
- No API changelog or version deprecation schedule
- Both platforms hit same endpoints with different expectations
- Missing API response validation beyond status codes

**Phase to address:** Phase 4 (Cloud) — Backend architecture must define versioning before platform integration

---

### Pitfall 5: Cross-Platform Account Sync Without Unified Identity

**What goes wrong:**
Users create separate accounts on iOS and Android, or OAuth tokens don't transfer between platforms, causing account fragmentation, lost data, and support nightmares.

**Why it happens:**
Different OAuth providers (Sign in with Apple on iOS, Google Play Games on Android) or lack of email-based identity bridging. The User model doesn't account for multi-platform identity.

**How to avoid:**
1. Implement email/password as universal identity anchor
2. Create unified user ID that maps to platform-specific OAuth IDs
3. Use shared authentication provider (e.g., Firebase Auth) for cross-platform tokens
4. Implement account linking flow for existing users

**Warning signs:**
- Same email results in two different accounts
- OAuth tokens are platform-specific with no refresh mechanism
- No account linking UI in settings
- User ID differs between iOS and Android for same logical user

**Phase to address:** Phase 4 (Cloud) — Auth architecture must support unified identity before implementation

---

### Pitfall 6: Offline-First Without Conflict Resolution Strategy

**What goes wrong:**
iOS uses Core Data with NSPersistentCloudKit for offline changes. Android implementation lacks conflict resolution, causing data loss, duplicates, or stale data when offline changes sync.

**Why it happens:**
Core Data's merge policy handles conflicts implicitly. Room requires explicit conflict resolution (last-write-wins, merge, or manual). WoofTalk's offline translation cache and community contributions need conflict handling.

**How to avoid:**
1. Define conflict resolution strategy per entity (last-write-wins for translations, merge for community contributions)
2. Use Room's `onConflict` clause for simple cases
3. Implement manual conflict resolution UI for complex cases (user contributions)
4. Add "sync status" field to track pending/local changes

**Warning signs:**
- Duplicate entries appear after going online
- Local changes overwritten by server without notification
- No "last synced" timestamp in UI
- Offline edits silently lost on sync

**Phase to address:** Phase 2 (Data Layer) — Offline strategy must be designed before Room implementation

---

### Pitfall 7: Fragment Lifecycle Mismatch with SwiftUI Lifecycle

**What goes wrong:**
Android Fragments have complex lifecycle (onCreate → onViewCreated → onResume → onPause → onDestroy) that doesn't map to SwiftUI's simpler lifecycle. Translation state is lost, audio continues playing, or memory leaks occur.

**Why it happens:**
SwiftUI's `.onAppear` and `.onDisappear` fire once per navigation. Android's Fragment lifecycle fires multiple times (configuration changes, back navigation, process death). The audio engine from iOS needs explicit lifecycle binding in Android.

**How to avoid:**
1. Use Jetpack Navigation with NavHost and remember saved state
2. Bind audio session lifecycle to Fragment's `onResume`/`onPause`
3. Use `ViewModel` with SavedStateHandle for state persistence across lifecycle
4. Implement `onConfigurationChanged` handling explicitly

**Warning signs:**
- Translation progress lost on rotation
- Audio continues after navigating away from translation screen
- Memory leak from unclosed resources on Fragment destroy
- State resets when returning to previous screen

**Phase to address:** Phase 1 (Foundation) — Navigation and lifecycle architecture must be designed first

---

### Pitfall 8: Background Execution Limits Ignoring Doze Mode

**What goes wrong:**
iOS background audio is straightforward. Android's Doze mode, App Standby, and background execution limits kill ongoing translation processing, causing incomplete translations and frustrated users.

**Why it happens:**
Android 6+ introduced Doze mode that suspends background processing. iOS has background modes but fewer restrictions. WoofTalk's translation processing may be killed mid-translation.

**How to avoid:**
1. Use `WorkManager` for deferrable translation sync work
2. Request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` for critical translation features
3. Implement partial result caching to handle interruptions
4. Use `ForegroundService` for active translation sessions

**Warning signs:**
- Translations fail silently when phone is idle
- No notification that translation was interrupted
- Battery optimization settings reset translations
- Background sync never completes

**Phase to address:** Phase 3 (Audio/Video) — Background execution must be designed with Android power management in mind

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use `var` instead of `val` in Kotlin | Faster initial development | Mutable state bugs, harder testing | Never — use `val` by default |
| Skip Room migrations in dev | Faster iteration | Data loss in production | Only with `fallbackToDestructiveMigration()` during active dev |
| Single Activity architecture | Simpler initial setup | Harder to manage complex navigation | Acceptable for simple apps;WoofTalk needs Fragments for feature complexity |
| Copy iOS UI exactly | Familiar UX | Poor Android UX patterns | Only as initial wireframe, must Android-ize |
| Ignore ProGuard/R8 minification | Debugging easier | App size bloated, security risk | Only in debug builds |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| OpenAI API | Hardcoding API key in Android app | Use backend proxy with API key, or Firebase Remote Config with secrets |
| Firebase Auth | Different Firebase project per platform | Single Firebase project with both iOS and Android apps configured |
| Cloud Sync | No retry logic for network failures | Implement exponential backoff with WorkManager |
| Push Notifications | Separate FCM setup per platform | Single FCM setup with platform-specific payloads |
| Community Phrase API | Not handling rate limits | Implement local caching with Room, queue submissions |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Excessive recomposition | UI jank, battery drain | Use `derivedStateOf`, stable keys, lazy lists | With list > 100 items, complex animations |
| Main thread database queries | UI freezes | Use Room with `withContext(Dispatchers.IO)` | Any database operation > 16ms |
| Large image loading | OOM crashes, slow load | Use Coil/Glide with memory cache limits | With community phrase images > 10MB total |
| Inefficient JSON parsing | Slow sync | Use Kotlinx Serialization with pre-generated serializers | With community sync > 100 phrases |
| Memory leak from audio | Gradual slowdown, crashes | Proper lifecycle binding, release in onDestroy | After 30+ minutes of audio use |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing OAuth tokens in SharedPreferences | Token theft, account takeover | Use EncryptedSharedPreferences |
| Hardcoding API endpoints | MITM attacks, endpoint enumeration | Use build config with debug/release variants |
| No certificate pinning | Man-in-the-middle on public WiFi | Implement certificate pinning for production |
| Logging sensitive data (user text, translations) | Privacy violation, GDPR fines | Use privacy-aware logging ( Timber with privacy filters) |
| No rate limiting on translation API | API quota exhaustion, costs | Implement client-side rate limiting with WorkManager |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| iOS-style navigation (swipe back everywhere) | Android users expect back button | Use Jetpack Navigation with proper back stack |
| Not following Material Design 3 | App feels "not Android" | Apply Material 3 theming, use Material components |
| No haptic feedback on translation completion | Feels "dead" compared to iOS | Add vibration feedback on translation complete |
| Not handling dark mode | Blinding white UI at night | Implement dark theme from Day 1 |
| No offline indicator | User doesn't know why translation fails | Always show network status in UI |

---

## "Looks Done But Isn't" Checklist

- [ ] **Audio Recording:** Permission requested but rationale dialog missing — verify explainer shown before permission prompt
- [ ] **Offline Mode:** Translation cached but sync status not shown — verify "pending sync" indicator in UI
- [ ] **Account Sync:** Login works but cross-platform token refresh fails — verify token refresh works after 1 hour
- [ ] **Database Migration:** Room schema created but no migration tests — verify migration from empty to populated DB
- [ ] **Background Audio:** Audio plays but stops when screen locks — verify with Doze mode testing
- [ ] **Community Phrases:** Phrases load but pagination broken — verify scroll to bottom loads more

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| ViewModel pattern wrong | MEDIUM | Refactor to StateFlow + ViewModel, add integration tests |
| Room migration failure | HIGH | Reset DB, re-import from iOS export, add migration tests |
| Audio permission crash | LOW | Add permission check before any audio operation |
| Account fragmentation | HIGH | Implement account linking, notify users, provide merge UI |
| Offline sync loss | MEDIUM | Add conflict resolution, show sync status, implement retry |
| Background audio killed | MEDIUM | Migrate to ForegroundService, add battery optimization dialog |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SwiftUI to Compose anti-patterns | Phase 1: Foundation | UI state survives config change, no recomposition loops |
| Core Data to Room migration | Phase 2: Data Layer | Migration test passes with sample data |
| AVFoundation permission gaps | Phase 3: Audio/Video | Permission flow complete, background audio works |
| Backend versioning | Phase 4: Cloud | v2 endpoint works while v1 still supported |
| Account sync | Phase 4: Cloud | Same email on both platforms shows one account |
| Offline-first conflicts | Phase 2: Data Layer | Offline edits sync correctly after reconnection |
| Fragment lifecycle | Phase 1: Foundation | State persists through rotation, audio stops on exit |
| Background execution limits | Phase 3: Audio/Video | Translation completes in Doze mode |

---

## Sources

- Android Developer Documentation: Background execution limits, Doze mode
- Jetpack Compose: State management best practices
- Room Database: Migration documentation
- Firebase: Cross-platform auth patterns
- Android Architecture Components: ViewModel, SavedStateHandle
- Migrating from iOS to Android: Common pitfalls (Google Developer Relations)
- WoofTalk iOS codebase: CoreDataModel.swift, audio_engine.swift, WoofTalkApp.swift

---

*Pitfalls research for: iOS to Android port (WoofTalk)*
*Researched: 2026-03-31*