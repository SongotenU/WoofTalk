# Technology Stack -- Enterprise Features Addendum

**Project:** WoofTalk
**Scope:** API access, admin dashboard, team/org management (M006)
**Researched:** 2026-04-02
**Extends:** Existing stacks from v3.0 (Android) and v3.1 (Web/Watch)

---

## Executive Summary

This document covers ONLY what is new or modified for M006 enterprise features. The existing stack (Supabase backend, Next.js web app with shadcn/ui, iOS/Android/watch clients) remains unchanged. Three capability areas are addressed: (1) REST API with key-based auth for third-party integrations, (2) admin dashboard for user/content moderation and analytics, (3) organization/team hierarchy with RBAC and SSO. The guiding principle is **augment Supabase, don't replace it** -- leverage existing Edge Functions (6 already deployed), PostgreSQL, and auth infrastructure wherever possible.

---

## Recommended Stack Additions

### 1. External API Layer (REST)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Supabase Edge Functions (Deno)** | Deno 2.x (bundled with Supabase CLI) | Custom REST API endpoints with API key auth | Already in the project (6 functions exist). Zero new infrastructure. Direct PostgreSQL access. Deployed by Supabase. |
| **Hono** | 4.x | API routing within Edge Functions | Lightweight, Edge-native, native Deno support. Superior to Express on Edge runtimes. Minimal bundle size (~14KB). |
| **zod** | 3.x | Request/response schema validation | Type-safe validation at API boundary. Generates TypeScript types. Works with Hono via zod validator middleware. |
| **@upstash/ratelimit** | 2.x | Rate limiting per API key | Works with Redis (Upstash free tier: 10K req/day). Token bucket + sliding window algorithms. Native Deno support. |
| **Upstash Redis** | Free tier | Rate limit state storage | Serverless Redis, pay-per-use. ~1ms latency. Pairs with @upstash/ratelimit. Already the standard for Edge rate limiting. |

**Why NOT build a separate API server:** A standalone Node/Express/Fastify server adds infrastructure complexity (hosting, scaling, auth handoff from Supabase, cross-origin setup). Supabase Edge Functions already provide serverless compute co-located with your database. The only limitation is Deno runtime (not Node.js), which Hono handles elegantly.

**Why NOT GraphQL:** WoofTalk's API surface for third parties will be modest (translation endpoints, phrase access, analytics read). A well-designed REST API with zod-validated schemas is sufficient. Apollo federation or Pothos GraphQL adds complexity for marginal benefit at scale <100 API consumers. Revisit at 10K API consumers.

### 2. API Key Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Custom table: `api_keys`** | -- | API key storage, scoping, usage tracking | No existing Supabase feature handles external API key lifecycle. Custom table is the standard pattern. |
| **`@oslojs/crypto`** | 2.x (deno.land/x) | Secure API key generation | Cryptographically secure random bytes + encoding. Same library used by Lucia Auth. Superior to built-in crypto.randomUUID(). |
| **`bcrypt` (bcrypt edge)** | -- (deno.land/x) | API key hashing before storage | Store hashes, not plaintext keys. Standard security practice. |
| **Supabase Database Functions (SQL)** | PostgreSQL 15+ | Key validation at row level | RLS policies can validate API keys via SQL functions for direct table access patterns. |

**API Key Model:**
```sql
-- New tables in existing PostgreSQL database
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  billing_email TEXT,
  plan TEXT DEFAULT 'free', -- free, team, enterprise
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- admin, member, viewer
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- admin, member
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  permissions JSONB DEFAULT '[]',
  is_system BOOLEAN DEFAULT FALSE, -- system roles cannot be deleted
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  key_hash TEXT NOT NULL, -- bcrypt hash of the actual key
  key_prefix TEXT NOT NULL, -- first 8 chars for display (e.g., "wt_live_abc12345")
  scopes TEXT[] DEFAULT '{}', -- ['translation:read', 'phrases:read', 'analytics:read']
  rate_limit_per_minute INT DEFAULT 60,
  expires_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE TABLE api_key_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INT,
  response_time_ms INT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for API key validation (hot path)
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_key_usage_api_key_id_timestamp ON api_key_usage(api_key_id, timestamp DESC);
```

### 3. Admin Dashboard UI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Next.js App Router** | 15.x (already in project) | Admin dashboard host | Already the web app framework. Admin routes live at `/admin/*` within same codebase. Zero new framework. |
| **shadcn/ui** | Latest (already in project) | Admin UI components | Already in project. Consistent design language. Components: Table, Dialog, Dropdown, Badge, Card, Tabs, Select -- all admin-relevant. |
| **TanStack Table (React Table)** | 8.x | Admin data tables with pagination, sorting, filtering | Industry standard for React data tables. Headless (works with shadcn Table). Handles virtualization for 10K+ rows. Used by Stripe, Linear, Vercel dashboards. |
| **Tremor** | 3.x | Analytics charts and metrics dashboard | Built on Recharts. Purpose-built for dashboards. Components: Metric, BarChart, LineChart, DonutChart, AreaChart -- exactly what admin analytics need. Better integration with Tailwind/shadcn than raw Chart.js. |
| **React Hook Form** | 7.x | Admin form management (moderation actions, org settings) | Superior controlled form performance. Zod integration via @hookform/resolvers. Less re-renders than Formik. |
| **nuqs** | 2.x | URL state management for admin filters/sorting | Type-safe URL search params. Replaces useQueryParams/qs. Perfect for admin table state (page, sort, filter) that should be bookmarkable/sharable. |

**Why NOT separate admin app:** A `/admin/*` route within the existing Next.js app shares auth (Supabase Auth), UI components (shadcn), deployment (same Vercel project), and middleware. A separate admin dashboard app (e.g., Refine, Strapi admin) doubles deployment surface, requires SSO bridge, and fragments the component library. Only split into separate deployment if admin users need independent uptime SLA from the main app.

**Why NOT Refine/React-Admin:** These frameworks bring their own routing, data providers, and UI. WoofTalk already has a custom Next.js app with shadcn/ui. Refine's value proposition (admin CRUD from day one) is outweighed by the cost of integrating it into an existing codebase. TanStack Table + shadcn/ui = 80% of Refine's capability with native integration.

### 4. RBAC (Role-Based Access Control)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Supabase RLS (Row Level Security)** | Built-in | Row-level data isolation per org/team | Already implemented (30+ policies). Extend with org_id-based policies. The most robust RBAC layer -- enforced at database level, not application level. |
| **Supabase Custom JWT Claims** | Built-in | Embed org/role in auth tokens | Via Edge Function or PostgREST, add custom claims to JWT. Client and Edge Functions can read user's org membership without additional query. |
| **PostgreSQL Enum Types** | PostgreSQL 15+ | Role/permission type safety | `CREATE TYPE org_role AS ENUM ('owner', 'admin', 'member', 'viewer')`. Database-enforced valid values. Superior to TEXT columns. |
| **Permission matrix in SQL function** | PostgreSQL 15+ | Centralized permission checks | `user_has_permission(user_id, org_id, permission)` function used by both RLS policies and Edge Functions. Single source of truth. |

**RBAC Architecture:**
```
Organization (top-level)
  |-- members (user + role: owner/admin/member/viewer)
  |-- teams (optional sub-grouping)
  |     `-- members (user + role: admin/member)
  |-- roles (custom, with JSONB permissions)
  |-- api_keys (scoped to org)
  `-- data (all tables get org_id column)

Permission model:
  - owner: full access, billing, delete org
  - admin: manage members, teams, API keys, content moderation
  - member: use API, view analytics, manage own resources
  - viewer: read-only analytics, no mutations

RLS policy pattern for all new admin tables:
  CREATE POLICY "org_isolation" ON table_name
    USING (
      organization_id IN (
        SELECT organization_id FROM organization_members
        WHERE user_id = auth.uid()
      )
    );
```

### 5. SSO Support (Enterprise)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Supabase Auth SSO (SAML)** | Built-in (Pro plan +) | Enterprise SSO via SAML 2.0 | Supabase natively supports SAML SSO on Pro plans ($25/org/month). No custom SSO infrastructure needed. Azure AD, Okta, Google Workspace, OneLogin all supported. |
| **Supabase Auth SSO (OIDC)** | Built-in (Pro plan +) | OpenID Connect SSO | Supabase supports OIDC for organizations that prefer OIDC over SAML. Same Pro plan requirement. |

**If self-hosting SSO or on free plan:** Use Clerk (clerk.com, from $25/mo) or Better Auth (open source, from 2024) as auth provider instead of Supabase Auth. Clerk has superior SSO features, org management, and RBAC out of the box. **Recommendation:** Start with Supabase SSO (Pro plan). Migrate to Clerk only if Supabase SSO feature gaps emerge.

**Why NOT build custom OAuth2 server:** Building an OAuth2/OpenID provider (e.g., Keycloak, custom) for a single application is 3-6 months of undifferentiated work. Supabase provides SSO as a platform feature. The complexity is in SAML assertion parsing, certificate rotation, SCIM provisioning, and SLO (single logout) -- all solved problems in Supabase Auth.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| API runtime | Supabase Edge Functions (Deno) | Node.js server (Fastify/Express) | Adds hosting, deployment, auth bridge complexity. Edge Functions are co-located with DB, already deployed. |
| API routing | Hono | Express, Fastify | Express/Fastify are Node.js-first. Hono is designed for Edge runtimes (Deno, Cloudflare Workers) with identical API to both. |
| GraphQL | None (REST only) | Apollo GraphQL, Pothos | API surface too small for GraphQL complexity. REST with zod schemas is faster to build and debug. |
| Rate limiting | @upstash/ratelimit | Custom Redis, Supabase native | Supabase has no built-in rate limiting for custom endpoints. Custom Redis requires provisioning. Upstash is serverless and Edge-native. |
| Admin framework | Next.js + TanStack Table + shadcn | Refine, React-Admin, Strapi | Already have Next.js + shadcn/ui. Admin frameworks fight existing patterns. TanStack Table provides the heavy lifting (sorting, pagination, virtualization) without framework lock-in. |
| Charts | Tremor | Recharts, Chart.js, D3 | Tremor is built on Recharts with Tailwind-ready styling. Lower abstraction cost than Chart.js. Less complexity than D3. Perfect for admin dashboard KPIs and trends. |
| RBAC enforcement | Supabase RLS + SQL functions | Casbin, Oso, application-level middleware | Application-level RBAC can be bypassed by direct DB access. RLS is enforced at the database layer. Casbin/Oso add another dependency layer without database-level protection. |
| SSO | Supabase Auth SAML/OIDC | Custom Keycloak, Auth0, Clerk | Supabase already handles auth. Adding SSO as a feature of existing Auth is simplest. Keycloak is overkill (self-hosted, complex). Auth0 is more expensive. Clerk is viable alternative if Supabase SSO gaps exist. |
| Form management | React Hook Form + Zod | Formik, react-final-form | React Hook Form has fewer re-renders, better TypeScript support, and direct Zod integration via @hookform/resolvers. Formik is maintenance-mode. |
| URL state | nuqs | use-debounce + qs, zustand | nuqs is purpose-built for URL search params with full TypeScript. State in zustand/local state is lost on refresh and not shareable. |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Separate API server (Express/Fastify/NestJS)** | Duplicates deployment, requires auth bridge from Supabase, adds hosting cost | Supabase Edge Functions with Hono |
| **GraphQL (Apollo/Pothos/urql server)** | Overkill for WoofTalk's API surface; REST is simpler and faster to build | REST with Hono + zod schemas |
| **Standalone admin framework (Refine, Strapi)** | Fights existing Next.js + shadcn/ui setup; doubles deployment surface | TanStack Table + shadcn/ui in existing Next.js app |
| **Custom OAuth2 server (Keycloak, custom)** | 3-6 months build time; battle-tested solutions already exist | Supabase SAML SSO (Pro plan) |
| **Separate auth provider just for SSO** | Fragmented auth surface; Supabase already handles auth | Extend Supabase Auth with SSO |
| **Heavy charting library (D3, Nivo, Victory)** | Excessive for admin KPIs; Tremor covers all dashboard needs | Tremor (built on Recharts) |
| **RBAC library (Casbin, Oso)** | Application-level enforcement can be bypassed; RLS is database-level | Supabase RLS policies + SQL permission functions |
| **API gateway (Kong, AWS API Gateway)** | Overengineering for <100 API consumers; Edge Functions provide rate limiting + auth | @upstash/ratelimit + Hono middleware |
| **Admin-specific backend (Strapi, Directus)** | Would duplicate existing Supabase data model; two truth sources | Admin routes in Next.js querying existing Supabase tables |
| **Docker/containers for API** | Supabase Edge Functions are already deployed, scaled, and monitored by platform | Supabase Edge Functions |

---

## Integration with Existing Stack

### How New Components Connect to Existing Supabase Backend

```
+-------------------------------------------------------------------+
|                        EXTERNAL API                               |
|  Third-party integrations (partners, ISVs, enterprise clients)    |
+-------------------------------+-----------------------------------+
                                | POST /api/v1/translate
                                |      (Authorization: Bearer wt_live_xxx)
                                | GET  /api/v1/phrases
                                | GET  /api/v1/analytics
                                v
+-------------------------------------------------------------------+
|              Supabase Edge Functions (Deno + Hono)                |
|  +-------------------------------------------------------------+  |
|  |  API Key Middleware                                         |  |
|  |  - Extract key from Authorization header                    |  |
|  |  - Hash + lookup in api_keys table                          |  |
|  |  - Check revoked, expired, rate limit                       |  |
|  |  - Log usage to api_key_usage table                         |  |
|  +-------------------------------------------------------------+  |
|  +-------------------------------------------------------------+  |
|  |  Translation Endpoint  -->  PostgreSQL phrases              |  |
|  |  Analytics Endpoint    -->  Aggregation queries             |  |
|  |  Phrases Endpoint      -->  Filtered community_phrases      |  |
|  +---------------------------+---------------------------------+  |
+------------------------------+------------------------------------+
                               |
                               v
+-------------------------------------------------------------------+
|                    POSTGRESQL (Supabase)                          |
|  +------------+ +----------+ +----------+ +--------------------+  |
|  | org tables | | api_keys | |  RLS on  | | existing 8 tables  |  |
|  | + teams    | | + usage  | | all new  | | + org_id column    |  |
|  |            | |          | | tables   | | added              |  |
|  +------------+ +----------+ +----------+ +--------------------+  |
+-------------------------------------------------------------------+

+-------------------------------------------------------------------+
|                    ADMIN DASHBOARD                                |
|  Next.js App Router (/admin/* routes) within existing web app     |
|  +-------------------------------------------------------------+  |
|  |  User Management  (TanStack Table + shadcn/ui)              |  |
|  |  Content Moderation (queue, approve, reject, ban)           |  |
|  |  Analytics         (Tremor charts + metrics)                |  |
|  |  Org/Team Mgmt     (invite, roles, API key management)      |  |
|  |  Settings          (SSO config, billing, permissions)       |  |
|  +-------------------------------------------------------------+  |
|                                                                   |
|  Supabase Auth: admin role gate via RLS + custom JWT claims      |
|  Data: Direct Supabase client (same SDK as existing web app)     |
+-------------------------------------------------------------------+
```

### Database Schema Changes Required

All existing tables need an `organization_id` reference for enterprise multi-tenancy:

```sql
-- Add org_id to existing tables (nullable for B2C users)
ALTER TABLE users ADD COLUMN organization_id UUID REFERENCES organizations(id);
ALTER TABLE contributions ADD COLUMN organization_id UUID REFERENCES organizations(id);
ALTER TABLE community_phrases ADD COLUMN organization_id UUID REFERENCES organizations(id);

-- Index for org-scoped queries
CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_contributions_org ON contributions(organization_id);
```

### Edge Function Structure

```
supabase/functions/
  api/                           # New: External REST API
    index.ts                     # Hono app with all routes
    middleware/
      api-key.ts                 # API key validation middleware
      rate-limit.ts              # @upstash/ratelimit middleware
      cors.ts                    # CORS for external consumers
    routes/
      translate.ts               # POST /api/v1/translate
      phrases.ts                 # GET /api/v1/phrases
      analytics.ts               # GET /api/v1/analytics
  admin/                         # New: Admin-only Edge Functions
    index.ts                     # Admin action endpoints (ban, approve)

  [existing 6 Edge Functions]    # Unchanged
```

---

## Installation

```bash
# New npm dependencies (for Next.js admin dashboard)
npm install @tanstack/react-table@8.21 @tremor/react@3.18
npm install react-hook-form@7.55 @hookform/resolvers@4.1
npm install nuqs@2.4

# Supabase CLI update (for Edge Function development)
npm install -g supabase@2.x

# Upstash (for rate limiting in Edge Functions)
# Install via: supabase secrets set UPSTASH_REDIS_URL=xxx UPSTASH_REDIS_TOKEN=xxx
# Then import in Edge Functions: import { Ratelimit } from "https://deno.land/x/upstash/ratelimit/mod.ts"

# @oslojs/crypto (for API key generation in Edge Functions)
# Import in Edge Functions: import { sha256 } from "https://deno.land/x/@oslojs/crypto@2.0.0/mod.ts"
```

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Hono 4.x | Deno 2.x (Supabase Edge Functions runtime) | Native Deno support, zero bundle config needed |
| @upstash/ratelimit 2.x | Deno via deno.land/x URL | Import from deno.land, not npm |
| TanStack Table 8.x | React 19, Next.js 15 | Headless -- pairs with any UI library |
| Tremor 3.x | React 18+, Tailwind 3/4, Next.js App Router | Requires Tailwind already in project (confirmed) |
| React Hook Form 7.x | React 19, Next.js 15 | @hookform/resolvers@4.x for Zod 3.x |
| nuqs 2.x | Next.js 15 App Router | Uses native Next.js searchParams |
| Supabase SSO/SAML | Pro plan ($25/org/month) | Not available on free tier |

---

## API Endpoint Design (Recommended)

```
POST /api/v1/translate
  Header: Authorization: Bearer wt_live_<key>
  Body: { "text": "hello", "direction": "human_to_dog", "language": "en" }
  Response: { "translation": "woof woof", "quality": 0.92, "method": "ai" }

GET /api/v1/phrases?page=1&limit=50&sort=votes&direction=dog_to_human
  Header: Authorization: Bearer wt_live_<key>
  Response: { "data": [...], "meta": { "total": 1523, "page": 1 } }

GET /api/v1/analytics/usage?period=30d
  Header: Authorization: Bearer wt_live_<key>
  Response: { "total_requests": 15230, "avg_response_ms": 145, "error_rate": 0.02 }
```

**API Key format:** `wt_live_<random>` for production, `wt_test_<random>` for sandbox. The `wt_` prefix identifies WoofTalk keys. `live`/`test` environment separation. Key is shown once at creation, then only the prefix (first 8 chars) is displayed for identification.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Supabase Edge Functions + Hono for API | HIGH | Edge Functions already in project (6 exist). Hono is the standard Deno routing library. |
| API key model (custom table) | HIGH | Standard pattern when no built-in key management exists. Supabase has no native external API key feature. |
| Rate limiting with Upstash | HIGH | Industry standard for Edge rate limiting. Deno-native. |
| Admin dashboard: Next.js + TanStack Table | HIGH | Extends existing Next.js app. TanStack Table is the de facto standard for React data tables. |
| Tremor for analytics charts | MEDIUM | Tremor 3.x is solid, but Tremor 4.x has API changes. May need to pin version. Verify compatibility with existing Tailwind setup. |
| RBAC via Supabase RLS | HIGH | RLS already in project (30+ policies). Org-scoped RLS policies are a natural extension. |
| SSO via Supabase SAML/OIDC | MEDIUM | Feature exists on Pro plans but requires verification of current plan availability and limitations. Flag: verify Supabase SSO capabilities before committing SSO to roadmap. |
| nuqs for URL state | HIGH | Purpose-built for Next.js 15 App Router. |
| GraphQL deferral | HIGH | Justified by API surface size. Revisit at scale. |

---

## Sources

- Supabase Auth SSO docs: supabase.com/docs/guides/auth/enterprise-sso (confidence: MEDIUM -- feature exists on Pro plans, verify current tier availability)
- Supabase Edge Functions: supabase.com/docs/guides/functions (confidence: HIGH -- core Supabase feature, already in project with 6 functions)
- Supabase RLS: supabase.com/docs/guides/auth/row-level-security (confidence: HIGH -- already implemented with 30+ policies)
- Hono Edge runtime: hono.dev/docs/getting-started/deno (confidence: HIGH -- standard Deno/Edge HTTP framework)
- TanStack Table v8: tanstack.com/table/latest (confidence: HIGH -- de facto standard for React tables)
- Tremor dashboard: tremor.so/docs/getting-started/installation (confidence: HIGH -- purpose-built dashboard library on Recharts)
- @upstash/ratelimit: upstash.com/docs/ratelimit (confidence: HIGH -- standard Edge rate limiting)
- nuqs: nuqs.47ng.com (confidence: HIGH -- purpose-built for Next.js URL state)
- React Hook Form + Zod: react-hook-form.com/get-started#SchemaValidation (confidence: HIGH -- standard React form pattern)
- RBAC with Supabase RLS: Based on Supabase RLS architecture pattern (confidence: HIGH -- RLS is the standard way to enforce org-scoped access)

---

*Stack research for: M006 Enterprise Features (API access, admin dashboard, org/team management)*
*This document augments the existing stacks from v3.0/v3.1; it does not replace them.*
*Researched: 2026-04-02*
