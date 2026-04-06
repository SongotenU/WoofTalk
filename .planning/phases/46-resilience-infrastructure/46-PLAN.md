# Phase 46: Resilience Infrastructure - Plan

## Plans

### Plan 1: Circuit Breaker Pattern
**Type:** New infrastructure
**Description:** Create CircuitBreaker struct with closed/open/halfOpen states. Opens after 5 consecutive failures, half-open after 30s, closes on probe success. Used by AITranslationService.

### Plan 2: Retry with Exponential Backoff
**Type:** New infrastructure
**Description:** Add retry wrapper to AITranslationService with max 3 attempts, backoff starting at 250ms doubling each retry. Only retries transient errors.

### Plan 3: Timeout Enforcement
**Type:** Bug fix
**Description:** Wrap performAITranslation with async timeout (5 seconds). Throw inferenceTimeout if exceeded.

### Plan 4: Activate Retry Error Handler
**Type:** Integration
**Description:** Wire AITranslationErrorHandler into translate() flow. Use ErrorAction to decide retry vs fallback.

### Plan 5: Failure Threshold Detection
**Type:** Integration
**Description:** Track consecutive failures in CircuitBreaker. Open circuit when threshold (5) reached. Track and expose failure count.

## Execution Order

1. Plan 1 + Plan 5 (CircuitBreaker struct with threshold)
2. Plan 2 (Retry wrapper)
3. Plan 3 (Timeout enforcement)
4. Plan 4 (Wire error handler)

## Success Criteria

1. CircuitBreaker type exists with state machine and open/close logic
2. AITranslationService uses retry with backoff on transient errors
3. performAITranslation has async timeout
4. AITranslationErrorHandler is called in the translate flow
