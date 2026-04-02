# Phase 29: API Gateway & Data Model — Summary

## What Was Built

### Database Migrations (7 files)
- **0001_organizations.sql** — `organizations`, `organization_members`, `teams`, `team_members` tables with RLS policies and indexes
- **0002_api_keys.sql** — `api_keys` (prefix-based bcrypt validation), `api_key_usage` (per-key request tracking) tables with RLS
- **0003_api_key_function.sql** — `validate_api_key(raw_key)` SQL function with SECURITY DEFINER for Edge Function lookup
- **0004_add_org_id_columns.sql** — ADD COLUMN org_id on 9 existing tables (translations, community_phrases, social_follows, social_likes, social_comments, user_settings, notification_preferences, activity_events, leaderboard_entries)
- **0005_migrate_rls_policies.sql** — Recreated 30+ policies with org-scoped OR logic preserving backward compatibility for consumer users
- **0006_migrate_role_functions.sql** — `is_admin()` and `is_moderator()` migrated from `raw_user_meta_data` to `organization_members` join table; added `get_user_orgs()` and `get_user_org_role()`
- **0007_seed_data.sql** — Seed data template for development testing

### Edge Functions (2 functions, 5 shared modules)
- **api-gateway** — Hono-based REST API gateway at `/v1/*`:
  - `POST /v1/translate` — Translation endpoint with zod validation
  - `GET /v1/languages` — Supported languages list
  - `GET /v1/usage` — Per-key usage dashboard endpoint
  - API key auth as Hono middleware (format check → prefix lookup → bcrypt compare)
  - Scope enforcement middleware (translate:read/write/full → endpoint mapping)
  - Upstash rate limiter with fixed window algorithm
  - `API-Version: v1` header on all responses
  - Standardized error response shape with machine-readable error codes

- **api-key-manage** — API key lifecycle via Supabase session auth:
  - `POST /keys` — Generate new key (returns plaintext once, stores bcrypt hash)
  - `GET /keys` — List user's keys (without hashes)
  - `DELETE /keys/:id` — Revoke key
  - `PATCH /keys/:id` — Update name/scope/rate_limit

### Shared Utilities
- `_shared/api-key.ts` — `validateApiKey()` (prefix + bcrypt), `checkScope()` (scope → permission mapping)
- `_shared/rate-limit.ts` — `checkRateLimit()` with Upstash Redis, dev fallback when Redis unavailable
- `_shared/response.ts` — `apiError()`, `apiSuccess()`, `trackUsage()` (fire-and-forget)

## Requirements Delivered

| Req | Status | How |
|-----|--------|-----|
| API-01 | Done | `POST /v1/translate`, `GET /v1/languages` via Hono Edge Function |
| API-02 | Done | `POST /keys` generates, `DELETE /keys/:id` revokes, `PATCH /keys/:id` renames |
| API-03 | Done | Upstash fixed-window rate limiting, 429 + Retry-After + X-RateLimit-* headers |
| API-04 | Done | Scope middleware enforces translate:read/write/full permissions per endpoint |
| API-05 | Done | `api_key_usage` table writes per request + `GET /v1/usage` aggregation |
| API-06 | Done | `/v1/` prefix, `API-Version: v1` header on all responses |
| API-07 | Done | zod schemas on request bodies, 400 with validation details on failure |
| DATA-01 | Done | 6 new tables: organizations, organization_members, teams, team_members, api_keys, api_key_usage |
| DATA-02 | Done | org_id column on 9 existing tables via ADD COLUMN DEFAULT NULL |
| DATA-03 | Done | 30+ RLS policies migrated with org_id OR logic, consumer branch preserved |
| DATA-04 | Done | is_admin()/is_moderator() use organization_members, not raw_user_meta_data |
| DATA-05 | Done | validate_api_key() SQL function + Edge Function prefix + bcrypt validation |
| DATA-06 | Done | Upstash Ratelimit with fixed window, per-key rate_limit column override |

## Deployment Notes

1. Apply migrations in order: 0001 → 0007
2. Provision Upstash Redis instance and set env vars
3. Deploy both Edge Functions: `api-gateway` and `api-key-manage`
4. Run consumer client regression (iOS, Android, Web, Watch) after RLS migration
