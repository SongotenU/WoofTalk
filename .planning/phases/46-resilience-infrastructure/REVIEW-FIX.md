---
status: all_fixed
findings_in_scope: 2
fixed: 2
skipped: 0
iteration: 1
---

# Fix Report - Phase 46: resilience-infrastructure

## Summary
Fixed 2/2 WARNING-level findings.

## Fixes Applied

### [FIXED] WR-01: CircuitBreaker `currentState` not thread-safe
**File**: `WoofTalk/CircuitBreaker.swift`
**Fix**: Added `lock.lock()` / `defer { lock.unlock() }` around the `currentState` computed property to ensure thread-safe access to the `state` property.

### [FIXED] WR-02: Retry logic doesn't always call `circuitBreaker.onFailure()`
**File**: `WoofTalk/AITranslationService.swift`
**Fix**: Restructured `translate()` retry logic so that `circuitBreaker.onFailure()` is called when all retries are exhausted. Added clarification comment distinguishing between deterministic failures (`.showErrorToUser`) and retryable failures.

## Skipped Issues
None.

---
_Fixed: 2026-04-30_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
