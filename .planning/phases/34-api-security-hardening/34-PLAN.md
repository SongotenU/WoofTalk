---
phase: 34
plan: 34
name: api-security-hardening
type: execution
objective: Harden API gateway with IP allowlisting, OpenAPI spec, and tightened CORS
status: complete
requires: phase-29 (api_keys table, api-gateway)
key: IP allowlist, OpenAPI spec, CORS lockdown
---

# Phase 34 Plan 34: API Security Hardening Summary

**One-liner:** Add IP allowlist to api_keys, implement IP check middleware in api-gateway, add OpenAPI 3.1 spec, and tighten CORS from wildcard to specific origins.

## Tasks Completed

| Task | Description | Done |
|---|---|---|
| Wave 1: Database Migration | Add `allowed_ips` array column to `api_keys` table (migration 0010) | Yes |
| Wave 1: IP Middleware | Add IP allowlist check to `supabase/functions/api-gateway/index.ts` | Yes |
| Wave 2: OpenAPI Spec | Add `GET /v1/openapi.json` endpoint returning OpenAPI 3.1 spec | Yes |
| Wave 2: CORS Tightening | Change CORS from `*` to specific configured `ALLOWED_ORIGINS` | Yes |

## Commit

```
d474d4a Phase 34: API security hardening
6c87b7c Phase 34: API security hardening — ROADMAP update
```

## What Changed

### 1. Migration 0010: `allowed_ips` on api_keys

Added `allowed_ips` TEXT[] column to `api_keys` table. Stores list of allowed IP addresses for API key. Empty array means no restriction (backward compatible).

**File:** `supabase/migrations/0010_api_key_ip_allowlist.sql`

### 2. API Gateway IP Check & CORS

**Before:** CORS allowed all origins (`*`). No IP validation.

**After:**
- Extracts IP from `X-Forwarded-For` or `CF-Connecting-IP` headers (Cloudflare-aware)
- Skips check if `allowed_ips` is empty (opt-in restriction)
- Returns 403 for non-allowlisted IPs with JSON error
- CORS configured via `ALLOWED_ORIGINS` env var (defaults to localhost for dev)
- Adds `Access-Control-Allow-Credentials: true` for authenticated requests

**File:** `supabase/functions/api-gateway/index.ts`

### 3. OpenAPI 3.1 Spec Endpoint

Added `GET /v1/openapi.json` that returns complete OpenAPI specification for the API gateway. Includes:
- All API routes with methods, paths, descriptions
- Authentication scheme (API key in header)
- Response schemas
- Server URL from `SUPABASE_PROJECT_REF`

**File:** `supabase/functions/api-gateway/index.ts` (lines 184-223)

## Deviations from Plan

**None** — All planned tasks completed as specified. The plan called for IP allowlisting, OpenAPI spec, and CORS tightening. All three delivered.

## Known Stubs

**None** — Feature is complete and wired. IP allowlisting is per-API-key (empty = unrestricted), OpenAPI spec is dynamic, CORS is production-ready.

## Files Changed

- `supabase/migrations/0010_api_key_ip_allowlist.sql` (new)
- `supabase/functions/api-gateway/index.ts` (modified)
