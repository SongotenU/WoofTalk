#!/usr/bin/env bash
# Phase 35: Consumer Client Regression Test
# Verifies existing Edge Functions still work after v4.0 RLS migration
set -euo pipefail

BASE="${SUPABASE_FUNCTIONS_URL:-https://$(echo "$SUPABASE_URL" | sed 's|https://||;s|\.supabase.*||').supabase.co/functions/v1"
TOKEN="${SUPABASE_ACCESS_TOKEN:-demo_token}"
PASS=0; FAIL=0; TOTAL=0

pass() { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); echo "  ❌ $1 (expected $2, got $3)"; }
check() {
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$1")
  if [ "$CODE" = "$2" ]; then pass "$3"; else fail "$3" "$2" "$CODE"; fi
}

echo "=== Consumer Client Regression ==="
echo "Target: $BASE"
echo ""

# Test 1: translate function still works
echo "--- POST /translate ---"
RESP=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"human_text":"hello","animal_text":"woof"}' \
  "${BASE}/translate")
CODE="${RESP##*$'\n'}"; BODY="${RESP%$'\n'*}"
[ "$CODE" = "201" ] && pass "translate accepts new translations" || fail "translate" "201" "$CODE"

# Test 2: phrases-search returns data
echo "--- GET /phrases-search ---"
check "${BASE}/phrases-search?q=test" "200" "phrase search returns 200"

# Test 3: leaderboard readable
echo "--- GET /leaderboard ---"
check "${BASE}/leaderboard?period=all_time" "200" "leaderboard returns 200"

# Test 4: activity-batch rejects without auth
echo "--- POST /activity-batch (no auth) ---"
RESP=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{"events":[{"event_type":"test"}]}' \
  "${BASE}/activity-batch")
CODE="${RESP##*$'\n'}"
[ "$CODE" = "401" ] && pass "activity-batch requires auth" || fail "activity-batch auth" "401" "$CODE"

echo ""
echo "Results: ${PASS}/${TOTAL} passed"
[ "$FAIL" -eq 0 ] && echo "✅ All consumer regression tests passed" || echo "⚠️  ${FAIL} test(s) failed"
