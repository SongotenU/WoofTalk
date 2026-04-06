# Architecture: M008 Production Hardening

**Domain:** Scale testing, performance optimization, and tech debt cleanup
**Researched:** 2026-04-04
**Extends:** Existing architecture from M001-M007 (6 platforms, Supabase backend with 8 tables, 30+ RLS policies, 6 Edge Functions, Upstash Redis)

## Integration Points with Existing Systems

### Tech Debt Items and Their Integration Boundaries

| # | Tech Debt Item | Files Affected | Platform | Integration Boundary |
|---|---------------|----------------|----------|---------------------|
| 1 | Duplicate audio_processing/ | `WoofTalk/audio_processing/` (10 files, ~1,166 lines) vs `WoofTalk/AudioProcessing/` (8 files, ~1,756 lines) | iOS only | Both directories coexist in the same Xcode target -- must delete snake_case version and verify PascalCase version is referenced |
| 2 | TranslationCache unused | `TranslationCache.swift` exists; `TranslationEngine.swift` never calls `getCachedTranslation()` or `cacheTranslation()` | iOS only | Add 2 lines to TranslationEngine (check cache before compute, store result after compute) |
| 3 | LanguageDetectionManager O(n2) | `LanguageDetectionManager.swift` -- `analyzeFrequencies()` loops bins x languages, `performLanguageDetection()` loops frequencies x languages | iOS only | Pre-compute frequency-to-language map at init, reduce to O(n) |
| 4 | Missing retry + circuit breaker | `AITranslationErrorHandler.swift` (.retry exists but never returned), `RealTranslationController.swift` (no circuit breaker) | iOS + Supabase Edge Functions | Implement circuit breaker on client; add retry to error handler for transient errors |
| 5 | NotificationCenter/Timer leaks | `TranslationViewController.swift`, `BatteryOptimizer.swift`, `NetworkOptimizer.swift`, `LeaderboardManager.swift`, `PerformanceOptimizer.swift` | iOS only | Add `deinit { removeObserver(self) }`, store timer refs, invalidate on completion |

### Cross-Platform Impact

```
iOS (Swift/iOS)     -- All 5 tech debt items are iOS-only. No Android/Web/AR/VR changes required.
Android (Kotlin)   -- No direct impact. Pattern should be mirrored in Android translation layer.
Web (Next.js)       -- No direct impact. Web Speech API path does not use these Swift classes.
AR (Vision Pro)     -- AR app uses separate TranslationService.swift, shares same TranslationEngine pattern.
VR (Quest/Unity)    -- Unity C# translation pipeline is independent.
Supabase (Backend) -- Edge Functions unchanged for items 1-3, 5. Item 4 could add retry middleware.
```

### Scale Testing Integration Points

| System | Current | Scaled Target | Integration Method |
|--------|---------|---------------|-------------------|
| Supabase Edge Functions | 6 functions, no circuit breaker on client | Handle burst traffic from 6 platforms | Load test via k6/Artillery against existing `/translate`, `/phrases-search`, `/leaderboard`, `/activity-batch` endpoints |
| Upstash Redis rate limiting | Fixed window 100 req/60s per user on translate | Validate limits under concurrent load | Test rate-limit.ts under 100+ concurrent clients |
| PostgreSQL tables | 8 tables, 30+ RLS policies | Validate RLS correctness under load | Concurrent user tests with different org_id contexts |
| iOS memory footprint | Multiple leaks detected | Stable RSS under extended translation sessions | Instruments Memory Graph + Leaks profiling |
| Core Data | Unbounded cache growth, no fetchBatchSize | Predictable memory with eviction policies | Xcode Performance Tools |

### What Needs to Be Modified vs New vs Removed

#### Removed (delete/dead code cleanup)

- `WoofTalk/audio_processing/` directory -- 10 files, ~1,166 lines of duplication with `WoofTalk/AudioProcessing/`. Must verify Xcode project file references before deletion.
- Duplicate `TranslationDirection` enum -- defined in both `TranslationEngine.swift` and `AITranslationService.swift`. Consolidate to shared `TranslationModels.swift`.
- `AITranslationErrorHandler.ErrorAction.retry` dead case -- exists but never returned; will be activated as part of circuit breaker implementation (not deleted, repurposed).
- `legacyDirection` variable in `MultiLanguageAdapter.swift` -- vestigial naming, refactor.

#### Modified (existing code)

| File | What Changes | Risk |
|------|-------------|------|
| `TranslationEngine.swift` | Add `TranslationCache.shared.getCachedTranslation()` check before ML/vocabulary lookup; add `cacheTranslation()` after successful translation | LOW (additive pattern, no behavioral change for cache miss) |
| `LanguageDetectionManager.swift` | Replace nested `for bin in frequencies { for language in AnimalLanguage.allCases { ... } }` with pre-computed frequency-bin-to-language dictionary. O(n x m) becomes O(n). | MEDIUM (audio hot path -- must validate accuracy parity) |
| `AITranslationErrorHandler.swift` | Return `.retry` for `.inferenceTimeout` and `.translationFailed`; implement exponential backoff in calling code | MEDIUM (changes error handling flow -- must add retry limit) |
| `TranslationViewController.swift` | Add `deinit { NotificationCenter.default.removeObserver(self) }` | LOW (no behavioral impact) |
| `LeaderboardManager.swift` | Store Timer reference, add `[weak self]`, call `invalidate()` on completion. Add `@MainActor` isolation. | LOW (correctness fix) |
| `BatteryOptimizer.swift` | Add `deinit { removeObserver(self) }` | LOW |
| `NetworkOptimizer.swift` | Add `deinit { removeObserver(self) }`. Implement `executeQueuedRequest()` -- currently a placeholder. | MEDIUM (makes offline queue functional for the first time) |
| `PerformanceOptimizer.swift` (`NetworkRequestBatcher`) | Replace sequential `for request in batch { await performRequest(request) }` with `TaskGroup` parallel execution | LOW |
| `TranslationCache.swift` | Auto-call `evictOldEntries()` when cache exceeds threshold. Add TTL-based expiry. Fix synchronous `Data(contentsOf:)` to async. | MEDIUM (first-time eviction behavior could cause cache miss spikes) |
| `Settings.swift` | Load all `UserDefaults` reads into memory at init, write lazily (debounced or app-background) | LOW |
| `SpamDetectionService.swift` | Convert `suspiciousPhrases` linear scan to Set/regex-based lookup | LOW |
| `AudioTranslationBridge.swift` | Replace `result += word + " "` (O(n2)) with `.joined(separator: " ")` | LOW |
| `LatencyMonitor.swift` | Replace `.sorted()` percentile calculation with quickselect | LOW |
| `RealTranslationController.swift` | Add circuit breaker pattern around AI translation calls. Add timeout (30s) to `await`. | MEDIUM (circuit breaker is new runtime state) |
| `OfflineTranslationManager.swift` | Replace silent `catch { }` with error logging + retry queue | MEDIUM (changes behavior for edge cases) |

#### New (additional code/infrastructure)

| Component | Purpose | Where |
|-----------|---------|-------|
| `CircuitBreaker.swift` | Stateful circuit breaker (closed/open/half-open) for AI translation. Tracks consecutive failures, opens after N failures, half-opens after X seconds | iOS |
| `RetryWithBackoff.swift` | Exponential backoff helper (maxAttempts=3, base=1s, max=30s) for transient errors | iOS |
| Scale test suite (k6) | Load tests for Supabase Edge Functions: /translate burst, /leaderboard pagination, /activity-batch throughput | Backend testing |
| Scale test suite (Swift) | Instruments automation: memory stability during 1-hour continuous translation session, AudioEngine lifecycle tests | iOS testing |
| RLS concurrency tests | 50 concurrent users with different org_id values, verify zero cross-org data leakage | Backend testing |
| `os_log` structured logging | Replace `print("Error...")` across 19 files with `os_log` subsystem | iOS |

## Suggested Build/Execution Order

The tech debt items have dependency relationships. The build order must respect these dependencies to avoid cascading failures and to maximize measurable impact early.

### Phase Ordering with Dependency Rationale

```
                    ┌──────────────────────────────────────────┐
                    │   PHASE 1: Safety First (Memory Leaks)   │
                    │  Items: NotificationCenter + Timer fixes │
                    │  Why: Unbounded leaks prevent accurate     │
                    │  measurement of all other performance     │
                    │  improvements. Must be clean first.       │
                    └─────────────────────┬────────────────────┘
                                          │
                            Must complete first because leaks
                            corrupt memory baselines for ALL
                            subsequent measurements
                                          │
                    ┌─────────────────────┴────────────────────┐
                    │   PHASE 2: Structural Cleanup            │
                    │  Items: Delete duplicate audio_processing/ │
                    │         Deduplicate TranslationDirection  │
                    │         Fix AudioTranslationBridge O(n2)   │
                    │  Why: Reduces binary surface area,        │
                    │       eliminates runtime conflicts         │
                    └─────────────────────┬────────────────────┘
                                          │
                     Must complete before LanguageDetection
                     changes because AudioProcessor classes
                     may be referenced by both directories
                                          │
                    ┌─────────────────────┴────────────────────┐
                    │  PHASE 3: Performance Hot-Path Fixes     │
                    │  Items: Connect TranslationCache          │
                    │         Fix LanguageDetectionManager O(n2) │
                    │         Fix TranslationCache eviction     │
                    │         Fix Settings UserDefaults I/O     │
                    │  Why: Biggest measurable performance wins │
                    │       80-90% reduction in repeated        │
                    │       translation latency, 10-50x in      │
                    │       audio frame processing              │
                    └─────────────────────┬────────────────────┘
                                          │
                   TranslationCache must be connected BEFORE
                   circuit breaker testing (circuit breaker
                   should count cache hits as success, not
                   only API responses)
                                          │
                    ┌─────────────────────┴────────────────────┘
                    │   PHASE 4: Resilience Infrastructure      │
                    │  Items: CircuitBreaker, RetryWithBackoff  │
                    │         Implement ErrorAction.retry       │
                    │         RealTranslationController timeout  │
                    │         OfflineTranslationManager fix      │
                    │         NetworkOptimizer queue execution  │
                    │  Why: New infrastructure that depends on  │
                    │       clean baselines from phases 1-3    │
                    └─────────────────────┬────────────────────┘
                                          │
                   Resilience must be in place before
                   scale testing so load tests measure
                   production-ready behavior
                                          │
                    ┌─────────────────────┴────────────────────┘
                    │   PHASE 5: Quality of Life (Medium/Low)   │
                    │  Items: LatencyMonitor quickselect        │
                    │         Analytics try? fixes              │
                    │         AudioEngine deinit cleanup        │
                    │         Core Data fetch optimization      │
                    │         PerformanceOptimizer parallelism  │
                    │         print -> os_log                   │
                    └─────────────────────┬────────────────────┘
                                          │
                   Quality improvements that don't block
                   scale testing but should ship before
                   production launch
                                          │
                    ┌─────────────────────┴────────────────────┘
                    │   PHASE 6: Scale Testing                  │
                    │  Items: k6 Edge Function load tests       │
                    │         Instruments memory profiling      │
                    │         RLS concurrency verification      │
                    │         End-to-end regression suite       │
                    │  Why: Validates all prior work under      │
                    │       production-like load                │
                    └──────────────────────────────────────────┘
```

### Detailed Phase Breakdown

#### Phase 1: Memory Leak Elimination (1-2 days)

**Goal:** Establish a clean memory baseline. No valid performance measurement is possible with active leaks.

| Item | File(s) | Change | Verification |
|------|---------|--------|--------------|
| NotificationCenter leak in TranslationViewController | `TranslationViewController.swift` | Add `deinit { NotificationCenter.default.removeObserver(self) }` | Instruments: dismiss and dismiss 50 times, RSS unchanged |
| NotificationCenter leak in BatteryOptimizer | `Performance/BatteryOptimizer.swift` | Add `deinit` cleanup | Same |
| NotificationCenter leak in NetworkOptimizer | `Performance/NetworkOptimizer.swift` | Add `deinit` cleanup | Same |
| Timer leak in LeaderboardManager | `LeaderboardManager.swift` | Store timer, add `[weak self]`, `invalidate()` on completion | Instruments: no Timer objects persist after deallocation |
| Timer leak in PerformanceOptimizer | `PerformanceOptimizer.swift` (`NetworkRequestBatcher`) | Store `batchTimer`, add `[weak self]` cleanup | Same |
| Add `@MainActor` to singletons | `LeaderboardManager.swift` | Class-level `@MainActor` annotation | Swift concurrency warnings disappear |
| AVAudioEngine deinit cleanup | All files with AVAudioEngine | Add `audioEngine.stop()` in `deinit` | Instruments Audio: no zombie audio sessions |

**Exit criteria:** Xcode Instruments shows flat memory graph during 30-minute translation session. No growing object counts for NotificationCenter observers or Timer objects.

#### Phase 2: Structural Cleanup (1-2 days)

**Goal:** Remove duplicate code and consolidate single sources of truth.

| Item | Files | Change | Verification |
|------|-------|--------|--------------|
| Delete duplicate audio_processing/ | `audio_processing/` (10 files) | Remove entire directory, verify Xcode project has no dangling references | Xcode builds without warnings, AudioProcessing/ version works |
| Deduplicate TranslationDirection | `TranslationEngine.swift`, `AITranslationService.swift` | Move to shared `TranslationModels.swift` | Single import site, no compiler errors |
| Fix AudioTranslationBridge O(n2) | `AudioTranslationBridge.swift` | Replace string concatenation with `.joined(separator: " ")` | Benchmark: 10K word translation completes in <50ms |
| Clean up legacyDirection naming | `MultiLanguageAdapter.swift` | Rename to `normalizedDirection` | N/A (cosmetic) |

**Exit criteria:** `wc -l` on `audio_processing/` returns 0. Xcode builds clean. No runtime behavior changes.

#### Phase 3: Performance Hot-Path Fixes (3-4 days)

**Goal:** Close the biggest performance gaps with measurable latency reductions.

| Item | File(s) | Change | Expected Improvement |
|------|---------|--------|---------------------|
| Connect TranslationCache to TranslationEngine | `TranslationEngine.swift` | Add `if let cached = TranslationCache.shared.getCachedTranslation(...) { return cached }` before ML lookup; `TranslationCache.shared.cacheTranslation(...)` after successful translation | 80-90% faster repeated translations |
| Fix LanguageDetectionManager O(n2) | `LanguageDetectionManager.swift` | Pre-compute `{ frequency_range: AnimalLanguage }` dictionary at init. Single-pass bin lookup. | 10-50x faster audio frame processing |
| Fix TranslationCache unbounded growth | `TranslationCache.swift` | Call `evictOldEntries()` when `cache.count > maxEntries`. Add TTL check to `getCachedTranslation()`. | Stable memory footprint, never exceeds maxEntries |
| Fix synchronous cache I/O | `TranslationCache.swift` | Replace `Data(contentsOf:)` with async file I/O | No UI freeze on cache load |
| Fix Settings UserDefaults I/O | `Settings.swift` | Load all into memory at init. Debounce writes. Batch on `willTerminate` | Eliminate 10-50ms per-read disk I/O |
| Fix TranslationEngine instance creation | `AITranslationService.swift` | Replace `let engine = TranslationEngine()` with `private let fallbackEngine` | Eliminate per-call allocation overhead |
| Fix SpamDetectionService | `SpamDetectionService.swift` | Replace linear scan with Set-based lookup | 5-10x faster spam detection |
| Fix multiple .filter.count passes | `QualityMetricsCollector.swift`, `AutoModerationService.swift`, `AbuseReportingManager.swift`, `ModerationAnalyticsView.swift` | Single-pass `reduce(into:)` with dictionary counter | 3-8x reduction in iterations |

**Exit criteria:** LatencyMonitor shows P50 translation latency <1s, P95 <2s. Instruments shows TranslationCache hit rate >60% after warmup. LanguageDetectionManager processes audio frame in <5ms.

#### Phase 4: Resilience Infrastructure (3-4 days)

**Goal:** Implement retry + circuit breaker for AI translation. This is new code, not fixes.

| Item | Files | Implementation Details |
|------|-------|----------------------|
| CircuitBreaker | New file: `CircuitBreaker.swift` | State machine: CLOSED (normal) -> OPEN (after 5 failures) -> HALF_OPEN (after 30s) -> test request -> CLOSED or back to OPEN. Concurrent-safe with `NSLock`. Exposes `canExecute()` and `recordSuccess()/recordFailure()`. |
| RetryWithBackoff | New file: `RetryWithBackoff.swift` | `func retry<T>(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 30.0, operation: () async throws -> T) async throws -> T`. Uses `Task.sleep(nanoseconds:)`. Stops early on success. |
| AITranslationErrorHandler activation | `AITranslationErrorHandler.swift` | `.inferenceTimeout` and `.translationFailed` return `.retry` instead of immediate fallback. Caller implements circuit breaker + retry. |
| RealTranslationController resilience | `RealTranslationController.swift` | Wrap AI translation call in circuit breaker. Add `withTimeout(seconds: 30)` wrapper. Retry with backoff for transient errors before falling back to rule-based. |
| OfflineTranslationManager error handling | `OfflineTranslationManager.swift` | Replace `catch { }` with `os_log` + add items to retry queue with exponential backoff. |
| NetworkOptimizer queue execution | `Performance/NetworkOptimizer.swift` | Implement `executeQueuedRequest()` -- currently a no-op placeholder. Use TaskGroup for parallel execution with circuit breaker awareness. |

**Exit criteria:** Circuit breaker opens after 5 consecutive failures. Half-open test recovers when service is restored. Retry with backoff handles transient 429/500 errors gracefully. No cascading failures under continuous error conditions.

#### Phase 5: Quality of Life (2-3 days)

**Goal:** Medium and low priority improvements for production-grade quality.

| Item | Files | Change |
|------|-------|--------|
| LatencyMonitor quickselect | `LatencyMonitor.swift` | Replace `.sorted()` with O(n) quickselect for P50/P95/P99 |
| Analytics try? fixes | `PerformanceMonitor.swift`, `UsageAnalyticsTracker.swift`, `QualityMetricsCollector.swift`, `AnalyticsEventStore.swift` | Replace `try?` with `do/catch` + `os_log` + in-memory fallback |
| NetworkOptimizer parallel batch | `PerformanceOptimizer.swift` | Replace sequential batch flush with `withTaskGroup` |
| Core Data fetch optimization | `CommunityPhraseCacheManager.swift` and others | Add `fetchBatchSize`, `returnsObjectsAsFaults` to all fetch requests |
| print -> os_log | 19 files | Replace `print("Error...")` with `os_log` subsystem |
| TranslationCache Unicode normalization | `TranslationCache.swift` | Add `.folding(options: .canonical, locale: .current)` to cache key generation |
| ContributionManager save safety | `ContributionManager.swift` | Replace `try? save()` with proper error handling |
| SocialGraphManager guard logging | `SocialGraphManager.swift` | Add `os_log` when userID guard fails |

**Exit criteria:** No `print()` statements in production code. No `try?` swallowing errors. Structured os_log output visible in Console.app. All Core Data fetch requests batched.

#### Phase 6: Scale Testing (3-5 days)

**Goal:** Validate all prior work under production-like load. No code to write on the client -- this is test infrastructure.

**A. Backend Scale Testing (k6/Artillery)**

| Test | Target | Parameters | Pass Criteria |
|------|--------|-----------|---------------|
| Translate endpoint burst | `POST /translate` | 100 concurrent users, 1000 req/min, 5 min duration | 99th latency <3s, 0% error rate, no 500s |
| Rate limiting validation | All Edge Functions | 200 concurrent clients, 10x normal rate | 429 responses at threshold, no bypass |
| RLS isolation | All table queries | 50 concurrent users across 5 organizations | Zero cross-organization data leakage |
| Leaderboard performance | `GET /leaderboard` | 200 concurrent reads with complex ordering | P95 <500ms |
| Activity batch throughput | `POST /activity-batch` | 50 concurrent batch writes (50 events each) | 99% success rate |
| Simulated multi-platform load | All 6 endpoints | 100 users across 6 platform headers | Proportional distribution, no platform starvation |

**B. iOS-Specific Scale Testing (Xcode Instruments + Custom)**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| Memory stability | Instruments: Run 60-min continuous translation session with repeated text | RSS stays within 20% of baseline. No growing objects. |
| AudioEngine lifecycle | Instruments Audio: Create/destroy AudioEngine 100x | No zombie audio sessions. All sessions properly deallocated. |
| Core Data fetch patterns | Instruments Core Data: Scroll through 1000 translation history entries | No full-table fetches. All requests use batch size. |
| Translation cache warmup | Custom test: Translate 50 unique phrases, then repeat | Second pass shows >60% cache hit rate. P50 <200ms on cached lookups. |
| Circuit breaker behavior | Custom test: Simulate 10 consecutive AI failures | Circuit opens after 5, retries after 30s, graceful fallback active |
| Timer cleanup verification | Custom test: Start/stop LeaderboardManager 100x | Zero Timer objects in heap after all stops |
| Low memory mode | Instruments Memory Pressure: Simulate critical memory pressure on device | All LRU caches cleared. App remains responsive. Graceful degradation. |

**C. Android/Kotlin Mirror Testing**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| Room database scale | Benchmark: 10K phrase insert + query | Query <50ms, no ANR |
| Concurrent sync | 5 simultaneous sync workers | No race conditions, data consistent |

**D. End-to-End Regression**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| Cross-platform sync | Translate on iOS -> verify sync to Android, Web, AR, VR | History appears on all platforms within 5s |
| Offline recovery | Disconnect network, translate, reconnect | Pending translations sync on reconnect |
| AR/VR platform sync | Create translation history in AR, verify on mobile | platform=ar_vision record exists, spatial_position preserved |

**Exit criteria for M008:**
- All 6 scale test suites pass
- No memory leaks in 60-minute session
- P95 translation latency <3s for AI, <200ms for cached
- Circuit breaker tested and verified (open, half-open, recovery)
- Zero cross-tenant data leakage
- Binary size reduced by ~50KB (duplicate removal)
- Translation cache hit rate >60%

## Scale Testing Approach

### Infrastructure

```
Scale Test Orchestrator
    |
    ├── k6 (backend load testing)
    │   ├── supabase_load_tests/
    │   │   ├── translate_burst.js     -- 100 concurrent users
    │   │   ├── rate_limit_test.js     -- burst beyond limits
    │   │   ├── rls_isolation.js       -- cross-org verification
    │   │   ├── leaderboard_perf.js    -- heavy read load
    │   │   └── activity_batch.js      -- concurrent batch writes
    │   └── results/
    │       └── reports/ (generated JSON/HTML)
    |
    ├── Xcode Instruments Automation
    │   ├── mem_stability.dtx           -- template for memory profiling
    │   ├── audio_lifecycle.dtx         -- AudioEngine lifecycle
    │   └── core_data_patterns.dtx      -- fetch pattern analysis
    |
    └── Custom Swift Test Harness
        ├── CircuitBreakerTests.swift
        ├── TranslationCacheWarmupTests.swift
        ├── RLSConcurrencyTests.swift
        └── CrossPlatformSyncTests.swift
```

### k6 Script Template

Each k6 test targets existing Supabase Edge Functions. The translate function endpoint is `https://<project>.functions.supabase.co/translate`. Tests use service role key for authenticated requests (not suitable for production -- use test-specific keys).

**Key k6 metrics to track:**
- `http_req_duration` -- P50, P95, P99 latency per endpoint
- `http_req_failed` -- error rate
- `iterations` -- throughput
- `vus` -- concurrent virtual users
- Custom: `circuit_breaker_state` -- OPEN/CLOSED/HALF_OPEN transitions

### Regression Guardrails

| Guardrail | How | When |
|-----------|-----|------|
| No memory regression | Instruments compare baseline RSS vs post-fix RSS | After each phase |
| No latency regression | LatencyMonitor reports, k6 P95 < baseline | After phases 3, 4 |
| No functional regression | Existing XCTest suite (MultiLanguageTests, OfflineModeTests, ContributionValidationTests) | After every phase |
| No RLS regression | RLS concurrency test (50 concurrent, cross-org) | After phase 6 |
| Binary size decrease | `ls -l WoofTalk.app` comparison | After phase 2 |

## Performance Optimization Strategy

### Optimization Principles

1. **Measure first, fix second** -- Every performance item was already measured in the OPTIMIZATION_AUDIT.md. Validate baselines before applying changes.
2. **Fix leaks before optimizing** -- Phase 1 eliminates memory leaks first. Optimizing code that leaks is pointless.
3. **Hot path priority** -- TranslationEngine -> TranslationCache (80-90% improvement) and LanguageDetectionManager O(n2) fix (10-50x improvement) yield the most user-visible latency reduction.
4. **Resilience before scale** -- Circuit breaker and retry must exist before load testing. Load testing without circuit breaker will hammer a failing service.
5. **Structured logging everywhere** -- Replace `print()` with `os_log` before production launch to enable debugging in the wild.

### Performance Budget

| Metric | Target | Current (estimated) | After fixes |
|--------|--------|---------------------|-------------|
| P50 translation latency | <500ms | ~1500ms (cold), ~800ms (warm) | <200ms (cached), <500ms (cold) |
| P95 translation latency | <2s | ~3s+ (with failures) | <2s (circuit breaker prevents cascade) |
| Audio frame processing | <5ms | Variable (O(n2) nested loop) | <1ms (O(n) dictionary lookup) |
| Memory after 60 min session | <200MB RSS | Unbounded (leaks) | Stable <200MB |
| Cache hit rate (warm session) | >60% | 0% (unused) | >60% |
| API retry recovery | ~30% of transient failures | 0% (immediate fallback) | ~30% recovered via retry |
| Binary size reduction | -50KB | Baseline | -50KB (duplicate removal) |

### Cache Hierarchy

```
User Request
    |
    v
┌─────────────────────────────┐
│  MemoryLRUCache (MemoryManager) │ <-- Phase 3: already exists
│  100 entry translation cache    │
│  50 quality score cache         │
│  200 language detection cache   │
└──────┬──────────────────────┘
       │ MISS
       v
┌─────────────────────────────┐
│  TranslationCache.swift      │ <-- Phase 3: now connected
│  Dictionary-based, disk-backed │
│  Auto-evict >10K entries      │
│  TTL-based expiry             │
└──────┬──────────────────────┘
       │ MISS
       v
┌─────────────────────────────┐
│  AITranslationService        │
│  Core ML model inference      │
│  With circuit breaker         │ <-- Phase 4: new resilience
└──────┬──────────────────────┘
       │ FAILURE
       v
┌─────────────────────────────┐
│  TranslationEngine           │
│  Vocabulary DB + rule-based   │
│  (existing fallback)          │
└─────────────────────────────┘
```

### Circuit Breaker State Machine

```
            5 consecutive failures
CLOSED ──────────────────────────────────> OPEN
  │                                          │
  │  (normal operation)                      │ After 30s cooldown
  │  records:                                │
  │  - success:  reset counter               │
  │  - failure:  increment counter           │
  v                                          v
                                     HALF_OPEN
                                        │
                   ┌────────────────────┤────────────────────┐
                   │                    │                    │
            test request           test request         test request
            SUCCESS                FAILURE              TIMEOUT
                   │                    │                    │
                   v                    v                    v
                CLOSED               OPEN                (retry OPEN)
           (normal ops)        (30s cooldown)          (30s cooldown)
```

**Configuration for M008:**
- `failureThreshold = 5` -- open after 5 consecutive failures
- `cooldownDuration = 30` seconds
- `maxRetries = 3` with exponential backoff (1s, 2s, 4s)
- `failureTimeout = 30` seconds (max time for a request to count as failed)

## Sources

- `.planning/reports/OPTIMIZATION_AUDIT.md` -- 34 findings from 7 parallel specialist agents, 2026-03-31
- `WoofTalk/TranslationEngine.swift` -- examined translation path, cache usage (unused)
- `WoofTalk/TranslationCache.swift` -- examined cache implementation, disk persistence
- `WoofTalk/LanguageDetectionManager.swift` -- examined O(n2) nested loops, frequency analysis
- `WoofTalk/AITranslationService.swift` -- examined AI translation, fallback pattern
- `WoofTalk/AITranslationErrorHandler.swift` -- examined error handling, dead retry case
- `WoofTalk/Performance/MemoryManager.swift` -- examined LRU cache, memory pressure handling
- `WoofTalk/PerformanceOptimizer.swift` -- examined NetworkRequestBatcher timer leak
- `WoofTalk/LatencyMonitor.swift` -- examined percentile calculation
- `WoofTalk/NotificationManager.swift` -- examined notification patterns
- `supabase/functions/translate/index.ts` -- examined backend rate limiting
- `supabase/functions/_shared/rate-limit.ts` -- examined Upstash rate limiting
- `.planning/research/ARCHITECTURE.md` -- existing M007 architecture for integration mapping
- `.planning/research/STACK.md` -- existing technology stack across all 6 platforms
- `.planning/MILESTONES.md` -- M007 completion status
- `.planning/ROADMAP.md` -- completed milestone history (M001 through M007)

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Tech debt identification | HIGH | Directly verified in source code + OPTIMIZATION_AUDIT.md |
| Integration points | HIGH | Read all affected Swift files, confirmed platform boundaries |
| Build order | HIGH | Dependencies verified through reading actual code (TranslationEngine doesn't call TranslationCache, audio_processing/ exists alongside AudioProcessing/) |
| Scale testing approach | MEDIUM | k6 patterns standard, but specific Supabase limits depend on project tier |
| Circuit breaker design | MEDIUM | Standard pattern, exact thresholds need validation with real traffic |
| Performance budgets | MEDIUM | Estimated from audit findings, needs empirical verification |
| Android scale testing | LOW | Android code not directly read, assumed similar patterns |
