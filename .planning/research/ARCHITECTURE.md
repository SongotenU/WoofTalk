# Architecture Research

**Domain:** M006 Enterprise — API Access, Admin Dashboard, Team/Org Management
**Researched:** 2026-04-02
**Confidence:** HIGH

## Executive Summary

WoofTalk's existing architecture (Supabase + 4 platform clients) needs selective extension for enterprise features. The critical insight: **all 4 existing clients use Supabase client SDKs directly** (no API gateway), which is fine for consumer users but insufficient for enterprise API consumers.

## 1. API Gateway Architecture

### Current State
All clients authenticate via Supabase auth → use client SDK to query PostgREST directly.

### New API Consumer Path
```
Third-party API → Supabase Edge Function (auth via API key) → PostgreSQL → Response
```

**Why Edge Functions, not PostgREST directly:**
- API keys are NOT Supabase session tokens — need custom auth middleware
- Rate limiting requires stateful tracking (token bucket in Upstash Redis)
- Response shape/versioning control (prevent schema leaks to consumers)
- Usage analytics tracking per API call

### Edge Function Design
```
POST /functions/v1/translate
  → Validate API key from header
  → Check rate limit (Upstash Redis)
  → Execute translation (reuse existing Edge Function logic)
  → Track usage (increment counter)
  → Return response

GET /functions/v1/usage
  → Validate API key
  → Return usage stats for period
```

### Data Model Additions
```sql
-- API key storage
api_keys (
  id, user_id (nullable), org_id (nullable),
  key_hash (bcrypt), name, scopes TEXT[],
  rate_limit_per_min DEFAULT 60,
  last_used_at, expires_at, created_at
)

-- Usage tracking (partitioned by month)
api_usage (
  id, api_key_id, endpoint, request_count,
  period_start, period_end
)
```

## 2. Admin Dashboard Architecture

### Integration with Existing Web App
Reuse existing Next.js web app — add `/admin/*` routes with:
- Server-side auth check (Supabase SSR pattern already in place)
- Role-gated middleware: only users with `role IN ('admin', 'moderator')` can access
- No new server needed

### Data Flow
```
Admin UI → Supabase (server component)
  → With elevated RLS policies for admin queries
  → Cross-org visibility via `is_admin()` or `is_moderator()` checks
```

### Existing Edge Functions Review (org-awareness gaps)
6 existing Edge Functions need `org_id` column addition:
- `auth-proxy` — no change needed (auth is org-agnostic)
- `translate-ai` — org-level rate limits
- `translate-ai-stream` — org-level rate limits
- `speech-to-text` — no change (compute-bound, not user-scoped)
- `text-to-speech` — no change
- `push-notification` — org-level notification routing

## 3. Organization & RBAC Architecture

### Schema Migration Strategy
```sql
organizations (
  id, name, slug, plan_type DEFAULT 'free',
  max_members DEFAULT 10,
  created_at, updated_at
)

organization_members (
  id, org_id, user_id,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by, invited_at, accepted_at,
  UNIQUE(org_id, user_id)
)

-- RLS extension pattern:
-- All existing tables need org_id column + new RLS policies
-- Example for users:
ALTER TABLE users ADD COLUMN org_id UUID REFERENCES organizations(id);
-- RLS: can read org members iff current_user is org member
```

### RLS Policy Pattern (Org-Scoped)
```sql
-- For any org-scoped table:
CREATE POLICY "org_members_read" ON community_phrases
  FOR SELECT
  USING (
    org_id IS NULL  -- public content
    OR org_id IN (
      SELECT org_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );
```

### Access Control Flow
```
1. User authenticates (Supabase Auth)
2. Edge Function extracts org_id from organization_members table
3. RLS policies enforce org-scoped access
4. Admin functions use `is_admin()` or role-based checks
```

## 4. Suggested Build Order

1. **F1: Role/Access Foundation** — `is_admin()`, `is_moderator()` function migration, org tables
2. **F2: API Gateway** — Edge Functions for API, key management, rate limiting
3. **F3: Admin Dashboard** — Next.js admin routes, moderation UI
4. **F4: Organizations** — Org CRUD, member invites, roles
5. **F5: Org API Keys** — Org-level key pool, shared usage
