# Code Review Report - Phase 49: scale-testing
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 49 implemented scale testing: k6 load test script for Supabase edge functions (10→50→100 users over 2.5 minutes) and concurrent RLS verification script. The k6 test has issues: `BASE` URL defaults to `localhost:54321` which won't work in CI without Supabase started, and the `translate` endpoint test doesn't include an auth token (only apikey). The RLS verification script tests that both users CAN access their own data (200 status), but doesn't verify that users CANNOT access each other's data — the script name implies security verification but actually only checks availability.

## Findings

### [WARNING] WR-01: k6 test translate endpoint missing Authorization token
**File**: `scripts/load-tests/k6-edge-functions.js:29-41`
**Severity**: WARNING
**Category**: Bug
**Description**: The `translate` POST request includes only `apikey` header but no `Authorization: Bearer <token>` header. Supabase edge functions typically require authentication via the Authorization header. Without it, requests may fail with 401 for protected functions, skewing the load test results.
**Recommendation**: Add Authorization header with a test token:
```javascript
headers: {
  'Content-Type': 'application/json',
  'apikey': API_KEY,
  'Authorization': `Bearer ${__ENV.SUPABASE_USER_TOKEN || 'test-token'}`,
},
```

### [WARNING] WR-02: RLS verification script doesn't test RLS enforcement
**File**: `scripts/load-tests/verify-rls-concurrent.sh:20-38`
**Severity**: WARNING
**Category**: Bug
**Description**: The script is named "verify-rls-concurrent" and claims to test "Row Level Security prevents cross-tenant data access". However, it only checks that User1 and User2 CAN access `/rest/v1/phrases` (200 status). It NEVER tests that User1 cannot see User2's data, or that a user cannot access another tenant's resources. This is an availability test, not a security test.
**Recommendation**: Add negative test cases:
```bash
# Test that User1 cannot access User2's data
RES_CROSS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X GET "${URL}/rest/v1/phrases?id=eq.user2-phrase-id" \
  -H "apikey: ${KEY}" \
  -H "Authorization: Bearer ${TOKEN1}")
if [ "$RES_CROSS" -ne 403 ] && [ "$RES_CROSS" -ne 401 ]; then
  echo "FAILED: RLS not enforced — User1 accessed User2's data"
  exit 1
fi
```

### [INFO] IN-01: k6 test default BASE URL won't work in CI
**File**: `scripts/load-tests/k6-edge-functions.js:24`
**Severity**: INFO
**Category**: Quality
**Description**: The default `BASE` URL is `http://localhost:54321/functions/v1` which requires a local Supabase instance. In CI, this would fail unless Supabase is started. The env var `SUPABASE_FUNCTIONS_URL` is already used, but the fallback is misleading.
**Recommendation**: Either remove the fallback (require env var) or add a check:
```javascript
if (!__ENV.SUPABASE_FUNCTIONS_URL) {
  console.error('Set SUPABASE_FUNCTIONS_URL environment variable');
  exit(1);
}
```

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 1
