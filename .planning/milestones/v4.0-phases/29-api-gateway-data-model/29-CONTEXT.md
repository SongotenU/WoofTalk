# Phase 29: API Gateway & Data Model - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a REST API for WoofTalk translation that third-party developers can call with API keys that are validated, rate-limited, scoped, tracked, and versioned — backed by a multi-tenant data model with org-scoped RLS policies.

Narrow scope: API exposes ONLY translation endpoints (v1). Community phrases and analytics endpoints deferred to Phase 30+. The API exists to enable third-party integrations of WoofTalk's core value (dog-to-human and human-to-dog translation), not to be a general-purpose platform.

</domain>

<decisions>
## Implementation Decisions

### API Surface & Contract
- API v1 exposes only translation endpoints (`POST /v1/translate`, `GET /v1/languages`)
- Response format matches existing web app translation response shape (bidirectional: human→dog and dog→human)
- No community, social, or analytics endpoints in this phase
- Versioned API with `v1` prefix; deprecation headers on responses

### API Key Lifecycle
- API keys generated per user or per organization (future)
- Keys are bcrypt-hashed in database; client receives plaintext only once (at generation)
- Key format: `wt_live_` prefix for readability (e.g., `wt_live_abc12345`)
- Default rate limit: 60 requests/minute per key (configurable)
- Rate limiting is per-key, not per-org (org-level rate limiting deferred)
- Key scopes: `translate:read` (human→dog), `translate:write` (dog→human), `translate:full` (both)
- Keys do not expire by default; can be revoked at any time

### Data Migration Strategy
- New tables: `organizations`, `organization_members`, `teams`, `team_members`, `api_keys`, `api_key_usage`
- `org_id` column added to all existing org-scoped tables using `ALTER TABLE ... ADD COLUMN ... DEFAULT NULL` (fast in PG 11+)
- Existing consumer users have `org_id = NULL` (no organization membership)
- Migration from `raw_user_meta_data->>'role'` to `organization_members` join table done during this phase
- Batched backfill for org_id on existing tables (no single large transaction)
- RLS policies use OR logic: `org_id IS NULL OR org_id IN (SELECT org_id FROM organization_members WHERE user_id = auth.uid())`

### Rate Limiting
- Upstash Redis for token bucket algorithm (Supabase free tier for Redis)
- Per-key rate limiting (not per-org at this stage)
- 429 response with `Retry-After` header and `X-RateLimit-Remaining` header
- Rate limit config stored on `api_keys` table per key

### Infrastructure
- Stack: Supabase Edge Functions (Deno) + Hono routing + zod validation + @upstash/ratelimit
- No separate API server; leverage existing 6 Edge Functions
- Existing `is_admin()`, `is_moderator()` SQL functions migrated to use `organization_members` instead of metadata

### Claude's Discretion
- Specific table column names and index strategies
- Edge Function file structure and deployment organization
- Error response shape details (as long as they match API contract style)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- 6 existing Supabase Edge Functions: `auth-proxy`, `translate-ai`, `translate-ai-stream`, `speech-to-text`, `text-to-speech`, `push-notification`
- 30+ existing RLS policies on 8 tables (all need org-scoped variants)
- Existing translation logic in Edge Functions can be reused behind API key auth
- Next.js web app already has Supabase client integration
- DATABASE_SCHEMA.md in v3.0 research has full table specifications

### Established Patterns
- Supabase RLS for authorization (database-level, not app-level)
- Edge Functions for server-side logic (Deno runtime)
- Client-side auth via Supabase auth SDK on all 4 platforms
- Translation fallback chain: AI → Vocabulary → Simple

### Integration Points
- POST /v1/translate → routes through Edge Function (auth via API key) → existing translation logic → response
- API key validation → Edge Function middleware → Upstash Redis for rate limit
- Usage tracking → `api_key_usage` table write on each request
- Existing iOS/Android/Web/Watch clients use Supabase auth sessions (NOT API keys) — must not break

</code_context>

<specifics>
## Specific Ideas

User wants to keep WoofTalk focused on its core vision: translating between human and dog language. The API exists to support this, not to become a platform play. Translation-only API scope for this phase.
</specifics>

<deferred>
## Deferred Ideas

- Community phrases API (POST /v1/phrases) — deferred to Phase 30+
- Analytics API endpoints — deferred to Phase 30+ (admin dashboard phase)
- API playground / interactive docs — deferred (Future Requirements: API-08)
- IP allowlisting per key — deferred (Future Requirements: API-09)
- SDK for API consumers — deferred (Future Requirements: API-10)
- Org-level rate limiting — deferred until organizational features exist

</deferred>
