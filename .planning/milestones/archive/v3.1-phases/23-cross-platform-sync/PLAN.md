# Phase 23: Cross-Platform Sync — Execution Plan

**Milestone:** v3.0 Platform Expansion
**Duration:** 3-4 weeks
**Prerequisites:** Phases 19-22 complete

---

## Goal

Implement cross-platform sync between iOS and Android — shared authentication, synced translation history, synced social graph, real-time activity feed, offline sync queue with conflict resolution.

---

## Requirements

| ID | Requirement |
|----|-------------|
| SYNC-01 | Shared auth: same credentials on iOS and Android, unified Supabase identity |
| SYNC-02 | Translation history synced across platforms within 5 seconds |
| SYNC-03 | Social graph (follows, blocks, leaderboards) synced across platforms |
| SYNC-04 | Real-time activity feed sync via Supabase Realtime |
| SYNC-05 | Offline-first sync queue with automatic replay on connectivity restore |
| SYNC-06 | Conflict resolution: last-write-wins for translations, merge for social graph |

---

## Task Breakdown

### Wave 1: Sync Infrastructure (Days 1-5)

**T1. Sync Manager**
- Create `SyncManager` orchestrating all sync operations
- Implement network connectivity monitoring
- Implement sync scheduling (periodic + event-driven)
- Implement sync status tracking
- **Effort:** 6 hours
- **Deliverable:** Central sync orchestration

**T2. Offline Write Queue**
- Create `OfflineWriteQueue` using Room for persistence
- Implement queue operations (enqueue, dequeue, mark complete)
- Implement retry with exponential backoff
- Implement queue size limits and eviction
- **Effort:** 6 hours
- **Deliverable:** Persistent offline write queue

**T3. Conflict Resolution**
- Create `ConflictResolver` with strategies:
  - Last-write-wins for translations
  - Merge for social graph (union of follows)
  - Max-wins for votes (upvotes/downvotes)
- Implement vector clock for ordering
- **Effort:** 6 hours
- **Deliverable:** Conflict resolution engine

### Wave 2: Data Sync (Days 6-10)

**T4. Translation History Sync**
- Implement bidirectional translation history sync
- Sync new translations from Android → Supabase
- Sync translations from Supabase → Android (including iOS-created)
- Handle conflicts with last-write-wins
- **Effort:** 6 hours
- **Deliverable:** Translation history cross-platform sync

**T5. Social Graph Sync**
- Implement follow relationship sync (merge strategy)
- Implement block relationship sync
- Implement leaderboard sync (server-authoritative)
- Handle concurrent follow/unfollow
- **Effort:** 6 hours
- **Deliverable:** Social graph cross-platform sync

### Wave 3: Realtime + Verification (Days 11-14)

**T6. Realtime Activity Feed**
- Implement Supabase Realtime subscription for activity events
- Handle real-time phrase approvals
- Handle real-time leaderboard updates
- Handle connection drops and reconnection
- **Effort:** 6 hours
- **Deliverable:** Real-time activity feed

**T7. Sync Verification**
- Create `SyncVerifier` for testing sync correctness
- Implement sync latency measurement
- Implement data consistency checks
- Create sync status dashboard UI
- **Effort:** 4 hours
- **Deliverable:** Sync verification tools

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Same account works on iOS and Android | Log in with same credentials, verify unified profile |
| 2 | Translation history syncs within 5 seconds | Create translation on iOS → verify on Android within 5s |
| 3 | Follow relationships sync across platforms | Follow on iOS → verify on Android |
| 4 | Activity feed updates in real-time (<1s) | Create event → verify appears on other platform within 1s |
| 5 | Offline changes sync on reconnect | Make changes offline → go online → verify sync |
| 6 | Conflicts resolve without data loss | Concurrent edits → verify correct resolution |
