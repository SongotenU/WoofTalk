# Phase 32: Integration — Execution Plan

**Goal**: End-to-end validation that API gateway, admin dashboard, and organization management work together without breaking existing consumer clients.

**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04, E2E-05

## Execution

### E2E-01: Full Enterprise Flow
Create org → invite member → generate API key → call translate API → verify usage in admin dashboard

Delivering files (already created):
- `supabase/migrations/0009_integration_functions.sql` — `org_usage_summary()` cross-references api_keys, api_key_usage, translations by org_id
- `web/src/app/api/admin/analytics/route.ts` — aggregates api_key_usage data for dashboard
- `e2e-enterprise-test.sh` — automated end-to-end test script

### E2E-02: Admin Moderation of API-Created Content
Admin updates phrase status → audit log entry created → API key revocation takes immediate effect (401 on next call)

Delivering files:
- `web/src/app/api/admin/moderation/update/route.ts` — writes admin_audit_log on status change
- `supabase/functions/api-key-manage/index.ts` — DELETE /keys/:id sets is_revoked=true, revoked_at=now()

### E2E-03: Cross-Org RLS Isolation
User in org A cannot read org B's data. Consumer users (org_id IS NULL) unaffected.

Delivering files:
- `supabase/migrations/0005_migrate_rls_policies.sql` — all 30+ policies use `auth.uid() = user_id OR (org_id IS NOT NULL AND org_id IN subquery)` pattern
- `supabase/migrations/0009_integration_functions.sql` — `cross_org_isolation_check()` function queries cross-org leakage

### E2E-04: Consumer Client Regression
Existing iOS, Android, Web, Watch clients continue functioning with new RLS policies.

Verified by:
- All 6 existing Edge Functions unchanged (translate, phrases-search, leaderboard, activity-batch, text-to-speech, speech-to-text)
- New functions (api-gateway, api-key-manage) are separate — no shared codepaths
- RLS policy migration preserves `auth.uid() = user_id` as first OR branch for consumer users

### E2E-05: Full Verification
All 30 v4.0 requirements verified across 4 phases.
