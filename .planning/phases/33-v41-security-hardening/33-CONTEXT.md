# v4.1: Security & Deployment Hardening — Context

**Problem:** v4.0 delivered all 30 requirements across 4 phases, but the execution left several gaps in security, auth guards, and deployment readiness. The code is "feature-complete" but not "production-ready."

## Execution Gaps from v4.0

### 1. Admin Routes Have No Auth Gate
- **File:** `web/src/app/admin/` — 6 pages, 0 middleware
- **Gap:** No `middleware.ts` or route guards — anyone hitting `/admin/*` sees user data and moderation tools
- **Plan mentioned:** Wave 3 hardening was planned but never executed
- **Fix:** Add Next.js middleware with `is_admin()` RLS check, redirect unauthorized to `/403`

### 2. Admin API Routes Have No Auth
- **Files:** `web/src/app/api/admin/**/*.ts` — 7 routes
- **Gap:** No admin session check — any authenticated user can ban members
- **Fix:** Add `isAdmin()` check to all admin API routes

### 3. Org Invite Email Not Implemented
- **File:** `web/src/app/api/org/invite/route.ts`
- **Gap:** TODO comment: "Send email invite with invite link" — invite inserted to DB but no email
- **Fix:** Add Resend/SendGrid integration with invite template

### 4. Rate Limiting Unproven
- **File:** `supabase/functions/_shared/rate-limit.ts`
- **Gap:** Dev fallback allows all requests when Redis unavailable; no test proving 429 behavior
- **Fix:** Add unit test for rate limiter, document provisioning steps

### 5. Consumer Client Regression Not Tested
- **Gap:** 6 existing Edge Functions (translate, phrases-search, leaderboard, activity-batch) untested against new RLS
- **Fix:** Add regression test suite: verify each old function still works with new org-scoped policies

## Deferred Requirements to Pull into v4.1

| Req | Description | Why Now |
|-----|-------------|---------|
| API-08 | API Playground | Easy to add with `scalar/openapi` on Edge Function surface |
| API-09 | Per-key IP Allowlisting | Security gap — API keys can be leaked and replayed from any IP |

## Requirements NOT Pulled

| Req | Description | Why Defer |
|-----|-------------|-----------|
| SSO-01 | SSO/SAML | Requires Supabase Pro ($25/mo), needs budget decision |
| BILLING-01 | Usage-based billing | Complex, depends on org usage data from v4.1 deployment |
| API-10 | SDK (TS/Python) | Developer ecosystem, not security-critical |
| ORG-07 | Team-level workspaces | Content isolation complexity, needs org usage patterns |
| ADMIN-07 | Automated spam detection | ML complexity, manual moderation is sufficient for now |
