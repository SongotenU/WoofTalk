---
estimated_steps: 8
estimated_files: 3
---

# T02: Offline Manager Core

**Slice:** S04 — Offline Mode
**Milestone:** M001

## Description

Implement the core offline manager that handles connectivity detection, translation caching, and fallback logic. This is the central component that determines when to use cached translations versus online services.

## Steps

1. Research iOS network reachability APIs and Node.js network detection
2. Create `connectivity_manager.ts` with online/offline detection logic
3. Implement offline detection using network status and cached data availability
4. Create `offline_manager.ts` with core translation caching logic
5. Implement cache storage/retrieval for translation phrases
6. Add fallback behavior for missing phrases in offline mode
7. Implement storage limits and cleanup strategies
8. Add cache invalidation and freshness tracking

## Must-Haves

- Reliable online/offline detection with minimal false positives
- Fast cache lookup for translation phrases (sub-100ms target)
- Graceful fallback when phrases are missing in offline mode
- Storage usage stays within reasonable limits (target: <5MB)
- Cache invalidation prevents stale translations from being used

## Verification

- Offline detection correctly identifies network status changes
- Cached translations are returned when offline
- Fallback behavior provides meaningful responses for missing phrases
- Storage limits are enforced and cleanup works
- Cache invalidation respects freshness requirements

## Observability Impact

- Signals added: Online/offline status, cache hit/miss ratios, storage usage
- How a future agent inspects this: Debug logs, storage usage reports, cache statistics
- Failure state exposed: Detection failures, cache misses, storage errors

## Inputs

- SQLite database implementation from T01
- Network reachability APIs from iOS/Speech Framework research
- Translation data structure from S02
- Storage constraints from research

## Expected Output

- `offline_manager/connectivity_manager.ts` — Network status detection
- `offline_manager/offline_manager.ts` — Core offline translation logic
- Integration with SQLite database for phrase storage
- Test suite covering online/offline scenarios