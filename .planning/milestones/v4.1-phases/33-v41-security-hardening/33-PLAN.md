# v4.1: Security & Deployment Hardening — Execution Plan

**Goal:** Close security gaps from v4.0 execution, add auth guards, and make the admin/org/API surfaces production-ready.

**Depends on**: All v4.0 phases (29-32)

**Scope**: 5 phases, 2 waves each, focused on security gaps and deployment readiness

---

## Phase 33: Admin Auth & Route Guards
**Goal**: Protect all admin pages and API routes behind `is_admin()` validation

### Wave 1: Next.js Middleware
- Add `middleware.ts` at `web/src/` — checks Supabase session → `is_admin() → `/401` or `/` on failure
- Add admin-only pages under `/admin/`: `/401`

### Wave 2: API Route Auth
- Extract `requireAdmin()` helper → apply to all 7 admin API routes
- Verify: unauthenticated request to `/api/admin/users/list` returns 401

---

## Phase 34: API Security Hardening
**Goal**: Close API security gaps (IP allowlisting, CORS tightening, OpenAPI spec)

### Wave 1: IP Allowlisting (API-09)
- Add `allowed_ips` array column to `api_keys` table
- Check request IP against `allowed_ips` in Hono middleware
- Skip check if `allowed_ips` is empty

### Wave 2: OpenAPI Spec (API-08)
- Add `GET /v1/openapi.json` endpoint to api-gateway
- Add Scalar API playground at `GET /v1/docs`

---

## Phase 35: Consumer Client Regression
**Goal**: Verify existing client code is not broken by RLS policy changes

### Wave 1: Regression Test Script
- Script to test each existing Edge Function against deployed Supabase with new RLS
- Test cases: translate (session auth), phrases-search (public read), leaderboard (public read), activity-batch (session auth)

### Wave 2: RLS Policy Audit
- Verify consumer test passes
- Document any consumer users get 403
- Flag any broken auth flows

---

## Phase 36: Email & Invite System
**Goal**: Complete org invite flow with email delivery

### Wave 1: Email Integration
- Add Resend (or Supabase Email Templates) integration
- Create invite email template with `invite_token` and expiry
- Update `POST /api/org/invite` to send email on DB insert

### Wave 2: Invite Acceptance
- Add `/invite/:token` page in web app — validates token → joins org → redirects to `/org`
- Handle expired/invalid tokens

---

## Phase 37: Deployment Infrastructure
**Goal**: Make v4.0 deployable and monitorable

### Wave 1: Environment & Secrets
- Document all required env vars across Edge Functions
- Create `.env.example` for web admin
- Add Supabase CLI to CI for migration deployment

### Wave 2: E2E Test Execution
- Finalize `e2e-enterprise-test.sh`
- Run against staging → block merge on pass
- Generate VERIFICATION.md with test results
