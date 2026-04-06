# Phase 46: Resilience Infrastructure - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase)

<domain>
## Phase Boundary

Add circuit breaker, retry with backoff, timeout enforcement, and failure threshold detection to the AI translation pipeline.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices at Claude's discretion — infrastructure phase. Use ROADMAP phase goal as spec.

### Architecture Decisions
- CircuitBreaker should be a standalone struct with state machine (closed/open/halfOpen)
- Timeout should wrap performAITranslation with a 5-second deadline
- Retry should use exponential backoff (250ms, 500ms, 1s) with max 3 attempts
- Failure threshold: open circuit breaker after 5 consecutive failures
- Error handler activation: wire existing AITranslationErrorHandler into translate() flow
- Keep AITranslationService interface unchanged (backward compatible)

</decisions>

<code_context>
## Existing Code Insights

### AITranslationService.swift
- translate() calls performAITranslation() directly - no timeout, no retry
- Has AITranslationError.inferenceTimeout but never enforced
- AITranslationErrorHandler exists but is never imported or used by the service
- No circuit breaker pattern anywhere
- Model loading uses NSLock (good for thread safety)

### AITranslationErrorHandler.swift
- Already exists with handleError() → ErrorAction routing
- Maps errors to: fallbackToRuleBased, retryWithRuleBased, showErrorToUser, retry
- Has errorLog with maxLogSize = 100

### TranslationEngine.swift
- Now uses TranslationCache (from Phase 45)
- No resilience layer yet

</code_context>

<specifics>
## Specific Ideas

Implement 4 separate types:
1. `CircuitBreaker` struct - state machine
2. `RetryPolicy` struct with `execute` wrapper
3. Timeout using `withCheckedThrowingContinuation` wrapping async call
4. Wire `AITranslationErrorHandler` into `translate()` method

</specifics>

<deferred>
## Deferred Ideas

None — all scope fits within ROADMAP goal.

</deferred>
