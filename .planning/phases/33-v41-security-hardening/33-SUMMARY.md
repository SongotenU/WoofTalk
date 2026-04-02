---
phase: 33
plan: 33
name: admin-auth-guards
type: execution
objective: Add admin auth guards for Next.js frontend and API route protection using is_admin() checks via middleware.ts and requireAdmin() helper
status: complete
requires: phase-32 (org/team management)
key: middleware.ts, /403 page, requireAdmin()

---

# Phase 33 Plan 33: Admin Auth Guards Summary

**One-liner:** Next.js `middleware.ts` with real `is_admin()` session verification + `/403` forbidden page + `requireAdmin()` bug fix applied to all 7 admin API routes.

## Tasks Completed

| Task | Description | Done |
|---|---|---|
| Wave 1: middleware.ts | Replace stub middleware with real `is_admin()` session verification | Yes |
| Wave 1: /403 page | Create `/403` forbidden page for non-admin users | Yes |
| Wave 2: requireAdmin() fix | Remove `.throwOnError()` that caused 500 on missing SQL function | Yes |
| Wave 2: API route audit | Verified all 7 admin API routes use `requireAdmin()` helper | Yes |

## Commit

```
90e1d3a feat(33-33): add admin auth guards to middleware and API routes
```

## What Changed

### 1. `web/src/middleware.ts` — Real session verification

**Before:** Only checked for token presence (`sb-access-token` or `supabase-auth-token` cookie), then passed through with a comment that "actual is_admin() check is done server-side." This meant any authenticated user (not just admins) could access `/admin/*` pages.

**After:** 
- Extracts access token from JSON cookie or raw JWT format
- Calls `GET /auth/v1/user` to validate token and get user ID
- Calls `GET /rest/v1/organization_members` to check for active admin/owner role
- Redirects unauthenticated to `/auth/login?redirect=...`
- Redirects authenticated-but-not-admin to `/403`
- Gracefully handles missing Supabase env vars (dev mode passthrough)

### 2. `web/src/app/403/page.tsx` — Forbidden page (new file)

- Clean page matching existing Tailwind/shadcn design patterns
- Explains the user lacks admin permissions
- Provides "Go Home" and "Sign in as admin" action links

### 3. `web/src/lib/supabase/admin-auth.ts` — requireAdmin() bug fix

**Bug:** `.throwOnError()` on `supabase.rpc('is_admin', undefined)` caused an uncaught 500 error if the `is_admin()` SQL function doesn't exist in the database, instead of properly returning 403.

**Fix:** Replace `.throwOnError()` with error destructuring + `console.warn()`. Role-based fallbacks (checking organization_members for admin/owner roles) still work even when `is_admin()` RPC is unavailable.

### 4. API route audit

All 7 admin API routes confirmed using `requireAdmin()`:
- `/api/admin/users/list` — GET (list users)
- `/api/admin/users/role` — POST (suspend/reactivate)
- `/api/admin/audit` — GET (audit log)
- `/api/admin/analytics` — GET (analytics dashboard)
- `/api/admin/moderation/phrases` — GET (moderation queue)
- `/api/admin/moderation/update` — POST (approve/reject)
- `/api/admin/moderation/bulk` — POST (bulk approve/reject)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `.throwOnError()` crash in `requireAdmin()`**
- **Found during:** Task 3 (Wave 2: API route audit)
- **Issue:** `requireAdmin()` at line 113 used `.throwOnError()` on the `is_admin()` Supabase RPC call, which would crash with a 500 server error instead of gracefully returning 403 when the `is_admin()` SQL function is not deployed
- **Fix:** Replaced `.throwOnError()` with error destructuring + console.warn. Role-based fallbacks (admin/owner role check) continue working even without `is_admin()` SQL function
- **Files modified:** `web/src/lib/supabase/admin-auth.ts`
- **Commit:** `90e1d3a`

**2. [Rule 2 - Missing] Added `/403` forbidden page**
- **Found during:** Task 2 (Wave 1: /403 page)
- **Issue:** Plan mentioned /403 redirect in middleware context but page didn't exist in plan's specific task list. Middleware was redirecting to `/403` which would 404
- **Fix:** Created `/403` page with Tailwind-styled forbidden message
- **Files modified:** `web/src/app/403/page.tsx` (new)
- **Commit:** `90e1d3a`

## Known Stubs

None — all middleware and API route guards are fully wired to Supabase authentication and admin role checks.

## Files Changed

- `web/src/middleware.ts` (modified) — Real admin session verification
- `web/src/app/403/page.tsx` (created) — Forbidden page for non-admin users
- `web/src/lib/supabase/admin-auth.ts` (modified) — Fixed requireAdmin() crash bug
