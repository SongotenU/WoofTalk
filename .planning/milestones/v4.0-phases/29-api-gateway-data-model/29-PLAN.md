# Phase 29: API Gateway & Data Model - Execution Plan

**Goal**: Third-party developers can call WoofTalk APIs with API keys that are validated, rate-limited, scoped, tracked, and versioned — backed by a multi-tenant data model with org-scoped RLS policies.

**Depends on**: Phase 28 (existing Supabase backend stable)

**Requirements**: API-01–API-07, DATA-01–DATA-06 (13 total)

---

## Execution Strategy

**5 waves**, each independently testable. Migrations first (foundation), then gateway (surface), then validation (quality).

**Wave order**: migrations → tables → gateway → key-lifecycle → verification

---

## Wave 1: Database Schema — New Tables (DATA-01, DATA-05)

**Objective**: Create 6 new tables with indexes, RLS, and API key validation SQL function.

### Tasks

#### 1.1 Migration 001 — Organization Tables
Create `organizations`, `organization_members`, `teams`, `team_members` tables.

```sql
-- supabase/migrations/0001_organizations.sql
```

**Tables**:
- `organizations`: id (uuid), name, slug (unique), plan_type (free/pro/enterprise), owner_id (uuid → auth.users), created_at, updated_at
- `organization_members`: id, org_id (→ organizations), user_id (→ auth.users), role (owner/admin/member/viewer), joined_at, status (active/invited/suspended), invite_token (unique, nullable), invite_expires_at (nullable)
- `teams`: id, org_id (→ organizations), name, created_at
- `team_members`: id, team_id (→ teams), user_id (→ auth.users), joined_at

**RLS**: Enable on all 4 tables. Base policies:
- organizations: owner can manage own org; members can read their org
- organization_members: members can read own org membership; owner/admin can manage
- teams/team_members: org members can read; org admin can manage

**Indexes**:
- `organization_members(org_id, user_id)` unique
- `organizations(slug)` unique
- `teams(org_id)`
- `team_members(team_id, user_id)` unique

#### 1.2 Migration 002 — API Key Tables
Create `api_keys`, `api_key_usage` tables.

```sql
-- supabase/migrations/0002_api_keys.sql
```

**Tables**:
- `api_keys`: id, user_id (→ auth.users), org_id (nullable, → organizations), name, key_prefix (varchar(16)), key_hash (text), scope (translate:read/translate:write/translate:full), rate_limit (int, default 60), is_revoked (boolean, default false), created_at, revoked_at (nullable)
- `api_key_usage`: id, api_key_id (→ api_keys), endpoint (text), status_code (int), created_at (timestamped for time-series queries)

**RLS**:
- api_keys: owner/org-admin can read own keys; insert via service role only
- api_key_usage: read via service role only; write via service role

**Indexes**:
- `api_keys(key_prefix)` — for O(1) prefix lookup during validation
- `api_keys(user_id)` — for user's key listing
- `api_keys(org_id)` — for org key listing
- `api_key_usage(api_key_id, created_at)` — for usage queries
- `api_key_usage(created_at)` — for time-range analytics

#### 1.3 Migration 003 — API Key Validation SQL Function
Create `validate_api_key(raw_key)` function for DATA-05.

```sql
-- supabase/migrations/0003_api_key_function.sql
```

SQL function that takes a raw API key, looks up by prefix, and returns the key record (without hash). Used by Edge Functions via `supabase.rpc('validate_api_key', { raw_key: 'wt_live_...' })`.

Function logic:
1. Extract prefix (first 16 chars)
2. Look up `api_keys` where `key_prefix = prefix AND is_revoked = false`
3. Return record (id, user_id, org_id, scope, rate_limit, key_hash) — caller bcrypt-compares

#### 1.4 Verification
- `supabase db reset` locally or manual deployment
- Verify tables: `\dt organizations organization_members teams team_members api_keys api_key_usage`
- Verify indexes: `\di` on each table
- Verify function: `select validate_api_key('wt_live_test')` returns null (no keys yet)
- Test RLS: insert test org as service role, verify anon can't read it

---

## Wave 2: Database Schema — Migration of Existing Tables (DATA-02, DATA-03, DATA-04)

**Objective**: Add `org_id` to all org-scoped tables, migrate 30+ RLS policies, update role functions.

### Tasks

#### 2.1 Migration 004 — Add org_id Columns
`ALTER TABLE ... ADD COLUMN org_id uuid DEFAULT NULL` on all org-scoped tables.

Tables needing `org_id`:
- `translations`
- `community_phrases`
- `social_follows`
- `social_likes`
- `social_comments`
- `user_settings`
- `notification_preferences`
- `activities`

**Approach**: Single migration file, each `ALTER TABLE` is its own statement (fast in PG 11+, zero-lock for ADD COLUMN with DEFAULT NULL).

```sql
-- supabase/migrations/0004_add_org_id_columns.sql
```

#### 2.2 Migration 005 — Update RLS Policies
Drop and recreate 30+ policies with org-scoped variants.

**Pattern for user-owned tables** (translations, settings, etc.):
```sql
USING (
  auth.uid() = user_id
  OR (org_id IS NOT NULL AND auth.uid() IN (
    SELECT om.user_id FROM public.organization_members om
    WHERE om.org_id = {table}.org_id
  ))
)
```

**Pattern for shared tables** (community_phrases, activities):
```sql
USING (
  org_id IS NULL
  OR (org_id IS NOT NULL AND auth.uid() IN (
    SELECT om.user_id FROM public.organization_members om
    WHERE om.org_id = {table}.org_id
  ))
)
```

**Critical**: Consumer users with `org_id IS NULL` on rows they own still pass via `auth.uid() = user_id` branch. The `OR` logic preserves backward compatibility.

```sql
-- supabase/migrations/0005_migrate_rls_policies.sql
```

#### 2.3 Migration 006 — Migrate Role Functions
Update `is_admin()` and `is_moderator()` SQL functions to check `organization_members.role` instead of `raw_user_meta_data->>'role'`.

```sql
-- supabase/migrations/0006_migrate_role_functions.sql
```

New `is_admin()`:
```sql
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin')
    AND status = 'active'
  );
$$ LANGUAGE sql SECURITY DEFINER;
```

#### 2.4 Verification
- Deploy migrations in order: 004, 005, 006
- Verify columns: `\d translations` shows org_id column
- Verify policies: `SELECT count(*) FROM pg_policies WHERE schemaname = 'public'` matches expected count
- Run backward-compat test: verify consumer user (no org membership) can still read their own translations via `auth.uid() = user_id` check

---

## Wave 3: API Gateway — Core Infrastructure (API-01, API-06, API-07)

**Objective**: Deploy Hono-based Edge Function with validation, versioning, and translation handlers.

### Tasks

#### 3.1 Create `api-gateway` Edge Function
New Edge Function at `supabase/functions/api-gateway/`.

**Structure**:
```
supabase/functions/
├── api-gateway/
│   ├── deno.json           # Import map
│   ├── index.ts            # Hono app entry
│   └── handlers/
│       ├── translate.ts    # POST /v1/translate + GET /v1/languages
│       └── usage.ts        # GET /v1/usage (key owner usage endpoint)
├── _shared/
│   ├── middleware.ts       # Existing (untouched)
│   ├── api-key.ts          # NEW: API key validation
│   ├── rate-limit.ts       # NEW: Upstash rate limiting
│   └── response.ts         # NEW: Standard error helpers
```

#### 3.2 deno.json Import Map
```json
{
  "imports": {
    "hono": "https://esm.sh/hono@4",
    "hono/": "https://esm.sh/hono@4/",
    "zod": "https://esm.sh/zod@3",
    "@upstash/ratelimit": "https://esm.sh/@upstash/ratelimit@2",
    "@upstash/redis": "https://esm.sh/@upstash/redis@1.34",
    "bcrypt": "https://esm.sh/bcryptjs@2.4.3",
    "@supabase/supabase-js": "https://esm.sh/@supabase/supabase-js@2"
  }
}
```

#### 3.3 Shared Utilities

**`api-key.ts`** — API key validation:
- `validateApiKey(rawKey, supabase)`: format check → prefix lookup → bcrypt compare → return record
- `checkScope(scope, method, endpoint)`: scope → endpoint permission mapping

**`rate-limit.ts`** — Upstash rate limiting:
- `createRateLimiter()`: returns Upstash Ratelimit instance with fixed window
- `checkRateLimit(keyId, rateLimit)`: wrapper that returns { success, remaining, reset }

**`response.ts`** — Standardized responses:
- `apiError(c, message, status, code, details?)`
- `apiSuccess(c, data, meta?)`

#### 3.4 Hono App Entry (`index.ts`)

**Middleware stack** (executed in order):
1. CORS (global)
2. Version header (add `API-Version: v1`, `Deprecation` headers)
3. API key auth (`/v1/*`)
4. Scope check (`/v1/*`)
5. Rate limit (`/v1/*`)

**Routes**:
- `POST /v1/translate` → translate handler
- `GET /v1/languages` → languages handler
- `GET /v1/usage` → usage dashboard endpoint

**Error handler**: ZodError → 400 with details; unexpected → 500

#### 3.5 Translate Handler (`handlers/translate.ts`)

**`POST /v1/translate`**:
- zod schema validation: `{ source_language, target_language, text }`
- Reuse existing translation logic from translate Edge Function
- Response shape matches existing web app: `{ id, human_text, animal_text, source_language, target_language, confidence, quality_score, created_at }`
- Fire-and-forget usage tracking to `api_key_usage` table

**`GET /v1/languages`**:
- Return supported language list (static or from vocabulary config)
- No auth required beyond valid API key

#### 3.6 Usage Handler (`handlers/usage.ts`)

**`GET /v1/usage`**:
- Query `api_key_usage` for current key's recent activity
- Returns: `{ total_requests, successful, errors, last_request_at, usage_by_endpoint: [...] }`
- Scope: only returns data for the calling key

#### 3.7 Deploy and Smoke Test
- `supabase functions deploy api-gateway`
- curl test (without key): expect 401
- curl test (with invalid key): expect 401
- curl test (with valid key, invalid body): expect 400 with Zod errors
- curl test (with valid key, valid body): expect 200/201

---

## Wave 4: API Key Lifecycle — Generation & Management (API-02, API-03, API-04, API-05)

**Objective**: API key generation, naming, revocation, scoping, and rate limit enforcement.

### Tasks

#### 4.1 API Key Generation Edge Function
New function `supabase/functions/api-key-manage/` for key lifecycle (uses Supabase auth, not API key auth).

**Endpoints**:
- `POST /keys` — generate new key (body: `{ name, scope, org_id? }`)
- `GET /keys` — list user's keys (without hashes)
- `DELETE /keys/:id` — revoke key
- `PATCH /keys/:id` — update key name or scope

**Generation logic**:
```typescript
const rawKey = 'wt_live_' + crypto.randomUUID().replace(/-/g, '');
const keyPrefix = rawKey.slice(0, 16);
const keyHash = await bcrypt.hash(rawKey, 10);
// Insert into api_keys, return { id, key: rawKey } to caller
```

**Auth**: Uses existing `validateAuth()` from `_shared/middleware.ts` (Supabase session auth).

#### 4.2 Rate Limit Enforcement in Gateway

Integrate Upstash rate limiting into gateway middleware:
- `@upstash/ratelimit` with `fixedWindow(60, '60s')` as default
- Per-key override from `api_keys.rate_limit` column
- 429 response with `Retry-After`, `X-RateLimit-Remaining`, `X-RateLimit-Limit` headers

#### 4.3 Scope Enforcement in Gateway

Scope → permission mapping:
- `translate:full` → all `/v1/*` endpoints
- `translate:read` → `GET /v1/languages` only
- `translate:write` → `POST /v1/translate` only
- Other scope + endpoint → 403 `{ error: 'Insufficient scope', code: 'INSUFFICIENT_SCOPE' }`

#### 4.4 Usage Tracking

Write `api_key_usage` record after each successful API call:
- Called as fire-and-forget (non-blocking) to avoid adding latency to response
- Fields: `api_key_id`, `endpoint`, `status_code`, `created_at`

#### 4.5 Verification
- Generate key via `api-key-manage` function
- Verify `wt_live_` format, bcrypt hash in DB
- Test rate limit: send 61 rapid requests, verify 429 on 61st
- Test scope: use `translate:read` key on POST, verify 403
- Test revocation: revoke key, verify 401 on next call
- Test usage: query usage endpoint, verify request counted

---

## Wave 5: Integration & Hardening

**Objective**: End-to-end validation of all phase 29 requirements.

### Tasks

#### 5.1 E2E Test: Full API Flow
1. Create org (via SQL/service role)
2. Create API key for org member
3. Call `POST /v1/translate` with the key
4. Verify translation returned, usage recorded
5. Call `GET /v1/usage` to verify usage dashboard
6. Verify response has `API-Version: v1` header

#### 5.2 RLS Isolation Test
1. Create org A and org B with separate members
2. Org A member's API key calls API
3. Verify org A member cannot read org B's data (cross-org query returns empty)

#### 5.3 Consumer Client Regression
- Verify existing translate function (`supabase/functions/translate/`) still works with Supabase session auth
- Verify org_id=NULL rows are accessible by their original owners via `auth.uid() = user_id` RLS branch

#### 5.4 Environment Variables Documentation
Document required env vars for api-gateway:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_TOKEN`

#### 5.5 Update PROJECT.md and ROADMAP.md
- Mark phase 29 as complete
- Update STATE.md

---

## Dependencies & Risks

| Risk | Mitigation |
|------|-----------|
| Upstash not provisioned | Wave 1-3 don't need Redis; rate limiting degrades to pass-through. Document as prerequisite for Wave 4. |
| RLS migration breaks existing clients | Preserve `auth.uid() = user_id` as first OR branch. Test consumer users before merging. |
| bcrypt cold start >5s | Use prefix-based O(1) lookup (not full table scan). Salt rounds = 10 minimum. |
| Migration lock on large tables | `ALTER TABLE ADD COLUMN DEFAULT NULL` is fast in PG 11+. No batched backfill needed for DEFAULT NULL. |

## Success Criteria

1. ✅ Third-party can call translate API with API key and receive versioned JSON matching declared schema
2. ✅ Requests exceeding per-key rate limit are rejected with 429 + Retry-After header
3. ✅ API key can be generated, named, scoped, and revoked; scoped keys reject out-of-scope ops
4. ✅ API usage tracked per key and queryable via usage endpoint
5. ✅ Multi-tenant DB operational: all 6 tables exist, org_id on org-scoped tables, RLS enforces isolation, API key validation works
