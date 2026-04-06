# Phase 43: Memory Leak Elimination - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via autonomous mode, infrastructure phase)

<domain>
## Phase Boundary

Fix all known memory leaks in the iOS codebase before any other production hardening work. This phase targets:
- NotificationCenter observer leaks (no removeObserver in deinit)
- Timer leaks (no invalidate, no weak self)
- Core Data cache growth (no eviction, no fetchBatchSize)
- Verification of memory stability under extended use via Instruments

All fixes are iOS-only (Swift). Android, Web, AR, and VR are unaffected.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure/fix phase. Use REQUIREMENTS.md phase goal and codebase conventions to guide decisions.

### Known Leak Locations (from architecture research)
- `TranslationViewController.swift` — NotificationCenter observer, needs `deinit { NotificationCenter.default.removeObserver(self) }`
- `BatteryOptimizer.swift` — NotificationCenter observer leak
- `NetworkOptimizer.swift` — NotificationCenter observer leak, unimplemented `executeQueuedRequest()` placeholder
- `LeaderboardManager.swift` — Timer reference not stored, no `[weak self]`, no `invalidate()` call, needs `@MainActor` isolation
- `PerformanceOptimizer.swift` (`NetworkRequestBatcher`) — Timer leak

### Implementation Pattern
- Add `deinit` blocks with `NotificationCenter.default.removeObserver(self)` to all classes that add observers
- Store Timer references as instance properties, call `invalidate()` in deinit
- Add `[weak self]` captures in Timer closures
- Add `@MainActor` isolation where Timer callbacks touch UI

</decisions>

<code_context>
## Existing Code Insights

### Affected Files (known from research)
- `WoofTalk/TranslationViewController.swift`
- `WoofTalk/BatteryOptimizer.swift`
- `WoofTalk/NetworkOptimizer.swift`
- `WoofTalk/LeaderboardManager.swift`
- `WoofTalk/Performance/MemoryManager.swift`
- `WoofTalk/Performance/PerformanceOptimizer.swift`

### Verification Approach
- Build and compile — zero warnings
- Run under Xcode Instruments Memory Graph
- 1-hour continuous translation session — RSS stays stable <200MB

### Testing
- Existing test suite should pass after changes
- No new tests required for deinit/removeObserver (standard pattern)
- Timer fixes verifiable by code inspection (invalidate called, weak self used)

</code_context>

<specifics>
No additional specific requirements beyond the 4 LEAK requirements in REQUIREMENTS.md.
</specifics>

<deferred>
None — scope limited to memory leak elimination.
</deferred>
