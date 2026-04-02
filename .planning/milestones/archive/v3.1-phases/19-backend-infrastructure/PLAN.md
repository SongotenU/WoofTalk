# Phase 19: Backend Infrastructure — Execution Plan

**Milestone:** v3.0 Platform Expansion
**Duration:** 3-4 weeks
**Prerequisites:** None

---

## Goal

Set up Supabase backend infrastructure — PostgreSQL database, auth providers, database schema mapped from Core Data, realtime subscriptions, FCM push notifications, and iOS SDK integration — enabling cross-platform data access for both iOS and Android clients.

---

## Requirements

| ID | Requirement |
|----|-------------|
| BACKEND-01 | Supabase project provisioned with PostgreSQL, auth (email, Google, Apple), RLS policies |
| BACKEND-02 | Database schema for users, translations, community phrases, contributions, follows, blocks, activity events, leaderboard entries |
| BACKEND-03 | REST/GraphQL API layer with auth middleware, rate limiting, input validation |
| BACKEND-04 | Realtime subscriptions for community phrase updates, activity feed events, leaderboard changes |
| BACKEND-05 | FCM configured for Android push notifications |
| BACKEND-06 | Supabase client SDK integrated into existing iOS app |

---

## Task Breakdown

### Wave 1: Foundation (Days 1-3) — Parallel

**T1. Supabase Project Setup**
- Create Supabase project (production + staging)
- Configure environment variables (project URL, anon key, service role key)
- Set up organization and team access
- Configure CORS for iOS/Android origins
- **Effort:** 2 hours
- **Deliverable:** Live Supabase project with credentials documented

**T2. Auth Provider Configuration**
- Enable Email/Password auth
- Configure Google OAuth (create Google Cloud project, OAuth consent screen)
- Configure Apple Sign In (create Apple Developer app ID, key, configure redirect)
- Set up email templates (confirmation, password reset)
- Configure auth hooks for platform detection (iOS vs Android)
- **Effort:** 4 hours
- **Deliverable:** All 3 auth providers working, test users created

**T3. Core Data → PostgreSQL Schema Migration Design**
- Map each Core Data entity to PostgreSQL table:
  - `users` (id UUID, email, display_name, avatar_url, platform, is_premium, subscription_expiry, created_at, updated_at)
  - `translations` (id UUID, user_id FK, human_text, animal_text, source_language, target_language, confidence, quality_score, is_favorite, created_at)
  - `community_phrases` (id UUID, phrase_text, language, submitted_by FK, approved_by FK, approval_status, upvotes, downvotes, created_at, updated_at)
  - `contributions` (id UUID, user_id FK, phrase_id FK, status, submitted_at, reviewed_at, reviewer_id FK)
  - `follow_relationships` (follower_id UUID FK, following_id UUID FK, created_at, PK: (follower_id, following_id))
  - `block_relationships` (blocker_id UUID FK, blocked_id UUID FK, created_at, PK: (blocker_id, blocked_id))
  - `activity_events` (id UUID, user_id FK, event_type, event_data JSONB, visibility, created_at)
  - `leaderboard_entries` (id UUID, user_id FK, score, period, rank, updated_at)
- Design indexes for query patterns (user lookups, phrase search, activity feed pagination)
- Design foreign key constraints and cascade rules
- **Effort:** 4 hours
- **Deliverable:** Schema migration document with SQL

### Wave 2: Database & Security (Days 4-7) — Parallel after Wave 1

**T4. Database Schema Implementation**
- Execute SQL migrations in Supabase (use Supabase migration system)
- Create all 8 tables with proper types, constraints, indexes
- Add computed columns where useful (e.g., `full_name` from display_name)
- Seed test data for each table
- **Effort:** 4 hours
- **Deliverable:** All tables created, seeded, queryable via Supabase SQL editor

**T5. Row-Level Security (RLS) Policies**
- Define RLS policies per table:
  - `users`: Users can read/update own profile; admins can read all
  - `translations`: Users can CRUD own translations; no public read
  - `community_phrases`: Anyone can read approved; only authenticated can create; moderators can approve/reject
  - `contributions`: Users can CRUD own; moderators can review
  - `follow_relationships`: Users can manage own follows; anyone can read
  - `block_relationships`: Users can manage own blocks; private
  - `activity_events`: Users can read visible events; system can create
  - `leaderboard_entries`: Anyone can read; system updates
- Create `is_admin()` helper function
- Create trigger functions for auto-updating `updated_at` timestamps
- **Effort:** 6 hours
- **Deliverable:** All RLS policies active, tested with anon/authenticated roles

**T6. Database Functions & Triggers**
- Create `update_updated_at_column()` trigger function
- Create `increment_phrase_votes()` function for upvote/downvote
- Create `calculate_leaderboard()` function for periodic leaderboard computation
- Create `notify_new_activity()` trigger for Realtime events
- Create `search_phrases()` function for full-text phrase search
- **Effort:** 4 hours
- **Deliverable:** All functions deployed and tested

### Wave 3: API & Realtime (Days 8-12) — After Wave 2

**T7. Supabase Edge Functions (API Layer)**
- Set up Supabase Edge Functions (Deno runtime)
- Implement auth middleware function (validate JWT, attach user context)
- Implement rate limiting middleware (token bucket per user/IP)
- Implement input validation helpers (phrase text length, email format, etc.)
- Create custom endpoints that Supabase REST doesn't cover:
  - `POST /api/translate` — log translation to database
  - `POST /api/phrases/search` — full-text phrase search
  - `GET /api/leaderboard` — computed leaderboard with pagination
  - `POST /api/activity/batch` — batch activity event creation
- **Effort:** 8 hours
- **Deliverable:** Edge functions deployed, tested with curl/Postman

**T8. Realtime Subscriptions Configuration**
- Enable Realtime for `community_phrases`, `activity_events`, `leaderboard_entries` tables
- Configure broadcast channels per event type:
  - `phrase_updates` — new/approved/rejected phrases
  - `activity_feed` — new activity events
  - `leaderboard_changes` — rank updates
- Set up Realtime filters (only broadcast approved phrase changes)
- Test Realtime latency (<1 second target)
- **Effort:** 4 hours
- **Deliverable:** Realtime channels active, latency verified <1s

**T9. FCM Setup for Push Notifications**
- Create Firebase project (FCM only, no Firestore needed)
- Generate FCM server key
- Configure FCM in Supabase (Edge Function to send push via FCM API)
- Create `push_notifications` table for notification queue
- Create Edge Function `send-push-notification` that reads queue and calls FCM API
- Test push delivery to Android test device
- **Effort:** 6 hours
- **Deliverable:** Push notifications working on Android test device

### Wave 4: iOS Integration (Days 13-16) — After Wave 3

**T10. Supabase iOS SDK Integration**
- Add `supabase-swift` package via SPM to existing Xcode project
- Configure Supabase client singleton (URL, anon key)
- Create `SupabaseManager` class with methods:
  - `signIn(email:password:)`, `signUp(email:password:)`, `signOut()`
  - `signInWithGoogle()`, `signInWithApple()`
  - `fetchTranslations()`, `saveTranslation()`
  - `fetchCommunityPhrases()`, `submitPhrase()`
  - `follow(userId:)`, `unfollow(userId:)`
  - `subscribeToRealtime(channel:)`
- **Effort:** 8 hours
- **Deliverable:** SupabaseManager class with all methods

**T11. iOS Dual-Mode Data Layer**
- Create `DataSource` protocol with `LocalDataSource` (Core Data) and `CloudDataSource` (Supabase) implementations
- Implement `SyncManager` that:
  - Reads from local Core Data first (offline-first)
  - Syncs to Supabase when online
  - Handles conflict resolution (last-write-wins for translations)
  - Queues writes when offline, replays when online
- Update existing Core Data code to use protocol (no breaking changes)
- **Effort:** 12 hours
- **Deliverable:** Dual-mode data layer working, existing iOS features unchanged

**T12. iOS Auth Integration**
- Replace/augment existing auth with Supabase auth
- Implement auth state observer (login/logout events)
- Implement token refresh handling
- Add platform field to user profile (`platform = "ios"`)
- Test auth flow: sign up → sign in → sign out → token refresh
- **Effort:** 6 hours
- **Deliverable:** Auth working end-to-end on iOS

### Wave 5: Testing & Verification (Days 17-20) — After Wave 4

**T13. Integration Testing**
- Test auth flow across all 3 providers (email, Google, Apple)
- Test CRUD operations on all 8 tables via iOS app
- Test Realtime: create phrase on iOS → verify appears in subscription within 1s
- Test offline mode: make changes offline → go online → verify sync
- Test FCM: trigger notification from Supabase → verify received on Android test device
- Test RLS: verify anon user cannot access private data
- **Effort:** 8 hours
- **Deliverable:** All integration tests passing

**T14. Performance Verification**
- Measure API endpoint latency (target: <200ms)
- Measure Realtime latency (target: <1s)
- Measure auth flow latency (target: <2s for sign-in)
- Verify no Core Data breakage (existing features work)
- **Effort:** 4 hours
- **Deliverable:** Performance metrics documented, all targets met

---

## Dependency Graph

```
Wave 1:  T1 ─┬─ T3
             ├─ T2
             └── (T1, T2, T3 parallel)

Wave 2:  T4 ─┬─ T5 ─┬─ T6
             │      │
             └──────┘ (T4 first, then T5+T6 parallel)

Wave 3:  T7 ─┬─ T8
             ├─ T9
             └── (T7, T8, T9 parallel after Wave 2)

Wave 4:  T10 ─┬─ T11 ─┬─ T12
              │       │
              └───────┘ (T10 first, then T11+T12 parallel)

Wave 5:  T13 ─┬─ T14
              └── (T13 first, then T14)
```

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Supabase project live with auth providers | Sign up/sign in with email, Google, Apple — all succeed |
| 2 | Database schema matches Core Data entities | All 8 tables exist with correct columns, types, FKs, indexes |
| 3 | API endpoints <200ms with auth middleware | Load test 100 requests, measure p95 latency |
| 4 | Realtime <1s delivery | Create phrase → measure time until Realtime event received |
| 5 | FCM push to Android | Send test notification → verify received on Android device |
| 6 | iOS app works with Supabase + Core Data intact | Run existing iOS app — all features work, new cloud features accessible |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Supabase auth conflicts with existing iOS auth | Medium | High | Dual-mode auth during transition, gradual migration |
| RLS policies too restrictive, breaking app | Medium | High | Test with both anon and authenticated roles before deployment |
| Realtime latency exceeds 1s target | Low | Medium | Use Supabase's dedicated Realtime servers, monitor with logging |
| Core Data breakage during integration | Low | Critical | Protocol-based abstraction, extensive regression testing |
| FCM setup complexity (separate Firebase project) | Medium | Low | FCM-only Firebase project, minimal configuration needed |
