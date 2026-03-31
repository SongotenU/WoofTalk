# v3.0 Requirements — Platform Expansion

**Milestone:** v3.0 Platform Expansion
**Date:** 2026-03-31
**Goal:** Expand WoofTalk from iOS-only to Android with shared cloud backend and full cross-platform account sync.

---

## Backend Infrastructure

- [ ] **BACKEND-01**: Supabase project is provisioned with PostgreSQL database, auth providers (email, Google, Apple), and row-level security (RLS) policies
- [ ] **BACKEND-02**: Database schema is defined for users, translations, community phrases, contributions, follows, blocks, activity events, and leaderboard entries — mapped from existing Core Data models
- [ ] **BACKEND-03**: REST/GraphQL API layer is implemented with authentication middleware, rate limiting, and input validation
- [ ] **BACKEND-04**: Realtime subscriptions are configured for community phrase updates, activity feed events, and leaderboard changes using Supabase Realtime
- [ ] **BACKEND-05**: Firebase Cloud Messaging (FCM) is configured for push notification delivery to Android devices
- [ ] **BACKEND-06**: Supabase client SDK is integrated into existing iOS app for cross-platform data access

## Android Core Translation

- [ ] **ANDROID-CORE-01**: Kotlin translation engine is implemented with rule-based translation (human↔animal) matching iOS TranslationEngine logic and vocabulary
- [ ] **ANDROID-CORE-02**: AI translation integration with OpenAI API is implemented, matching iOS AITranslationService with fallback chain (AI → Vocabulary → Simple)
- [ ] **ANDROID-CORE-03**: Jetpack Compose UI is implemented with Material 3 design system, matching iOS feature set (translation view, history, settings)
- [ ] **ANDROID-CORE-04**: Room Database is implemented for local persistence of translation history, user data, and cached phrases — schema matches iOS Core Data models
- [ ] **ANDROID-CORE-05**: Multi-language support (Dog, Cat, Bird) is implemented with protocol-based language adapter pattern matching iOS
- [ ] **ANDROID-CORE-06**: LRU translation cache is implemented with configurable max size and TTL, matching iOS TranslationCache

## Android Voice I/O

- [ ] **VOICE-01**: Speech recognition input is implemented using android.speech.SpeechRecognizer with RECORD_AUDIO permission handling
- [ ] **VOICE-02**: Text-to-speech output is implemented using android.speech.tts.TextToSpeech with configurable voice, speed, and pitch
- [ ] **VOICE-03**: Background voice processing is implemented as a foreground service with microphone notification, allowing continuous translation while app is backgrounded
- [ ] **VOICE-04**: Audio format handling matches iOS (sample rate, encoding, buffer size) for consistent translation quality
- [ ] **VOICE-05**: Voice input/output is integrated with the translation engine pipeline, matching iOS RealTranslationController flow

## Android Community & Social

- [ ] **COMMUNITY-01**: Community phrase browser is implemented with browse, search, and filter capabilities, matching iOS CommunityPhraseManager
- [ ] **COMMUNITY-02**: Phrase contribution system is implemented with submission, validation, and quality scoring, matching iOS ContributionValidationService
- [ ] **COMMUNITY-03**: Social features are implemented: follow/unfollow users, leaderboards, activity feed, matching iOS SocialGraphManager
- [ ] **COMMUNITY-04**: Spam detection and moderation tools are implemented, matching iOS SpamDetectionService and AutoModerationService
- [ ] **COMMUNITY-05**: Android share intent integration (Intent.ACTION_SEND) is implemented for sharing translations and phrases to other apps
- [ ] **COMMUNITY-06**: Home screen widget (Glance) is implemented for quick translation access from Android home screen

## Cross-Platform Sync

- [ ] **SYNC-01**: Shared authentication allows users to log in with same credentials on iOS and Android, with unified Supabase user identity
- [ ] **SYNC-02**: Translation history is synced across platforms — user sees same history on iOS and Android
- [ ] **SYNC-03**: Social graph (follows, blocks, leaderboards) is synced across platforms with conflict resolution
- [ ] **SYNC-04**: Real-time activity feed sync is implemented using Supabase Realtime — new community phrases, contributions, and social activity appear live on both platforms
- [ ] **SYNC-05**: Offline-first sync queue is implemented on Android — changes made offline are queued and synced when connectivity is restored
- [ ] **SYNC-06**: Conflict resolution strategy is defined and implemented for concurrent edits (last-write-wins for translations, merge for social graph)

---

## Future Requirements (Deferred)

### Web Version
- [ ] **WEB-01**: React/Next.js web application with translation interface
- [ ] **WEB-02**: Web-based community phrase browser and contribution system
- [ ] **WEB-03**: Admin dashboard for moderation and analytics

### Smartwatch Companion
- [ ] **WATCH-01**: Wear OS companion app for quick translations
- [ ] **WATCH-02**: Apple Watch companion app for iOS users
- [ ] **WATCH-03**: Voice-only translation mode optimized for watch form factor

### Advanced Android Features
- [ ] **ANDROID-ADV-01**: Quick Settings Tile for instant translation launch
- [ ] **ANDROID-ADV-02**: Android Auto integration for in-car translation
- [ ] **ANDROID-ADV-03**: Dynamic color theming (Material You)

---

## Out of Scope

| Requirement | Reason |
|-------------|--------|
| Web version | Deferred to M005 — requires separate frontend stack |
| Smartwatch apps | Deferred to M005 — companion experience after main platforms |
| Android Auto | Too niche for v3.0 — validate demand first |
| Custom backend | Supabase covers all needs — custom backend adds unnecessary complexity |
| Cross-platform framework (Flutter/RN) | Native Kotlin + Jetpack Compose provides better quality and matches iOS parity goal |

---

## Traceability

| Phase | Requirements | Success Criteria |
|-------|-------------|-----------------|
| Phase 19: Backend Infrastructure | BACKEND-01 through BACKEND-06 | Supabase project live, iOS app connected, schema matches Core Data |
| Phase 20: Android Core Translation | ANDROID-CORE-01 through ANDROID-CORE-06 | Android app translates human↔animal text with history persistence |
| Phase 21: Android Voice I/O | VOICE-01 through VOICE-05 | Android app accepts voice input, produces voice output, works in background |
| Phase 22: Android Community & Social | COMMUNITY-01 through COMMUNITY-06 | Android users can browse, contribute, follow, and share phrases |
| Phase 23: Cross-Platform Sync | SYNC-01 through SYNC-06 | Same account works on iOS + Android with synced data |
| Phase 24: Final Integration | ALL | End-to-end flow: voice→translate→share works on Android, syncs to iOS |
