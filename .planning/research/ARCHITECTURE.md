# Architecture Research

**Domain:** Cross-platform Mobile (iOS + Android + Backend)
**Researched:** 2026-03-31
**Confidence:** HIGH

## Executive Summary

This document outlines the architecture for expanding WoofTalk from iOS-only to include Android + shared backend. Based on analysis of the existing iOS codebase, we recommend **Supabase** for the shared backend due to its superior SQL flexibility, open-source nature, and excellent realtime capabilities. The translation engine logic should be shared via protocol-based design rather than code sharing, with platform-specific implementations.

---

## 1. Shared Backend Options

### Comparison Matrix

| Criteria | Firebase | Supabase | Custom Backend |
|----------|----------|----------|----------------|
| **Auth** | Excellent (Google, Apple, Email) | Excellent (30+ providers + email) | Requires building |
| **Database** | NoSQL (Firestore) | PostgreSQL (relational) | Full control |
| **Realtime** | Firestore listeners | PostgreSQL + Broadcast | Requires WebSocket |
| **Offline** | Built-in support | Client with local caching | Custom build |
| **Cost** | Pay-per-use, generous free tier | Generous free tier + paid plans | Hosting + Dev time |
| **iOS SDK** | Excellent | Excellent | Custom |
| **Android SDK** | Excellent | Excellent | Custom |
| **Open Source** | No | Yes | Full control |
| **SQL Flexibility** | Limited | Full PostgreSQL | Full control |

### Recommendation: Supabase

**Rationale for WoofTalk:**
1. **PostgreSQL aligns with Core Data → Room mapping** — Both are relational, making schema translation straightforward
2. **Row Level Security (RLS)** — Native multi-platform access control (web, iOS, Android, API) with different permission levels
3. **Realtime subscriptions** — Direct PostgreSQL change listening for community features (leaderboards, activity feed)
4. **Offline-first support** — Supabase client has built-in caching for offline operations
5. **Open source** — No vendor lock-in, can self-host if needed
6. **Edge Functions** — Serverless functions for AI translation proxying

**When to choose Firebase instead:**
- Team already heavily invested in Google ecosystem
- Need Firestore's offline-first by default (Supabase requires manual setup)
- NoSQL better matches your data model (WoofTalk data is relational)

---

## 2. Translation Engine Sharing Strategy

### Current iOS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    RealTranslationController                 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐                │
│  │ TranslationMode │  │  Translation     │                │
│  │    Manager      │──│    Engine        │                │
│  │  (AI vs Rules) │  │  (fallback chain)│                │
│  └────────┬────────┘  └────────┬─────────┘                │
│           │                    │                           │
│  ┌────────┴────────┐  ┌───────┴────────┐                 │
│  │ AITranslation   │  │ Vocabulary      │                 │
│  │    Service      │  │ Database        │                 │
│  └─────────────────┘  └─────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

### Recommended Sharing Strategy: Protocol-Based

```
┌─────────────────────────────────────────────────────────────┐
│                    TranslationEngine (Protocol)             │
├─────────────────────────────────────────────────────────────┤
│  + translate(input:direction:) async throws -> Result       │
│  + fallbackTranslate(input:direction:) -> String            │
│  + getQualityScore(for:text:) -> TranslationQualityScore?  │
└─────────────────────────────────────────────────────────────┘
           │                              │
     ┌─────┴─────┐                  ┌─────┴─────┐
     ▼           ▼                  ▼           ▼
┌─────────┐  ┌─────────┐        ┌─────────┐  ┌─────────┐
│ Swift   │  │ Kotlin  │        │ Swift   │  │ Kotlin  │
│ iOS Impl│  │Android  │        │ iOS Impl│  │Android  │
│         │  │         │        │         │  │         │
│ - CoreML│  │- ML Kit │        │- SQLite │  │- Room   │
│ - AV    │  │- Speech │        │- Vocab  │  │- Vocab  │
└─────────┘  └─────────┘        └─────────┘  └─────────┘
```

### Implementation Approach

**Do NOT share algorithm code directly.** Instead:
1. Define `TranslationEngineProtocol` in a shared specification document
2. Implement `KotlinTranslationEngine` for Android (Jetpack Compose compatible)
3. Implement `SwiftTranslationEngine` for iOS (SwiftUI compatible)
4. Both use same fallback chain logic: **AI → Vocabulary → Simple**

**Shared components (just data, not logic):**
- Translation input/output models (JSON schemas)
- Quality score models
- Language pack formats
- Translation direction enum

---

## 3. Data Model Mapping

### iOS (Core Data) → Android (Room) → Cloud (PostgreSQL)

```
┌────────────────────────────────────────────────────────────────────┐
│                         CORE DATA (iOS)                            │
├────────────────────────────────────────────────────────────────────┤
│  Entities:                                                          │
│  - User (id, username, email, isModerator)                        │
│  - Contribution (humanText, dogTranslation, status, qualityScore) │
│  - CommunityPhrase (humanText, dogTranslation, direction, timestamp)│
│  - TranslationHistory (input, output, timestamp, direction)       │
│  - FollowRelationship (followerID, followingID, timestamp)         │
│  - BlockRelationship (blockerID, blockedID, timestamp)             │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (mapping layer)
┌────────────────────────────────────────────────────────────────────┐
│                         ROOM DATABASE (Android)                    │
├────────────────────────────────────────────────────────────────────┤
│  Entities:                                                         │
│  - UserEntity (id, username, email, isModerator)                   │
│  - ContributionEntity (humanText, dogTranslation, status, ...)     │
│  - CommunityPhraseEntity (humanText, dogTranslation, direction, ..)│
│  - TranslationHistoryEntity (input, output, timestamp, direction) │
│  - FollowRelationshipEntity (followerId, followingId, timestamp) │
│  - BlockRelationshipEntity (blockerId, blockedId, timestamp)       │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Supabase client)
┌────────────────────────────────────────────────────────────────────┐
│                      POSTGRESQL (Supabase)                         │
├────────────────────────────────────────────────────────────────────┤
│  Tables:                                                            │
│  - users (id, username, email, created_at, platform)               │
│  - contributions (id, user_id, human_text, dog_translation, ...)   │
│  - community_phrases (id, human_text, dog_translation, direction)  │
│  - translation_history (id, user_id, input, output, direction, ..) │
│  - follow_relationships (follower_id, following_id, created_at)   │
│  - block_relationships (blocker_id, blocked_id, created_at)       │
│  - language_packs (language, version, vocabulary_json)             │
└────────────────────────────────────────────────────────────────────┘
```

### Key Mapping Rules

| iOS Core Data | Android Room | PostgreSQL |
|--------------|--------------|------------|
| `UUID` | `UUID` | `UUID` (primary key) |
| `Date` | `Long` (timestamp) | `TIMESTAMP` |
| `Set<Contribution>` | One-to-Many via ForeignKey | Foreign key + JOIN |
| `String?` (optional) | `String?` | `TEXT` (nullable) |
| `Bool` | `Boolean` | `BOOLEAN` |
| `Double` (quality) | `Double` | `DOUBLE PRECISION` |

### Sync Strategy

1. **CRDT for conflict resolution** — Use vector clocks or last-write-wins with timestamps
2. **Offline-first** — Both apps cache locally, sync when online
3. **Sync queue** — Similar to iOS `ContributionSyncManager`, Android uses WorkManager for background sync

---

## 4. Cross-Platform Account Sync Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AUTH ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐     ┌─────────────┐     ┌──────────────────────────┐ │
│  │   iOS    │     │  Supabase   │     │        Android           │ │
│  │  App     │◄───►│   Auth      │◄───►│         App              │ │
│  │          │     │             │     │                          │ │
│  │ - SignIn │     │ - Providers │     │ - SignIn                 │ │
│  │ - SignUp │     │ - Sessions  │     │ - SignUp                 │ │
│  │ - Link   │     │ - Tokens    │     │ - Link                   │ │
│  └──────────┘     └─────────────┘     └──────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    Cross-Platform Sync                         │ │
│  │                                                                │ │
│  │  User ───┬──► iOS Profile ──┐                                │ │
│  │          │                   │                                │ │
│  │          └──► Android Profile┴──► Unified Profile (cloud)    │ │
│  │                                                                │ │
│  │  Shared: username, email, preferences, subscription_status  │ │
│  │  Platform-specific: device_token, push_settings              │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Account Linking Flow

1. **New user** → Register on either platform → Auto-created in Supabase with `platform` field
2. **Existing user on new platform** → Login with same credentials → Supabase links to existing user via email/ID
3. **Link accounts** → User can explicitly link multiple auth providers to same account

### Sync Scope

| Data | Sync Strategy |
|------|---------------|
| **User profile** | Real-time sync across all devices |
| **Translation history** | Background sync, offline-first |
| **Community phrases** | Pull from cloud on app start + periodic refresh |
| **Social graph** | Real-time via Supabase Realtime subscriptions |
| **Leaderboard** | Real-time via Supabase Realtime |
| **Settings/preferences** | Local-first, sync on change |

---

## 5. Real-Time Sync for Community Features

### Features Requiring Realtime

| Feature | Update Frequency | Technology |
|---------|-----------------|------------|
| Activity feed | On new activity | Supabase Realtime (broadcast) |
| Leaderboard | On score change | Supabase Realtime (Postgres changes) |
| Social graph (followers) | On follow/unfollow | Supabase Realtime (Postgres changes) |
| Community phrase approvals | On status change | Supabase Realtime (Postgres changes) |

### Implementation

```kotlin
// Android (Kotlin) - Real-time subscription example
val supabase = createSupabaseClient(...)
supabase.from("leaderboard")
    .on("UPDATE") { callback ->
        // Update UI when leaderboard changes
    }
    .subscribe()
```

```swift
// iOS (Swift) - Real-time subscription example
let channel = supabase.channel("leaderboard")
channel.on("UPDATE") { payload in
    // Update leaderboard UI
}
.subscribe()
```

### Offline Handling
- Queue local changes when offline
- On reconnect, sync queue via `syncQueuedContributions()` pattern (already in iOS `ContributionSyncManager`)
- Use Supabase's `reconnect` event to trigger sync

---

## 6. Build Order & Dependencies

### Recommended Phase Execution

```
Phase 1: Backend Foundation (PREREQUISITE)
├── 1.1 Supabase project setup
├── 1.2 Database schema design & RLS policies
├── 1.3 Auth configuration (providers)
├── 1.4 Edge functions for AI translation proxy
└── 1.5 Realtime configuration

Phase 2: Android Core Translation
├── 2.1 Android project setup (Kotlin + Jetpack Compose)
├── 2.2 Room database setup (schema from iOS Core Data)
├── 2.3 TranslationEngine protocol implementation
├── 2.4 VocabularyDatabase (Room equivalent)
├── 2.5 Basic UI (Compose-based translation screen)
└── 2.6 Voice I/O (SpeechRecognizer + TextToSpeech)

Phase 3: Android Voice Features
├── 3.1 Audio capture integration
├── 3.2 Speech-to-text pipeline
├── 3.3 Dog vocalization synthesis (TTS)
├── 3.4 Real-time streaming translation
└── 3.5 Translation quality scoring

Phase 4: Android Community Features
├── 4.1 User authentication (Supabase Auth)
├── 4.2 Contribution system (submit phrases)
├── 4.3 Community phrase browser
├── 4.4 Social features (follow, leaderboard)
├── 4.5 Moderation queue (if moderator)
└── 4.6 Activity feed

Phase 5: Cross-Platform Sync
├── 5.1 iOS Supabase integration
├── 5.2 Translation history sync
├── 5.3 Social graph sync
├── 5.4 Account linking flow
└── 5.5 Offline sync validation

Phase 6: Integration & Polish
├── 6.1 Feature parity verification
├── 6.2 Cross-platform testing
├── 6.3 Performance optimization
├── 6.4 Analytics integration
└── 6.5 App store deployment
```

### Critical Dependencies

```
Backend (Phase 1)
    │
    ├── Required for Phase 2.2 (Room schema derived from backend)
    ├── Required for Phase 4.1 (Auth)
    └── Required for Phase 5 (Sync)

Android Core (Phase 2)
    │
    ├── Required for Phase 3 (Voice builds on core)
    └── Required for Phase 4 (Community builds on core)

Android Voice (Phase 3)
    │
    └── Required for Phase 6 (Integration)

Android Community (Phase 4)
    │
    └── Required for Phase 6 (Integration)

Cross-Platform Sync (Phase 5)
    │
    └── Requires BOTH iOS Supabase + Android Community
```

---

## 7. New vs Modified Components

### New Components (Brand New)

| Component | Platform | Description |
|-----------|----------|-------------|
| `SupabaseBackend` | Cloud | PostgreSQL database, Auth, Realtime |
| `AndroidTranslationEngine` | Android | Kotlin implementation of translation protocol |
| `AndroidRoomDatabase` | Android | Room persistence (replaces Core Data) |
| `AndroidVoicePipeline` | Android | Speech recognition + TTS |
| `AndroidCommunityModule` | Android | Contributions, phrases, social features |
| `SyncManager` | Both | Cross-platform data synchronization |
| `AccountLinkingService` | Both | Link accounts across platforms |

### Modified Components (Extend Existing iOS)

| Component | Modification | Reason |
|-----------|-------------|--------|
| `TranslationEngine` | Add Supabase client | Cloud vocabulary sync |
| `ContributionSyncManager` | Add Supabase backend endpoint | Cloud contribution storage |
| `SocialGraphManager` | Add Supabase Realtime subscription | Real-time follower updates |
| `CommunityPhraseManager` | Add cloud fetch + push | Sync with cloud phrases |
| `NetworkManager` | Add Supabase connectivity | Replace placeholder network check |
| `User+CoreDataClass` | Add platform identifier | Track iOS vs Android vs Web |

### Components to Keep Identical (No Changes)

- `LanguagePack` format (JSON schema stays same)
- `TranslationModeManager` logic (fallback chain unchanged)
- `VocabularyDatabase` lookup algorithm (same in Room)
- `TranslationQualityScorer` model (shared JSON)
- `AnimalLanguage` enum (same values)

---

## 8. Integration Points Summary

### External Services

| Service | Integration | Notes |
|---------|-------------|-------|
| **Supabase** | Auth, Database, Realtime, Storage | Primary backend |
| **OpenAI** | Translation API | Via Supabase Edge Functions (protects API key) |
| **Apple Sign In** | Auth provider | iOS-specific |
| **Google Sign In** | Auth provider | Android-specific |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **iOS ↔ Backend** | Supabase SDK (Swift) | REST-like + realtime subscriptions |
| **Android ↔ Backend** | Supabase SDK (Kotlin) | Same API, native SDK |
| **iOS ↔ Android** | Via Backend | No direct P2P, all through Supabase |
| **Translation Engine** | Protocol | Platform-specific implementations |

---

## 9. Scaling Considerations

| Scale | Architecture |
|-------|--------------|
| **0-10k users** | Single Supabase project, default configuration |
| **10k-100k** | Add database read replicas, consider caching layer |
| **100k+** | Sharding strategy, dedicated Supabase Pro support |

### First Bottleneck Predictions
1. **AI Translation latency** — Mitigate with Edge Functions + caching
2. **Realtime subscriptions** — Supabase handles automatically with Postgres changes
3. **Translation history sync** — Implement pagination, sync only recent items

---

## 10. Anti-Patterns to Avoid

### Anti-Pattern 1: Direct CoreML → ML Kit Port
**Don't:** Try to convert Swift ML models to Android models
**Instead:** Share algorithm logic, use platform-specific ML (CoreML on iOS, ML Kit on Android)

### Anti-Pattern 2: Single Auth Token
**Don't:** Use same auth token for all platforms
**Instead:** Each platform gets own session, link via user ID in Supabase Auth

### Anti-Pattern 3: Realtime for Everything
**Don't:** Use realtime subscriptions for translation history
**Instead:** Pull-based sync for large datasets, realtime only for social/notifications

### Anti-Pattern 4: Skip RLS
**Don't:** Disable Row Level Security for faster dev
**Instead:** Design RLS from day one — different permissions for owner, follower, public

---

## Sources

- Supabase Documentation: https://supabase.com/docs
- Firebase Documentation: https://firebase.google.com/docs
- Room Database Guide: https://developer.android.com/jetpack/androidx/releases/room
- Kotlin Coroutines for async: https://kotlinlang.org/docs/coroutines-overview.html
- Jetpack Compose: https://developer.android.com/jetpack/compose
- iOS Core Data to Supabase mapping patterns from existing ContributionSyncManager

---

*Architecture research for: Cross-platform Mobile Expansion*
*Researched: 2026-03-31*