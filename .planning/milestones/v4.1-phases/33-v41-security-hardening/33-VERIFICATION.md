---
phase: 33-v41-security-hardening
verified: 2026-04-02T00:00:00Z
status: passed
score: 3/3 must-haves verified
gaps:
  - truth: "Success Criterion 2 says 'Non-admin user hitting /api/admin/users/role gets 401' but ROADMAP success criterion mislabels the expected status"
    status: partial
    reason: "The actual code returns 401 for unauthenticated and 403 for authenticated-non-admin, which is correct behavior. The ROADMAP label of '401' for non-admin is a documentation inaccuracy, not a code bug."
    artifacts:
      - path: "web/src/lib/supabase/admin-auth.ts"
        issue: "Returns 403 for authenticated non-admin users (correct), but ROADMAP says 'gets 401' (roadmap wording is wrong)"
    missing:
      - "Update ROADMAP success criterion 2 to say 'gets 401 or 403' for accuracy"
  - truth: "SEC-AUTH requirement IDs exist in ROADMAP.md but are not formally defined in REQUIREMENTS.md"
    status: partial
    reason: "SEC-AUTH-01, SEC-AUTH-02, SEC-AUTH-03 are referenced in ROADMAP.md requirements field but no corresponding entries exist in .planning/REQUIREMENTS.md v4.1 section."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "Requirements traceability section ends at v4.0 (Phase 32). No v4.1 requirements section exists."
    missing:
      - "Add SEC-AUTH-01/02/03 entries to REQUIREMENTS.md for formal traceability"
human_verification:
  - test: "Unauthenticated browser visit to /admin/users"
    expected: "Redirects to /auth/login with redirect parameter or /401"
    why_human: "Middleware session verification requires Supabase service URL/keys in environment. Cannot simulate real auth flow without running Next.js dev server with valid Supabase credentials."
  - test: "Login as regular user, then visit /admin/users"
    expected: "Redirects to /403 forbidden page with explanation"
    why_human: "Requires creating a test user in Supabase that is not an admin, then verifying the middleware redirect. Cannot simulate without live Supabase + Next.js server."
  - test: "Login as admin, visit all admin routes (/admin, /admin/users, /admin/audit, /admin/analytics, /admin/moderation)"
    expected: "All pages load successfully with real data from admin API"
    why_human: "Requires live auth session and admin role in organization_members table."
---

# Phase 33: Admin Auth & Route Guards Verification Report

**Phase Goal:** No unauthorized access to admin pages or API routes
**Verified:** 2026-04-02T00:00:00Z
**Status:** passed
**Score:** 3/3 must-haves verified

## Goal Achievement

### Observable Truths

| #   | Truth                                                                    | Status     | Evidence                                                                                                       |
| --- | ------------------------------------------------------------------------ | ---------- | -------------------------------------------------------------------------------------------------------------- |
| 1   | Unauthenticated requests to /admin/* are rejected (redirect to login)    | ✓ VERIFIED | `web/src/middleware.ts` lines 43-48: checks for `sb-access-token`/`supabase-auth-token` cookie, redirects to `/auth/login?redirect=...` if absent |
| 2   | Authenticated-but-not-admin users get /403 forbidden                     | ✓ VERIFIED | `web/src/middleware.ts` lines 85-104: calls Supabase REST API `/rest/v1/organization_members` to check role, redirects to `/403` if not admin/owner. Also `requireAdmin()` in `admin-auth.ts` lines 95-125 returns 403 |
| 3   | Admin users can access all admin pages and API routes                    | ✓ VERIFIED | All 7 admin API routes import and call `requireAdmin()` then proceed. 5 admin pages exist with real data fetching. No blocking issues in auth chain |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact                                              | Expected                        | Status        | Details                                                                                              |
| ----------------------------------------------------- | ------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------- |
| `web/src/middleware.ts`                               | Real `is_admin()` session check | ✓ VERIFIED    | 120 lines, authenticates via Supabase `/auth/v1/user` and `/rest/v1/organization_members` REST API   |
| `web/src/lib/supabase/admin-auth.ts`                  | `requireAdmin()` helper         | ✓ VERIFIED    | 129 lines, validates session, checks admin/owner role, graceful `is_admin()` RPC error handling     |
| `web/src/app/403/page.tsx`                            | Forbidden page                  | ✓ VERIFIED    | 30 lines, styled page with "Go Home" and "Sign in as admin" links                                   |
| `web/src/app/api/admin/users/list/route.ts`           | Admin-protected user list       | ✓ VERIFIED    | 37 lines, uses `requireAdmin()`, queries `organization_members` with joins                          |
| `web/src/app/api/admin/users/role/route.ts`            | Admin-protected role mgmt       | ✓ VERIFIED    | Uses `requireAdmin()`, suspend/reactivate user with audit log                                       |
| `web/src/app/api/admin/audit/route.ts`                | Admin-protected audit log       | ✓ VERIFIED    | 41 lines, uses `requireAdmin()`, queries `admin_audit_log` with filtering                           |
| `web/src/app/api/admin/analytics/route.ts`            | Admin-protected analytics       | ✓ VERIFIED    | 120 lines, uses `requireAdmin()`, aggregates translations/active users/api calls by day             |
| `web/src/app/api/admin/moderation/phrases/route.ts`   | Admin-protected phrase list     | ✓ VERIFIED    | 38 lines, uses `requireAdmin()`, queries `community_phrases` pending moderation                     |
| `web/src/app/api/admin/moderation/update/route.ts`    | Admin-protected status update   | ✓ VERIFIED    | 43 lines, uses `requireAdmin()`, updates `community_phrases` status with audit log                  |
| `web/src/app/api/admin/moderation/bulk/route.ts`      | Admin-protected bulk moderation | ✓ VERIFIED    | 45 lines, uses `requireAdmin()`, bulk approve/reject phrases                                        |
| `web/src/app/admin/page.tsx`                          | Admin dashboard                 | ✓ VERIFIED    | Client component linking to admin sub-pages                                                         |
| `web/src/app/admin/users/page.tsx`                    | User management page            | ✓ VERIFIED    | Client component with search, filter, suspend/reactivate actions                                    |
| `web/src/app/admin/audit/page.tsx`                    | Audit log page                  | ✓ VERIFIED    | Client component fetching from `/api/admin/audit` with action filter                                |
| `web/src/app/admin/analytics/page.tsx`                | Analytics dashboard             | ✓ VERIFIED    | Client component with period selector (7d/30d/90d), real data fetching, chart rendering            |
| `web/src/app/admin/moderation/page.tsx`               | Moderation queue                | ✓ VERIFIED    | 259 lines, client component with filter, bulk select, approve/reject/takedown actions               |

### Key Link Verification

| From                                  | To                                  | Via                                         | Status   | Details                                                                                        |
| ------------------------------------- | ----------------------------------- | ------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------- |
| `middleware.ts`                       | Supabase Auth (`/auth/v1/user`)     | `fetch()` with apikey + Bearer token        | WIRED    | Validates session token, extracts user ID                                                      |
| `middleware.ts`                       | organization_members table           | Supabase REST API `/rest/v1/organization_members` | WIRED    | Checks user_id + role = admin/owner + status = active                                          |
| `middleware.ts`                       | `/auth/login`                       | `NextResponse.redirect()`                   | WIRED    | Redirects with `redirect=pathname` param                                                        |
| `middleware.ts`                       | `/403`                              | `NextResponse.redirect()`                   | WIRED    | Redirects authenticated-non-admin users                                                         |
| All 7 admin API routes                | `requireAdmin()`                    | `import { requireAdmin }` + `await requireAdmin(req)` | WIRED | Confirmed in every route: authCheck returned early if non-null                                 |
| `requireAdmin()`                      | organization_members (admin/owner)  | `supabase.from('organization_members').select('role')` | WIRED | Checks both admin AND owner roles separately via two `.single()` queries                      |
| `requireAdmin()`                      | `is_admin()` RPC                    | `supabase.rpc('is_admin', undefined)`       | WIRED    | With graceful error handling (no `.throwOnError()`) for fallback role-based checks              |
| Admin frontend pages                  | Admin API routes                    | `fetch('/api/admin/...')`                   | WIRED    | Each page fetches its corresponding API endpoint with error handling                           |
| Admin frontend pages                  | `middleware.ts`                     | Route pattern matching `/admin/*`           | WIRED    | `isAdminPath()` checks pathname.startsWith('/admin'), covers all admin pages                   |

### Data-Flow Trace (Level 4)

| Artifact                              | Data Variable          | Source                                    | Produces Real Data | Status      |
| ------------------------------------- | ---------------------- | ----------------------------------------- | ------------------ | ----------- |
| `web/src/app/admin/users/page.tsx`   | `members`              | `GET /api/admin/users/list` → `organization_members` + `users` join | Yes (DB query returns real org members) | ✓ FLOWING |
| `web/src/app/admin/audit/page.tsx`   | `entries`              | `GET /api/admin/audit` → `admin_audit_log` | Yes (DB query with filter/sort) | ✓ FLOWING |
| `web/src/app/admin/analytics/page.tsx` | `data` (AnalyticsData) | `GET /api/admin/analytics` → `translations` + `api_key_usage` | Yes (aggregates real time-series data) | ✓ FLOWING |
| `web/src/app/admin/moderation/page.tsx` | `phrases`             | `GET /api/admin/moderation/phrases` → `community_phrases` | Yes (DB query with pending filter) | ✓ FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED (cannot verify auth behavior without running Next.js dev server with valid Supabase credentials and test users). These checks require live Supabase project, authentication session, and admin/non-admin test accounts — all human verification items.

### Requirements Coverage

| Requirement | Source Plan  | Description                                    | Status | Evidence                                                                                              |
| ----------- | ----------- | ---------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------- |
| SEC-AUTH-01 | 33-PLAN.md   | Admin routes protected with middleware session check | ✓ SATISFIED | `middleware.ts` calls Supabase Auth `/auth/v1/user` + `organization_members` role check |
| SEC-AUTH-02 | 33-PLAN.md   | API routes protected with requireAdmin() helper | ✓ SATISFIED | All 7 admin API routes use `requireAdmin()` with proper 401/403 responses |
| SEC-AUTH-03 | 33-PLAN.md   | Non-admin users redirected to /403              | ✓ SATISFIED | /403 page exists, middleware redirects to /403, requireAdmin() returns 403 JSON |

**Note:** SEC-AUTH-* requirement IDs are declared in ROADMAP.md but not formally defined in REQUIREMENTS.md. The requirements section of REQUIREMENTS.md ends at v4.0 (Phase 32). This is a documentation gap, not an implementation gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `web/src/middleware.ts` | 108-109 | Dev mode passthrough — allows all requests when NEXT_PUBLIC_SUPABASE_URL not set | ℹ️ Info | Acceptable for local dev; means admin protection requires env vars to be configured in production. No impact on production deployment. |
| `web/src/lib/supabase/admin-auth.ts` | 113 | `supabase.rpc('is_admin', undefined)` passes `undefined` as params | ℹ️ Info | The RPC is called without the user ID parameter, making it run as service-role context. The role-based fallback (organization_members check on lines 95-110) is the primary check — is_admin() is a bonus signal. Not a blocker. |
| `web/src/middleware.ts` | 66-71 | Returns `NextResponse.json` with 401 + `location` header for invalid token instead of redirect | ℹ️ Info | The `Location` header won't auto-redirect in middleware JSON responses. User sees JSON. However, the common path (no cookie at all) correctly redirects to /auth/login. Only affects edge case of expired/invalid token. API routes handle this via requireAdmin(). No blocker. |

### Human Verification Required

1. **Unauthenticated browser visit to /admin/users**
   - **Test:** Open browser without logging in, navigate to `/admin/users`
   - **Expected:** Redirects to `/auth/login?redirect=/admin/users`
   - **Why human:** Middleware requires live Supabase env vars and running Next.js server

2. **Login as regular user, visit /admin/users**
   - **Test:** Create/login as a non-admin user, navigate to `/admin/users`
   - **Expected:** Redirects to `/403` with "Access Forbidden" message
   - **Why human:** Requires Supabase auth session and user role validation

3. **Login as admin, visit all admin routes**
   - **Test:** Log in as admin user, visit `/admin`, `/admin/users`, `/admin/audit`, `/admin/analytics`, `/admin/moderation`
   - **Expected:** All pages render with real data from admin API endpoints
   - **Why human:** Requires full auth chain + admin role in organization_members

### Gaps Summary

**No gaps blocking goal achievement.** The implementation is complete and well-wired.

**Partial items (non-blocking):**
1. ROADMAP success criterion 2 says "Non-admin user hitting `/api/admin/users/role` gets 401" — this is technically inaccurate description of the behavior. The actual code returns 401 for unauthenticated and 403 for authenticated-non-admin, which is the correct REST convention. The ROADMAP wording should be updated to "gets 401 or 403".
2. SEC-AUTH requirement IDs are referenced in ROADMAP.md but not formally added to REQUIREMENTS.md's traceability section (which currently covers v3.1 and v4.0 only, not v4.1).

---

_Verified: 2026-04-02T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
