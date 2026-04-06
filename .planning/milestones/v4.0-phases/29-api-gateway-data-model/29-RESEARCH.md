# Phase 29: API Gateway & Data Model - Research

**Researched:** 2026-04-02
**Domain:** REST API Gateway with Supabase Edge Functions / Deno / Hono
**Confidence:** MEDIUM

## User Constraints (from CONTEXT.md)

### Locked Decisions
- API v1 exposes only translation endpoints (`POST /v1/translate`, `GET /v1/languages`)
- Response format matches existing web app translation response shape (bidirectional: human-to-dog and dog-to-human)
- No community, social, or analytics endpoints in this phase
- Versioned API with `v1` prefix; deprecation headers on responses
- API keys generated per user or per organization (future)
- Keys are bcrypt-hashed in database; client receives plaintext only once (at generation)
- Key format: `wt_live_` prefix for readability (e.g., `wt_live_abc12345`)
- Default rate limit: 60 requests/minute per key (configurable)
- Rate limiting is per-key, not per-org (org-level rate limiting deferred)
- Key scopes: `translate:read` (human-to-dog), `translate:write` (dog-to-human), `translate:full` (both)
- Keys do not expire by default; can be revoked at any time
- New tables: `organizations`, `organization_members`, `teams`, `team_members`, `api_keys`, `api_key_usage`
- `org_id` column added to all existing org-scoped tables using `ALTER TABLE ... ADD COLUMN ... DEFAULT NULL` (fast in PG 11+)
- Existing consumer users have `org_id = NULL` (no organization membership)
- Migration from `raw_user_meta_data->>'role'` to `organization_members` join table done during this phase
- Batched backfill for org_id on existing tables (no single large transaction)
- RLS policies use OR logic: `org_id IS NULL OR org_id IN (SELECT org_id FROM organization_members WHERE user_id = auth.uid())`
- Upstash Redis for token bucket algorithm (Supabase free tier for Redis)
- Per-key rate limiting (not per-org at this stage)
- 429 response with `Retry-After` header and `X-RateLimit-Remaining` header
- Rate limit config stored on `api_keys` table per key
- Stack: Supabase Edge Functions (Deno) + Hono routing + zod validation + @upstash/ratelimit
- No separate API server; leverage existing 6 Edge Functions
- Existing `is_admin()`, `is_moderator()` SQL functions migrated to use `organization_members` instead of metadata

### Claude's Discretion
- Specific table column names and index strategies
- Edge Function file structure and deployment organization
- Error response shape details (as long as they match API contract style)

### Deferred Ideas (OUT OF SCOPE)
- Community phrases API (POST /v1/phrases) -- deferred to Phase 30+
- Analytics API endpoints -- deferred to Phase 30+ (admin dashboard phase)
- API playground / interactive docs -- deferred
- IP allowlisting per key -- deferred
- SDK for API consumers -- deferred
- Org-level rate limiting -- deferred until organizational features exist

## Summary

This phase builds a REST API gateway for WoofTalk's translation endpoints using Supabase Edge Functions with Hono, backed by a multi-tenant data model with org-scoped RLS. API key authentication replaces Supabase auth sessions for third-party consumers. Existing Edge Functions use `serve()` with manual URL routing and in-memory rate limiting; this phase replaces that with a proper framework (Hono) and external rate limiting (Upstash Redis).

The biggest risk is the RLS migration: 30+ existing policies must be extended to support `org_id` scoping without breaking the four existing consumer platform clients. The safe approach is `ALTER TABLE ADD COLUMN DEFAULT NULL` (fast, zero-lock) followed by batched backfills. The key edge case is the `NULL` org_id consumer users -- their existing RLS behavior must remain exactly `auth.uid() = user_id`, which the `org_id IS NULL` branch preserves.

**Primary recommendation:** Single Edge Function gateway (`api-gateway`) running Hono handles all `/v1/*` routes. API key validation happens as Hono middleware before routing to translate handlers. `api_key_usage` writes use the service role key and bypass RLS, but `api_keys` table validation happens in Edge Function space (bcrypt compare), not via SQL function in RLS. Rate limiting uses `@upstash/ratelimit` with `fixedWindow` algorithm for predictable 60 req/min windows.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `hono` | 4.x | HTTP routing + middleware | Lightweight, Deno-native, built-in bearerAuth middleware, `app.route()` for path grouping |
| `zod` | 3.x | Request/response validation | Standard TypeScript validation, integrates with Hono via zod validator |
| `@upstash/ratelimit` | 2.x | Per-key rate limiting | Token bucket / fixed window via HTTP (serverless-safe), integrates with Upstash Redis |
| `@upstash/redis` | 1.34+ | Upstash Redis client | Required peer dependency for @upstash/ratelimit; HTTP-based, no TCP needed |
| `bcrypt.js` | 2.x | API key hash/compare | Pure JS implementation works in Deno/Edge without native bindings; async API avoids blocking |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `crypto` (Deno std) | std@0.168+ | UUID/crypto helpers | Native Deno crypto API for generating API key secrets |
| `@std/uuid` (Deno std) | std@0.168+ | UUID v4 generation | Standard library UUID for key generation |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `hono` | `itty-router` or manual `URL` parsing | Hono is more mature, has middleware ecosystem, Deno template support |
| `bcrypt.js` (pure JS) | Deno `bcrypt` WASM or native module | Pure JS avoids WASM cold start overhead and deno.land compat issues |
| `@upstash/ratelimit` | Redis Lua scripts or in-memory Map | Upstash is HTTP-based (no TCP needed for Edge Functions), battle-tested for serverless |

**Installation:**
Supabase Edge Functions use import maps via `deno.json`. Each function directory gets its own dependency config:

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

The existing `_shared/middleware.ts` will be replaced by the new Hono-based middleware stack.

**Version verification:** 
- hono@4.x current on npm registry (verified 2026-04-02)
- @upstash/ratelimit@2.0.8 on npm (depends on @upstash/redis@^1.34.3)
- bcryptjs@2.4.3 stable on npm -- pure JS version recommended for Deno compatibility

## Architecture Patterns

### Recommended Project Structure
```
supabase/
├── functions/
│   ├── api-gateway/              # NEW: Main REST API gateway
│   │   ├── deno.json             # Import map for this function
│   │   └── index.ts              # Hono app with all /v1/* routes
│   ├── _shared/
│   │   ├── middleware.ts         # EXISTING: Auth, rate limit helpers (keep for non-gateway functions)
│   │   ├── api-key.ts            # NEW: API key validation, bcrypt compare, scope check
│   │   └── response.ts           # NEW: Standardized error/success response helpers
│   ├── translate/                # EXISTING: Web app translate function (keep for backward compat)
│   ├── translate-ai/             # EXISTING
│   ├── translate-ai-stream/      # EXISTING
│   ├── speech-to-text/           # EXISTING
│   ├── text-to-speech/           # EXISTING
│   └── send-push-notification/   # EXISTING
├── migrations/
│   ├── 000001_create_org_tables.sql       # NEW: organizations, org_members, teams, team_members
│   ├── 000002_create_api_key_tables.sql   # NEW: api_keys, api_key_usage
│   ├── 000003_add_org_id_columns.sql      # NEW: batched ALTER TABLE additions
│   ├── 000004_migrate_rls_policies.sql    # NEW: update 30+ policies with org_id scoping
│   └── 000005_migrate_role_functions.sql  # NEW: update is_admin/is_moderator to use org_members
└── seed/
    └── seed_test_data.sql                 # NEW: test organizations, members, API keys
```

### Pattern 1: Single Gateway Function with Hono Routing
**What:** One Edge Function handles all `/v1/*` routes through Hono's `app.route()` path grouping.

**When to use:** For a focused API surface of 2-3 endpoints, a single function is simpler than function-per-endpoint. The cold start cost is paid once instead of per-endpoint, and the Hono app structure is clean and testable.

**Example:**
```typescript
// supabase/functions/api-gateway/index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { bearerAuth } from 'hono/bearer-auth';
import { zValidator } from 'hono/zod-validator';
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';
import { apiGatewayRateLimit } from '../_shared/rate-limit.ts';
import { translateSchema, translateHandler } from './handlers/translate.ts';
import { languagesHandler } from './handlers/languages.ts';

const app = new Hono();

// Global middleware
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['authorization', 'content-type', 'x-api-version'],
  exposeHeaders: ['retry-after', 'x-ratelimit-remaining', 'x-ratelimit-limit'],
}));

// Version header middleware
app.use('/v1/*', async (c, next) => {
  c.header('API-Version', 'v1');
  c.header('Deprecation', ''); // Set deprecation date when v2 launches
  await next();
});

// API key auth middleware (custom, not just bearer auth)
app.use('/v1/*', async (c, next) => {
  const authHeader = c.req.header('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Missing or invalid API key', status: 401 }, 401);
  }
  const rawKey = authHeader.replace('Bearer ', '');
  
  // Validate: must start with wt_live_
  if (!rawKey.startsWith('wt_live_')) {
    return c.json({ error: 'Invalid API key format', status: 401 }, 401);
  }
  
  // bcrypt hash lookup and comparison in DB
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  const { data: keyRecord } = await supabase
    .from('api_keys')
    .select('id, key_hash, scope, rate_limit, is_revoked, org_id')
    .eq('key_prefix', rawKey.slice(0, 16))
    .single();
  
  if (!keyRecord || keyRecord.is_revoked) {
    return c.json({ error: 'Invalid or revoked API key', status: 401 }, 401);
  }
  
  // Compare bcrypt hash (async, non-blocking)
  const bcrypt = await import('bcrypt');
  const isValid = await bcrypt.compare(rawKey, keyRecord.key_hash);
  if (!isValid) {
    return c.json({ error: 'Invalid API key', status: 401 }, 401);
  }
  
  // Store in context for downstream middleware
  c.set('apiKey', {
    id: keyRecord.id,
    scope: keyRecord.scope,
    rateLimit: keyRecord.rate_limit,
    orgId: keyRecord.org_id,
  });
  
  await next();
});

// Rate limiting middleware
app.use('/v1/*', async (c, next) => {
  const apiKey = c.get('apiKey');
  const result = await apiGatewayRateLimit(apiKey.id, apiKey.rateLimit);
  
  c.header('X-RateLimit-Limit', String(result.limit));
  c.header('X-RateLimit-Remaining', String(result.remaining));
  
  if (!result.success) {
    const retryAfter = Math.ceil((result.reset - Date.now()) / 1000);
    c.header('Retry-After', String(retryAfter));
    return c.json({
      error: 'Rate limit exceeded',
      retry_after: retryAfter,
    }, 429);
  }
  
  await next();
});

// Route group: /v1
const v1 = new Hono();
v1.post('/translate', zValidator('json', translateSchema), translateHandler);
v1.get('/languages', languagesHandler);
app.route('/v1', v1);

// Error handler
app.onError((err, c) => {
  if (err.name === 'ZodError') {
    return c.json({
      error: 'Validation failed',
      details: err.issues,
    }, 400);
  }
  return c.json({ error: 'Internal server error' }, 500);
});

export default app;
```

### Pattern 2: API Key Validation Flow
**What:** Multi-step validation in Edge Function middleware: format check, DB lookup by prefix, bcrypt compare, scope check, rate limit check.

**Critical design decision:** Store a `key_prefix` column (first 16 chars of the plaintext key) for O(1) lookup, rather than iterating all keys for bcrypt comparison. This avoids N bcrypt hash comparisons per request. The prefix is indexed and used alone to retrieve the hash, then bcrypt.compare is run once.

**Example:**
```typescript
// Key generation
const rawKey = 'wt_live_' + crypto.randomUUID().replace(/-/g, '');
const keyPrefix = rawKey.slice(0, 16);
const keyHash = await bcrypt.hash(rawKey, 10);

await supabase.from('api_keys').insert({
  key_prefix: keyPrefix,
  key_hash: keyHash,
  scope: 'translate:full',
  rate_limit: 60,
  org_id: orgId || null,
});
```

### Pattern 3: Rate Limiting with Upstash Redis
**What:** Fixed window algorithm with per-key buckets via Upstash Redis HTTP API (no TCP connection needed).

**Redis key pattern:** `wooftalk:ratelimit:{key_id}:{window}` where window is the current minute bucket (`2026-04-02T14:30`). Use `@upstash/ratelimit` `fixedWindow` constructor for predictable 60 req/min.

**Configuration:**
```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: Deno.env.get('UPSTASH_REDIS_URL')!,
  token: Deno.env.get('UPSTASH_REDIS_TOKEN')!,
});

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.fixedWindow(60, '60s'),
  prefix: 'wooftalk:ratelimit',
});

// Usage: const { success, limit, remaining, reset } = await ratelimit.limit(keyId);
```

## Anti-Patterns to Avoid
- **In-memory rate limiting for API gateway:** The existing `_shared/middleware.ts` uses a `Map` for rate limits. This fails across Edge Function instances and restarts. Must use Redis.
- **Full bcrypt scan per request:** Iterating all API keys for bcrypt comparison is O(N) and will fail under load. Always use a prefix index for single-row lookup.
- **Service role key for external API requests:** The gateway MUST use service role key for API key validation queries (not anon key), since API key consumers are not Supabase-authenticated users.
- **Migrating RLS in a single transaction:** The 30+ policy update should be in one migration file but each `DROP POLICY` / `CREATE POLICY` pair is separate and idempotent.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rate limiting | In-memory token bucket | `@upstash/ratelimit` | Cross-instance consistency, Redis-backed, handles Edge Function restarts |
| API key hashing | Custom hash (sha256) | bcrypt.js | bcrypt is designed for secrets; includes salt and cost factor |
| Request validation | Manual field checking | zod | Type-safe, generates schemas from TypeScript types, integrates with Hono |
| HTTP routing | Manual URL parsing | hono | Handles method dispatch, middleware chain, error handling, CORS headers |
| UUID generation | Custom random strings | `crypto.randomUUID()` or `@std/uuid` | Standard, collision-free, consistent format |

**Key insight:** The existing codebase has in-memory rate limiting (`checkRateLimit` using a `Map`), custom auth validation (`validateAuth`), and manual request parsing. All of these are adequate for internal client-facing functions but will fail under the multi-tenant, unbounded traffic expectations of a public API.

## Runtime State Inventory

This is NOT a rename/refactor phase. This section is not applicable.

## Common Pitfalls

### Pitfall 1: RLS Policy Migration Breaking Existing Clients
**What goes wrong:** Updating RLS policies to add `org_id` scoping causes existing iOS/Android/Web/Watch clients to get 403 on their existing queries.

**Why it happens:** The `ALTER TABLE ... ADD COLUMN org_id ... DEFAULT NULL` is safe, but the RLS policy migration must preserve the original authorization check (`auth.uid() = user_id`) for NULL org_id rows. If the OR condition is wrong, consumer users lose access.

**How to avoid:** The policy logic MUST be:
```sql
-- For user-owned tables (translations, etc.)
CREATE POLICY "Users can view own {table}" ON public.{table}
    FOR SELECT
    USING (
        auth.uid() = user_id
        OR (org_id IS NOT NULL AND org_id IN (
            SELECT om.org_id FROM public.organization_members om
            WHERE om.user_id = auth.uid()
        ))
    );
```

The `auth.uid() = user_id` check MUST remain as the first OR branch. This handles consumer users (org_id IS NULL) AND org users' owned rows. The second branch grants org-scoped access for org-membered users.

**Warning signs:** Any policy that removes the original `auth.uid() = user_id` check will break existing clients. Every updated policy must be tested against a consumer user account.

### Pitfall 2: bcrypt in Deno Edge Functions (Cold Start and Performance)
**What goes wrong:** Pure JS bcrypt is slow (10 rounds takes ~100-300ms), and the import from esm.sh adds to cold start latency (1-3s first call).

**Why it happens:** Deno Edge Functions cold start is ~1s base. Adding bcrypt comparison pushes it to ~1.5-2s. Edge Functions have a 5s timeout for warm starts and ~120s for cold.

**How to avoid:** 
1. Use bcrypt.js (pure JS, not native/WASM) for reliable Deno compatibility
2. Salt rounds = 10 is the minimum safe; 12 is recommended but adds ~4x compute time
3. The bcrypt call happens once per API request AND is only needed if the prefix lookup succeeds (1 row). The cold start amortizes over subsequent requests to the same function instance.
4. If cold start is unacceptable after profiling, consider a 2-stage approach: fast hash lookup (sha256 of api_key id + raw key) in DB + bcrypt for generation/rotation only. This drops per-request crypto to a single DB query. **However, this weakens security and should only be done if profiling shows it's needed.**

### Pitfall 3: Upstash Redis Connection from Deno
**What goes wrong:** `@upstash/redis` attempts to use Node.js-specific APIs or TCP connections that fail in Deno's Edge Functions runtime.

**Why it happens:** `@upstash/redis` uses HTTP (REST API), not TCP, so it should work in Deno. However, `Redis.fromEnv()` relies on `process.env`, which doesn't exist in Deno.

**How to avoid:** Always use explicit constructor:
```typescript
const redis = new Redis({
  url: Deno.env.get('UPSTASH_REDIS_REST_URL')!,
  token: Deno.env.get('UPSTASH_REDIS_TOKEN')!,
});
```
NOT `Redis.fromEnv()`. The HTTP-based Upstash client is fully compatible with Deno.

### Pitfall 4: API Key Scope Enforcement Gap
**What goes wrong:** `translate:read` scope keys can call POST `/v1/translate` which creates translation records (a write operation).

**Why it happens:** The scope check middleware must map API key scopes to HTTP method + endpoint combinations, not just check "is this key valid."

**How to avoid:** Scope validation middleware before the rate limiter:
- `translate:read` allows GET `/v1/languages` only
- `translate:write` allows POST `/v1/translate` only
- `translate:full` allows all `/v1/*` endpoints

### Pitfall 5: Batched Backfill Locking
**What goes wrong:** Backfilling `org_id` on the `translations` table with thousands of rows causes table locks or transaction timeouts.

**Why it happens:** A single `UPDATE translations SET org_id = ...` without WHERE clause locks the entire table.

**How to avoid:** Use chunked updates:
```sql
DO $$
DECLARE
    batch_size INT := 1000;
    rows_affected INT;
BEGIN
    LOOP
        UPDATE public.translations SET org_id = NULL
        WHERE ctid IN (
            SELECT ctid FROM public.translations WHERE org_id IS NOT NULL
            LIMIT batch_size
        );
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        EXIT WHEN rows_affected = 0;
        PERFORM pg_sleep(0.1);
    END LOOP;
END $$;
```

## Code Examples

### API Key Generation (Admin/Edge Function)
```typescript
import bcrypt from 'bcrypt';
import { createClient } from '@supabase/supabase-js';

async function generateApiKey(supabase: any, userId: string, scope: string, name: string) {
  // 1. Generate raw key
  const rawKey = 'wt_live_' + crypto.randomUUID().replace(/-/g, '');
  const keyPrefix = rawKey.slice(0, 16);
  
  // 2. Hash with bcrypt (10 rounds)
  const salt = await bcrypt.genSalt(10);
  const keyHash = await bcrypt.hash(rawKey, salt);
  
  // 3. Store hash (client only ever receives rawKey)
  const { data, error } = await supabase
    .from('api_keys')
    .insert({ user_id: userId, name, key_prefix: keyPrefix, key_hash: keyHash, scope })
    .select('id')
    .single();
  
  if (error) throw error;
  
  // Return plaintext key to caller (never stored)
  return { id: data.id, key: rawKey };
}
```

### API Usage Tracking Middleware
```typescript
// Called after successful request processing (fire-and-forget)
async function trackUsage(supabase: any, keyId: string, endpoint: string, statusCode: number) {
  await supabase.from('api_key_usage').insert({
    api_key_id: keyId,
    endpoint,
    status_code: statusCode,
    created_at: new Date().toISOString(),
  });
  // Best called as non-blocking: don't await in request handler
  // Or batch into a queue for bulk insert
}
```

### Standard Error Response Shape
```typescript
// All errors match this shape for API consumers
interface ApiError {
  error: string;           // Human-readable message
  code?: string;           // Machine-readable error code (e.g., 'RATE_LIMITED')
  status: number;          // HTTP status code
  retry_after?: number;    // Seconds until rate limit resets
  details?: unknown;       // Zod validation errors array
}
```

### RLS Policy Migration Pattern (translations table)
```sql
-- BEFORE Phase 29: Original policy
DROP POLICY IF EXISTS "Users can view own translations" ON public.translations;

-- AFTER Phase 29: Extended for org-scoped access
CREATE POLICY "Users can view own translations" ON public.translations
    FOR SELECT
    USING (
        -- Original: consumer users, or any user viewing their own rows
        auth.uid() = user_id
        -- NEW: org members can access org-owned translations
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = translations.org_id
        ))
    );
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `serve()` + URL parsing per function | Single Hono gateway with route grouping | Now (this phase) | Centralized auth, validation, error handling |
| In-memory Map rate limiting | Upstash Redis fixed-window | Now (this phase) | Cross-instance, cross-cold-start rate limits |
| Supabase auth sessions for API auth | API key + bcrypt validation in Edge Function | Now (this phase) | Decouples third-party API access from user auth |
| `raw_user_meta_data->>'role'` for admin check | `organization_members` join table | Now (this phase) | Multi-tenant RBAC without metadata bloat |
| No API versioning | `/v1/` prefix + deprecation headers | Now (this phase) | Future-proof for v2 without breaking changes |

**Deprecated/outdated:**
- `Redis.fromEnv()` in Deno Edge Functions: Relies on `process.env` which is undefined in Deno. Use explicit `new Redis({ url, token })`.
- Import maps per-function (legacy Supabase pattern): The current recommendation is `deno.json` per function directory, NOT a global `import_map.json`.

## Open Questions

1. **Should `api_keys` table validation use an SQL function for RLS or Edge Function validation?**
   - What we know: CONTEXT.md mentions "API key validation via SQL function (bcrypt hash comparison for RLS policies)" (DATA-05)
   - What is unclear: Whether the SQL function is meant for Edge Function middleware validation AND RLS policy evaluation, or just for RLS
   - **Recommendation:** Validation happens in Edge Function middleware (faster, can short-circuit before DB queries). The SQL function (`validate_api_key(key)`) exists as a helper that Edge Functions can call via `supabase.rpc()` instead of direct table queries, AND can be used by RLS policies if the API gateway calls the translate backend via the anon key. However, the primary path (direct API key auth in gateway) should validate in middleware for speed.
   
2. **Should rate limit tracking be synchronous or async?**
   - What we know: Every request needs tracking in `api_key_usage` table
   - What is unclear: Whether the tracking write happens in the request handler (blocking) or after response (background)
   - **Recommendation:** Use fire-and-forget for tracking. The rate limit check via Upstash blocks, but the usage tracking write should not. This keeps API latency under the function timeout.

3. **Does the `api-gateway` Edge Function need to be deployed separately from existing translate functions?**
   - Yes. It should be a new function (`api-gateway`) while keeping existing `translate`, `translate-ai`, etc. for backward compatibility with iOS/Android/Web/Watch clients. The existing functions use Supabase auth. The new `api-gateway` uses API key auth. This keeps the two auth paths isolated.

4. **How many rows need org_id backfill?**
   - Unknown until runtime audit. The translations table may have thousands of rows. The batched migration should handle any volume gracefully.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Supabase project | All API endpoints, DB queries, Edge Functions runtime | Verified | Production | -- |
| Upstash Redis | Per-key rate limiting (@upstash/ratelimit) | Not yet set up in project | -- | In-memory rate limiting (unreliable, only for local dev) |
| Deno Edge Functions | API gateway deployment | Verified | Supabase Edge Functions | -- |
| Supabase CLI | Migration deployment | Required by CI/CD | Must be available | Manual SQL paste |
| `bcrypt.js` via esm.sh | API key hashing in Edge Functions | Available via esm.sh | 2.4.3 | Deno `bcrypt` module (WASM, untested in this project) |

**Missing dependencies with no fallback:**
- Upstash Redis instance must be provisioned (Supabase integration or standalone) before this phase can deploy rate limiting

**Missing dependencies with fallback:**
- `@upstash/ratelimit` can run in-memory mode as a temporary dev fallback, but MUST use Redis for production

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | No test framework detected in project |
| Config file | None |
| Quick run command | `npm test` (not configured) |
| Full suite command | Not available |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-01 | Translation endpoints exposed via Edge Functions | Manual (curl) | `curl -H 'Authorization: Bearer wt_live_xxx' POST /v1/translate` | Wave 0 |
| API-02 | API key generation and revocation | Manual | SQL verify in Supabase | Wave 0 |
| API-03 | Per-key rate limiting | Manual | Rapid request loop, verify 429 | Wave 0 |
| API-04 | API key scoping enforcement | Manual | Test out-of-scope request gets 403 | Wave 0 |
| API-05 | Usage tracking | Manual | Verify `api_key_usage` rows after requests | Wave 0 |
| API-06 | API versioning headers | Manual | Inspect response headers | Wave 0 |
| API-07 | Zod schema validation | Manual | Send invalid payload, verify 400 | Wave 0 |
| DATA-01 | New tables exist | Manual | SQL DESCRIBE | Wave 0 |
| DATA-02 | org_id columns added | Manual | SQL DESCRIBE | Wave 0 |
| DATA-03 | RLS policies enforce org isolation | Manual | Test cross-org access denied | Wave 0 |
| DATA-04 | Role functions use org_members | Manual | Test is_admin() for org users | Wave 0 |
| DATA-05 | API key validation via SQL | Manual | Test bcrypt compare function | Wave 0 |
| DATA-06 | Rate limit via Upstash | Manual | Test rate limit enforcement | Wave 0 |

### Sampling Rate
- Per task commit: Manual curl verification of each endpoint
- Per wave merge: Full regression test suite (once test framework is added)
- Phase gate: All endpoints must return correct HTTP status codes before `/gsd:verify-work`

### Wave 0 Gaps
- No test framework configured for this project
- Manual curl-based testing is the verification strategy for this phase
- Consider adding Jest/Vitest for Edge Function unit tests in a future phase

## Sources

### Primary (HIGH confidence)
- Hono documentation (hono.dev) - Verified routing, middleware, route grouping patterns
- @upstash/ratelimit npm package (v2.0.8) - Verified peer dependency on @upstash/redis@^1.34.3, response object shape
- Hono bearer auth middleware source (GitHub) - Verified custom verifyToken pattern
- Supabase Edge Functions docs (supabase.com) - Verified function structure, serve() handler, deno.json import maps
- bcrypt.js README (GitHub) - Verified pure JS compatibility, salt rounds, async API

### Secondary (MEDIUM confidence)
- @upstash/redis documentation - HTTP-based Redis client verified, Deno compatibility confirmed via explicit constructor
- Existing WoofTalk Edge Functions code - Patterns reviewed for backward compatibility
- Existing RLS policies (migration 002) - All 30+ policies reviewed for org-scoped migration

### Tertiary (LOW confidence)
- Deno Edge Functions cold start benchmarks - Exact cold start times vary by deployment region
- Upstash Redis Supabase integration availability - Should verify Supabase dashboard supports Upstash provisioning

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - Library versions verified against npm registry, but specific Deno import paths from esm.sh not runtime-tested
- Architecture: HIGH - Based on verified Hono API patterns, existing codebase analysis, and locked technical decisions from CONTEXT.md
- Pitfalls: MEDIUM - RLS migration edge cases identified from 30+ existing policy review; bcrypt/Deno performance estimates are training-data based

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (30 days - stable domain with mature libraries)
