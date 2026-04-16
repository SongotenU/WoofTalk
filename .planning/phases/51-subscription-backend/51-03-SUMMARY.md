---
phase: 51-subscription-backend
plan: 03
subsystem: api
tags: [revenuecat, entitlement-check, edge-function, deno, subscription, caching, tier-gate]

# Dependency graph
requires:
  - phase: 51-01
    provides: subscription_status table, _shared/subscription.ts types and helpers
  - phase: 51-02
    provides: entitlement-webhook Edge Function that populates subscription_status
provides:
  - entitlement-check Edge Function with RevenueCat REST API verification and 5-min DB-backed caching
  - translate Edge Function subscription tier gate (403 for free users with 3+ daily translations)
affects: [52-paywall-ui, 53-client-gating]

# Tech tracking
tech-stack:
  added: [revenuecat-rest-api-v1]
  patterns: [updated-at-ttl-entitlement-caching, tier-gate-in-service-role-function, stale-data-fallback-with-warning]

key-files:
  created:
    - supabase/functions/entitlement-check/index.ts
  modified:
    - supabase/functions/translate/index.ts

key-decisions:
  - "entitlement-check does its own RevenueCat API call and DB update rather than importing checkSubscriptionTier — it needs the full subscriber response for entitlements/tier/platform data, not just tier+dailyCount"
  - "RevenueCat API fetch errors fall back to stale DB data with warning: cache_stale field — stale data is better than blocking the user"
  - "Missing subscription_status row returns tier: free with cached: true — covers new users before any webhook event"
  - "Deployment requires manual execution — Supabase CLI not available in worktree environment"

patterns-established:
  - "Stale-fallback pattern: when upstream API fails, return cached DB data with a warning flag rather than erroring"
  - "Tier gate placement: between rate limit check and method check in translate Edge Function — surgical addition, no existing logic changed"

requirements-completed: [SUB-06, SUB-07, SUB-10]

# Metrics
duration: 5min
completed: 2026-04-16
---

# Phase 51 Plan 03: Entitlement Check and Translate Tier Gate Summary

**Server-side entitlement verification with RevenueCat REST API, 5-minute DB-backed caching, and translate Edge Function tier gate blocking free-user overages**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T03:20:26Z
- **Completed:** 2026-04-16T03:25:26Z
- **Tasks:** 2 of 3 (1 requires manual execution)
- **Files modified:** 2

## Accomplishments
- Created entitlement-check Edge Function (147 lines) that verifies subscription status via RevenueCat REST API with 5-minute database-backed caching (D-08)
- Added subscription tier check to translate Edge Function that blocks free users at 3+ daily translations with 403 response (D-04 dual enforcement)
- Implemented stale-data fallback pattern: RevenueCat API errors return cached DB data with `warning: 'cache_stale'` flag

## Task Commits

Each task was committed atomically:

1. **Task 1: Create entitlement-check Edge Function** - `13bd7dd` (feat)
2. **Task 2: Update translate Edge Function with subscription tier check** - `830fa88` (feat)
3. **Task 3: Deploy entitlement-check and verify both functions** - NOT EXECUTED (Supabase CLI unavailable in worktree; requires manual deployment)

## Files Created/Modified
- `supabase/functions/entitlement-check/index.ts` - Server-side entitlement verification with RevenueCat REST API, DB-backed 5-min TTL caching, stale-data fallback, missing-row default to free tier
- `supabase/functions/translate/index.ts` - Added checkSubscriptionTier import and tier/dailyCount gate between rate limit and method check

## Decisions Made
- entitlement-check does its own RevenueCat API call and DB update rather than reusing checkSubscriptionTier helper — the function needs the full subscriber response (entitlements, trial_ends_at, purchase_platform) not just tier+dailyCount
- RevenueCat API fetch errors (network failure or non-OK status) fall back to stale DB data with `warning: 'cache_stale'` — stale data is better than blocking the user (T-51-10 mitigation)
- Missing subscription_status row (new users before any webhook event) returns `{ tier: 'free', cached: true }` — Pitfall 3 from RESEARCH
- Tier gate in translate placed between rate limit and method check — matches plan specification exactly

## Deviations from Plan

None - plan executed exactly as specified for Tasks 1 and 2. Task 3 (deployment) could not be executed due to environment limitations and is flagged for manual intervention.

## Issues Encountered

**Deployment requires manual execution:**
- Supabase CLI not installed in worktree environment
- The function code is complete and correct; deployment must be run manually after merge
- Verification commands:
  - `supabase functions deploy entitlement-check`
  - `supabase functions deploy translate`
  - `supabase secrets list` (verify REVENUECAT_API_KEY is set)
  - If missing: `supabase secrets set REVENUECAT_API_KEY=<your-api-key>`

## User Setup Required

**Edge Function deployment and secret configuration require manual execution.** After this branch is merged:
1. Set the API key secret if not already set: `supabase secrets set REVENUECAT_API_KEY=<your-api-key>`
2. Deploy entitlement-check: `supabase functions deploy entitlement-check`
3. Re-deploy translate: `supabase functions deploy translate`
4. Verify deployment: `supabase functions list | grep -E "entitlement-check|translate"`
5. Test entitlement-check: `curl -X GET <EDGE_FUNCTION_URL>/entitlement-check -H "Authorization: Bearer <user-token>" -H "Content-Type: application/json"`
6. Expected: 200 with tier data (or 401 for invalid token)

## Next Phase Readiness
- entitlement-check Edge Function code-complete, ready for deployment
- translate Edge Function tier gate code-complete, ready for deployment
- Both functions depend on REVENUECAT_API_KEY secret being configured before deployment
- Phase 52 (paywall UI) can now call entitlement-check to get subscription state
- Phase 53 (client gating) can use the tier data from entitlement-check responses

## Self-Check: PASSED

All files verified present, commit hashes confirmed, all acceptance criteria met:
- entitlement-check/index.ts: 147 lines, validateAuth, isEntitlementCacheStale, RevenueCat REST API, subscription_status UPDATE, cached field, missing-row handler, no REVENUECAT_WEBHOOK_AUTH
- translate/index.ts: checkSubscriptionTier import, tier/dailyCount gate, 403 for free overage, existing logic unchanged

---
*Phase: 51-subscription-backend*
*Completed: 2026-04-16*
