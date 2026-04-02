# Phase 29 Verification

## Requirements Checklist

| Req | Status | Evidence |
|-----|--------|----------|
| API-01 | PASS | `POST /v1/translate` and `GET /v1/languages` endpoints in `api-gateway/index.ts` |
| API-02 | PASS | `api-key-manage/index.ts`: POST/GET/DELETE/PATCH /keys |
| API-03 | PASS | `checkRateLimit()` in `_shared/rate-limit.ts`, 429 + headers in gateway middleware |
| API-04 | PASS | `checkScope()` in `_shared/api-key.ts`, scope middleware in gateway |
| API-05 | PASS | `api_key_usage` table (migration 0002), `trackUsage()` in `_shared/response.ts`, `GET /v1/usage` handler |
| API-06 | PASS | `API-Version: v1` header middleware in gateway, `/v1/` route prefix |
| API-07 | PASS | zod schemas + `zValidator` on `POST /v1/translate`, ZodError handler |
| DATA-01 | PASS | Migrations 0001 (org tables) + 0002 (api_keys tables) — 6 tables |
| DATA-02 | PASS | Migration 0004 — `ALTER TABLE ADD COLUMN org_id DEFAULT NULL` on 9 tables |
| DATA-03 | PASS | Migration 0005 — 30+ policies recreated with `org_id IS NULL OR org_id IN (...)` pattern |
| DATA-04 | PASS | Migration 0006 — `is_admin()`, `is_moderator()` use `organization_members` join |
| DATA-05 | PASS | Migration 0003 — `validate_api_key()` function + `_shared/api-key.ts` prefix+bcrypt |
| DATA-06 | PASS | Migration 0002 `api_keys.rate_limit` column + `_shared/rate-limit.ts` Upstash integration |

## Coverage: 13/13 requirements delivered

## Manual Test Commands (Pre-Deployment)

```bash
supabase db push        # Apply migrations
supabase functions deploy api-gateway
supabase functions deploy api-key-manage
```

## Post-Deployment Smoke Test

```bash
# 1. No key → 401
curl -sf -o /dev/null -w "%{http_code}" https://PROJECT.functions.supabase.co/functions/v1/api-gateway/v1/languages
# Expected: 401

# 2. Generate key → 201 + plaintext key
curl -sf -X POST -H "Authorization: Bearer USER_TOKEN" \
  -d '{"name":"test","scope":"translate:full"}' \
  https://PROJECT.functions.supabase.co/functions/v1/api-key-manage/keys

# 3. Valid key → 200
curl -sf -H "Authorization: Bearer wt_live_xxx" \
  https://PROJECT.functions.supabase.co/functions/v1/api-gateway/v1/languages

# 4. Invalid key → 401
curl -sf -o /dev/null -w "%{http_code}" -H "Authorization: Bearer wt_live_bogus" \
  https://PROJECT.functions.supabase.co/functions/v1/api-gateway/v1/languages

# 5. Invalid body → 400
curl -sf -o /dev/null -w "%{http_code}" -X POST \
  -H "Authorization: Bearer wt_live_xxx" \
  -d '{"bad":"body"}' \
  https://PROJECT.functions.supabase.co/functions/v1/api-gateway/v1/translate

# 6. Response headers include API-Version
curl -sI -H "Authorization: Bearer wt_live_xxx" \
  https://PROJECT.functions.supabase.co/functions/v1/api-gateway/v1/languages | grep API-Version
```
