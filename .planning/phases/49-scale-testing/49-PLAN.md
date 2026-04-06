# Phase 49: Scale Testing - Plan

## Plans

### Plan 1: k6 Load Test for Edge Functions
**Type:** Performance test
**Description:** `k6-edge-functions.js` — ramps 10→50→100 users over 2 minutes. Validates p95 < 2s and error rate < 1%. Tests translate and search endpoints.

### Plan 2: Concurrent RLS Verification
**Type:** Security test
**Description:** `verify-rls-concurrent.sh` — fires 10 concurrent request pairs with different user tokens, verifies RLS rejects none (both succeed independently).

### Plan 3: Rate Limit Validation
**Type:** Infrastructure test
**Description:** Embedded in k6 test via thresholds. Supabase rate limits tested under 100 concurrent users.

## Success Criteria

1. k6 load test script exists with realistic traffic patterns
2. RLS concurrent verification script exists and is executable
3. Rate limit thresholds defined in k6 options
4. Cache hit rate validation approach documented
