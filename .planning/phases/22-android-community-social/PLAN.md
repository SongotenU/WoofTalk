# Phase 22: Android Community & Social — Execution Plan

**Milestone:** v3.0 Platform Expansion
**Duration:** 4-5 weeks
**Prerequisites:** Phase 21 complete (Android Voice I/O)

---

## Goal

Build Android community and social features — community phrase browser, phrase contribution system, social features (follow/unfollow, leaderboards, activity feed), spam detection, share intent integration, and home screen widget — achieving full parity with iOS community features.

---

## Requirements

| ID | Requirement |
|----|-------------|
| COMMUNITY-01 | Community phrase browser with browse, search, filter |
| COMMUNITY-02 | Phrase contribution with submission, validation, quality scoring |
| COMMUNITY-03 | Social features: follow/unfollow, leaderboards, activity feed |
| COMMUNITY-04 | Spam detection and moderation tools |
| COMMUNITY-05 | Android share intent integration (Intent.ACTION_SEND) |
| COMMUNITY-06 | Home screen widget (Glance) for quick translation access |

---

## Task Breakdown

### Wave 1: Data + Network Layer (Days 1-5)

**T1. Supabase API Client**
- Create Retrofit/Ktor client for Supabase Edge Functions
- Implement auth interceptor (JWT token attachment)
- Create API interfaces: TranslateApi, PhraseApi, LeaderboardApi, ActivityApi
- Implement error handling and retry logic
- **Effort:** 6 hours
- **Deliverable:** Complete API client layer

**T2. Community Phrase Repository**
- Create `CommunityPhraseRepository` with Room + Supabase dual-source
- Implement pagination with Paging 3 library
- Implement search with debouncing
- Implement offline-first with sync on connectivity
- **Effort:** 6 hours
- **Deliverable:** Repository with offline-first phrase access

**T3. Social Repository**
- Create `SocialRepository` for follows, leaderboards, activity feed
- Implement follow/unfollow with optimistic updates
- Implement leaderboard pagination by period
- Implement activity feed with real-time updates via Supabase Realtime
- **Effort:** 6 hours
- **Deliverable:** Social data access layer

### Wave 2: Community UI (Days 6-12)

**T4. Community Phrase Browser Screen**
- Create `CommunityPhraseScreen` Composable with:
  - LazyColumn with Paging 3 for infinite scroll
  - Search bar with debounced search
  - Language filter chips (Dog/Cat/Bird/All)
  - Sort options (popular, recent, alphabetical)
  - Pull-to-refresh
  - Phrase detail bottom sheet
- **Effort:** 8 hours
- **Deliverable:** Fully functional phrase browser

**T5. Phrase Contribution Screen**
- Create `ContributePhraseScreen` Composable with:
  - Text input for phrase
  - Language selector
  - Preview of translation
  - Submit button with loading state
  - Validation feedback (length, duplicates)
- **Effort:** 6 hours
- **Deliverable:** Phrase submission screen

**T6. Social Screens**
- Create `LeaderboardScreen` Composable with:
  - Period tabs (daily, weekly, monthly, all-time)
  - Ranked list with user avatars
  - Current user position highlight
- Create `ActivityFeedScreen` Composable with:
  - Real-time activity feed
  - Different activity types (phrase submitted, followed, translated)
  - Pull-to-refresh with Supabase Realtime
- **Effort:** 8 hours
- **Deliverable:** Leaderboard and activity feed screens

### Wave 3: Integration + Widget (Days 13-18)

**T7. Spam Detection Service**
- Create `SpamDetectionService` with:
  - Text pattern matching (repeated characters, spam keywords)
  - Rate limiting per user
  - Duplicate phrase detection
  - Confidence scoring
- **Effort:** 4 hours
- **Deliverable:** Client-side spam detection

**T8. Share Intent Integration**
- Add Intent.ACTION_SEND handler to AndroidManifest
- Create `ShareManager` for sharing translations
- Implement share sheet with preview
- Support text and image sharing
- **Effort:** 4 hours
- **Deliverable:** Share integration

**T9. Home Screen Widget**
- Create Glance widget for quick translation
- Implement widget configuration (language selection)
- Implement widget tap → open app with translation screen
- Add widget refresh on translation
- **Effort:** 6 hours
- **Deliverable:** Home screen widget

---

## Dependency Graph

```
Wave 1:  T1 ─┬─ T2 ─┬─ T3
             │      │
             └──────┘ (T1 first, then T2+T3 parallel)

Wave 2:  T4 ─┬─ T5 ─┬─ T6
             │      │
             └──────┘ (T4 first, then T5+T6 parallel)

Wave 3:  T7 ─┬─ T8 ─┬─ T9
             │      │
             └──────┘ (T7+T8 parallel, then T9)
```

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Phrase browser loads in <1 second | Measure initial load time with 50 phrases |
| 2 | Phrase submission passes validation and appears in feed | Submit phrase → verify in community feed |
| 3 | Follow/unfollow, leaderboards, activity feed work | Test each social feature end-to-end |
| 4 | Spam detection flags >80% of test spam | Run 50 test spam submissions, measure detection |
| 5 | Share intent opens share sheet with text | Tap share → verify Android share sheet with pre-populated text |
| 6 | Widget launches translation screen | Tap widget → verify app opens to translation screen |
