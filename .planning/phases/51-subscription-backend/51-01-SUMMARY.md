---
phase: 51-subscription-backend
plan: 01
subsystem: database
tags: [postgresql, rls, subscription, revenuecat, enum, idempotency]

# Dependency graph
requires:
  - phase: 50-revenuecat-sdk-integration
    provides: RevenueCat SDK init, EntitlementManager, auth.uid as appUserID convention
provides:
  - subscription_status table with RLS (user-owned reads)
  - user_profiles table with revenuecat_id
  - webhook_events table for idempotency
  - Tier-aware translations INSERT policy (3/day free limit)
  - Shared subscription.ts module with types and tier-check helper
affects: [51-02, 51-03, 52-paywall-ui, 53-client-gating]

# Tech tracking
tech-stack:
  added: [postgresql-enum, jsonb-entitlements]
  patterns: [rls-with-subquery-tier-check, coalesce-default-free, updated-at-ttl-caching, webhook-events-idempotency]

key-files:
  created:
    - supabase/migrations/0013_subscription_status.sql
    - supabase/functions/_shared/subscription.ts
  modified: []

key-decisions:
  - "COALESCE with explicit cast handles new users without subscription_status row"
  - "user_profiles created with IF NOT EXISTS since table did not exist in prior migrations"
  - "Schema push requires manual execution (Supabase CLI not available in worktree)"

patterns-established:
  - "RLS tier-check pattern: subquery to subscription_status with COALESCE fallback to 'free'"
  - "Shared subscription module: export types + async helper functions, no serve() call"

requirements-completed: [SUB-01, SUB-02, SUB-08, SUB-09]

# Metrics
duration: 8min
completed: 2026-04-16
---

# Phase 51 Plan 01: Subscription Backend Summary

**PostgreSQL migration with subscription_status table, tier-aware RLS policy enforcing 3/day free limit, and shared subscription utility module**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-16T02:41:13Z
- **Completed:** 2026-04-16T02:49:13Z
- **Tasks:** 2 of 3 (1 requires manual execution)
- **Files modified:** 2

## Accomplishments
- Created migration 0013 with subscription_status, user_profiles, webhook_events tables and PostgreSQL ENUM types
- Replaced translations INSERT policy with tier-aware version that enforces 3/day free limit via RLS with COALESCE fallback
- Created shared subscription.ts module with SubscriptionTier/PurchasePlatform types, SubscriptionStatus interface, checkSubscriptionTier helper, and isEntitlementCacheStale with 5-min TTL

## Task Commits

Each task was committed atomically:

1. **Task 1: Create subscription backend migration** - `2bf0334` (feat)
2. **Task 2: Create shared subscription utility module** - `6aae22a` (feat)
3. **Task 3: Push schema to database** - NOT EXECUTED (Supabase CLI unavailable in worktree; requires manual `supabase db push`)

## Files Created/Modified
- `supabase/migrations/0013_subscription_status.sql` - Subscription backend migration with ENUM types, subscription_status table, user_profiles table, tier-aware RLS policy, webhook_events table
- `supabase/functions/_shared/subscription.ts` - Shared types (SubscriptionTier, PurchasePlatform, SubscriptionStatus) and helpers (checkSubscriptionTier, isEntitlementCacheStale, CACHE_TTL_MS)

## Decisions Made
- Used COALESCE with explicit cast `'free'::public.subscription_tier` in RLS policy to handle new users without subscription_status row (prevents NULL comparison failure)
- Created user_profiles table with `IF NOT EXISTS` since no prior migration creates it (RESEARCH Pitfall 6)
- Documented schema push as manual step since Supabase CLI is not available in the worktree environment

## Deviations from Plan

None - plan executed exactly as specified for Tasks 1 and 2. Task 3 (schema push) could not be executed due to environment limitations and is flagged for manual intervention.

## Issues Encountered

**Schema push requires manual execution:**
- Supabase CLI not installed in worktree environment
- No `supabase/config.toml` found (no local Supabase project link)
- Migration file is correct and complete; the `supabase db push` command must be run manually after merge
- Verification command: `supabase db push && supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('subscription_status', 'user_profiles', 'webhook_events') ORDER BY table_name;"`

## User Setup Required

**Schema deployment requires manual execution.** After this branch is merged:
1. Install Supabase CLI if not present: `brew install supabase/tap/supabase`
2. Link to project: `supabase link --project-ref <project-ref>`
3. Push the migration: `supabase db push`
4. Verify tables exist: `supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('subscription_status', 'user_profiles', 'webhook_events') ORDER BY table_name;"`
5. Expected output: 3 rows (subscription_status, user_profiles, webhook_events)

## Next Phase Readiness
- Migration and shared module are code-complete and ready for downstream plans 51-02 (webhook handler) and 51-03 (entitlement check)
- The shared subscription.ts module can be imported by Edge Functions: `import { checkSubscriptionTier, isEntitlementCacheStale, SubscriptionTier } from '../_shared/subscription.ts'`
- The RLS policy will activate once the migration is pushed, immediately enforcing 3/day free-tier translation limits
- Plans 51-02 and 51-03 depend on the tables existing in the database (Task 3 manual push)

---
*Phase: 51-subscription-backend*
*Completed: 2026-04-16*
