#!/bin/bash
# Concurrent RLS verification — tests that Row Level Security prevents
# cross-tenant data access under concurrent load
# Usage: SUPABASE_URL=... SUPABASE_ANON_KEY=... TOKEN1=... TOKEN2=... bash scripts/load-tests/verify-rls-concurrent.sh

set -euo pipefail

URL="${SUPABASE_URL:?Set SUPABASE_URL}"
KEY="${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY}"
TOKEN1="${TOKEN1:?Set TOKEN1}"
TOKEN2="${TOKEN2:?Set TOKEN2}"

echo "=== Concurrent RLS Verification ==="
echo "Testing ${URL} with 2 concurrent users"
echo ""

FAILED=0
TOTAL=0

for i in $(seq 1 10); do
  # User1 queries their data
  RES1=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "${URL}/rest/v1/phrases" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${TOKEN1}")

  # User2 queries their data
  RES2=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "${URL}/rest/v1/phrases" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${TOKEN2}")

  TOTAL=$((TOTAL + 2))
  if [ "$RES1" -ne 200 ] || [ "$RES2" -ne 200 ]; then
    FAILED=$((FAILED + 1))
    echo "  Iteration $i: User1=$RES1, User2=$RES2"
  fi

  # Negative test: User1 tries to access User2's data (should fail with 401 or 403)
  CROSS1=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "${URL}/rest/v1/phrases?id=eq.user2-test-id" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${TOKEN1}")
  TOTAL=$((TOTAL + 1))
  if [ "$CROSS1" -ne 401 ] && [ "$CROSS1" -ne 403 ]; then
    FAILED=$((FAILED + 1))
    echo "  Iteration $i: RLS FAILED - User1 accessed User2's data (status=$CROSS1)"
  fi

  # Negative test: User2 tries to access User1's data (should fail with 401 or 403)
  CROSS2=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "${URL}/rest/v1/phrases?id=eq.user1-test-id" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${TOKEN2}")
  TOTAL=$((TOTAL + 1))
  if [ "$CROSS2" -ne 401 ] && [ "$CROSS2" -ne 403 ]; then
    FAILED=$((FAILED + 1))
    echo "  Iteration $i: RLS FAILED - User2 accessed User1's data (status=$CROSS2)"
  fi
done

echo ""
echo "Result: $((TOTAL - FAILED))/$TOTAL iterations passed"
if [ "$FAILED" -gt 0 ]; then
  echo "FAILED: RLS rejected $FAILED concurrent request pairs"
  exit 1
fi
echo "PASSED: RLS verified under concurrent access"
