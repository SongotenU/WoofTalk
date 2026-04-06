# Phase 26: Web Voice & Community — Execution Plan

**Phase:** 26 — Web Voice & Community
**Created:** 2026-03-31
**Status:** Ready for execution

---

## Plan 1: Voice Input (Web Speech API)

**Goal:** Add SpeechRecognition to the translate page for voice input with graceful degradation.

**Files to create:**
- `web/src/hooks/useSpeechRecognition.ts` — Custom hook wrapping SpeechRecognition API
- `web/src/components/VoiceInput.tsx` — Mic button + waveform UI component

**Files to modify:**
- `web/src/app/translate/page.tsx` — Integrate VoiceInput component

**Success criteria:**
- [ ] Mic button appears on translate page
- [ ] Clicking mic starts speech recognition
- [ ] Recognized text populates input field
- [ ] Visual feedback during recording (pulsing indicator)
- [ ] Graceful degradation when SpeechRecognition unavailable (button hidden)

---

## Plan 2: Voice Output (SpeechSynthesis)

**Goal:** Add SpeechSynthesis TTS for reading translations aloud with configurable speed/pitch.

**Files to create:**
- `web/src/hooks/useSpeechSynthesis.ts` — Custom hook wrapping SpeechSynthesis API
- `web/src/components/VoiceOutput.tsx` — Speaker button component

**Files to modify:**
- `web/src/app/translate/page.tsx` — Integrate VoiceOutput component
- `web/src/app/settings/page.tsx` — Add voice speed/pitch controls

**Success criteria:**
- [ ] Speaker button appears next to translation result
- [ ] Clicking speaker reads translation aloud
- [ ] Speed and pitch configurable in settings
- [ ] Visual feedback while speaking (animated icon)

---

## Plan 3: Community Phrase Browser

**Goal:** Build `/community` page with phrase browsing, search, filter, and pagination.

**Files to create:**
- `web/src/app/community/page.tsx` — Community phrase browser page
- `web/src/components/PhraseCard.tsx` — Reusable phrase card component
- `web/src/components/SearchFilterBar.tsx` — Search + filter component
- `web/src/lib/supabase.ts` — Extend with community phrase CRUD operations

**Success criteria:**
- [ ] `/community` route loads approved phrases from Supabase
- [ ] Card grid layout (responsive: 1→2→3 columns)
- [ ] Search bar filters phrases in real-time
- [ ] Filter chips for language (Dog/Cat/Bird)
- [ ] Sort by upvotes/newest/trending
- [ ] Loading skeletons during fetch
- [ ] Empty state with CTA

---

## Plan 4: Phrase Contribution & Spam Detection

**Goal:** Modal form for submitting new phrases with client+server validation and spam detection.

**Files to create:**
- `web/src/components/ContributePhraseModal.tsx` — Modal submission form
- `web/src/lib/spamDetection.ts` — Port Android SpamDetectionService to TypeScript
- `web/src/app/api/validate-phrase/route.ts` — Edge Function for server-side validation

**Success criteria:**
- [ ] "Contribute Phrase" button opens modal dialog
- [ ] Form validates required fields in real-time
- [ ] Spam detection runs on submit (client-side)
- [ ] Server-side validation via Edge Function
- [ ] Success toast on submission
- [ ] Modal closes on success

---

## Plan 5: Social Features

**Goal:** Build `/social` page with activity feed, follow/unfollow, and leaderboards.

**Files to create:**
- `web/src/app/social/page.tsx` — Social features page with tabs
- `web/src/components/ActivityFeed.tsx` — Real-time activity feed
- `web/src/components/Leaderboard.tsx` — Top contributors leaderboard
- `web/src/components/UserFollowCard.tsx` — User card with follow/unfollow
- `web/src/lib/supabase.ts` — Extend with social operations (follow, activity, leaderboard)

**Success criteria:**
- [ ] `/social` route loads with tabs: Activity, Followers, Leaderboard
- [ ] Activity feed shows recent actions in real-time
- [ ] Follow/unfollow buttons update optimistically
- [ ] Leaderboard ranks users by contribution score
- [ ] Top 3 highlighted with medals

---

## Plan 6: Cross-Platform Sync

**Goal:** Ensure real-time sync of translations, community phrases, and social data across platforms.

**Files to create:**
- `web/src/lib/sync.ts` — Supabase Realtime channel subscriptions
- `web/src/hooks/useSyncStatus.ts` — Hook for sync status indicator

**Files to modify:**
- `web/src/lib/supabase.ts` — Add Realtime channel setup
- `web/src/app/layout.tsx` — Add sync status indicator

**Success criteria:**
- [ ] Supabase Realtime channels subscribed to translations, community_phrases, social tables
- [ ] New translations from other platforms appear within 5 seconds
- [ ] Community phrase updates propagate in real-time
- [ ] Offline changes queue to localStorage and sync on reconnect
- [ ] Sync status indicator visible in nav

---

## Plan 7: Settings — Voice Controls

**Goal:** Add voice speed and pitch controls to the settings page.

**Files to modify:**
- `web/src/app/settings/page.tsx` — Add voice section with sliders

**Success criteria:**
- [ ] Speed slider (0.5x–2x, default 1.0)
- [ ] Pitch slider (0.5–2.0, default 1.0)
- [ ] Settings persist in localStorage
- [ ] Preview button to test voice settings
