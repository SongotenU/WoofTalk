# Project Research Summary

**Project:** M006 Enterprise — API Access, Admin Dashboard, Team/Org Management
**Domain:** Enterprise SaaS features layered onto an existing multi-platform consumer app (Supabase + 4 platform clients)
**Researched:** 2026-04-02
**Confidence:** HIGH

## Executive Summary

WoofTalk is a multi-platform translation product built on Supabase with four existing clients (Android, iOS, Web, Wear OS) that all authenticate via Supabase Auth and query PostgREST directly. M006 adds enterprise-grade capabilities: a third-party API with key management and rate limiting, an admin dashboard for moderation and user management, and multi-organization support with RBAC. This is not a greenfield product -- it is a selective extension of an architecture that works well for consumers but is insufficient for enterprise API consumers.

The recommended approach is a three-lane build order: (1) foundational data model and RBAC migration, (2) API gateway via Supabase Edge Functions with Upstash Redis rate limiting, (3) admin dashboard and organization management as parallel tracks after foundations are stable. Everything stays within the existing Supabase + Next.js ecosystem -- no new backend services, no GraphQL layer, no external RBAC platform. The existing 6 Edge Functions need org_id awareness injected, and all existing tables need org-scoped RLS policies added.

The key risk is the data model migration: adding `org_id` columns to tables with existing user data can cause PostgreSQL lock contention and downtime if done naively. The second risk is RBAC done via string metadata (current state) which doesn't scale to multi-org. Both are mitigated by the phased migration strategy detailed in PITFALLS.md: NULL-default column additions, batched backfills, and proper `organization_members` join tables. Admin scope creep is also a real danger -- the admin UI must be built last, after the data model it manages is stable.

## Key Findings

### Recommended Stack

**Core technologies:**
- **Supabase Edge Functions (Deno):** API proxy + rate limiting -- already deployed, shares Supabase auth context, no new platform
- **Upstash Redis:** Distributed rate limiting cache -- serverless, sub-ms latency, token bucket pattern, zero infra
- **PostgreSQL (existing):** API key storage (bcrypt hashes), org tables, usage tracking -- extends current database
- **Next.js App Router (existing web):** Admin UI host with `/admin/*` routes -- zero new server, reuse SSR pattern
- **shadcn/ui + @tanstack/react-table + Recharts:** Admin component stack -- matches existing web patterns exactly
- **Supabase RLS (existing):** Authorization enforcement extended to org context -- `org_id` on all scoped tables

**What NOT to add:** No separate GraphQL layer, no dedicated admin framework (Refine/AdminBro), no external RBAC service (Permit.io/Oso), no separate backend service. The existing stack is sufficient.

### Expected Features

**Must have (table stakes):**
- API key generation, naming, scoping, and revocation -- basic credential management
- Per-key and per-org rate limiting -- prevent abuse and enforce pricing tiers
- API usage dashboard -- visibility into consumption
- Admin user list with search/filter -- basic user management
- Content moderation queue with ban/suspend -- safety enforcement
- Role management (Owner/Admin/Member/Viewer) -- org access control
- Organization creation and email invite with expiry -- org onboarding
- Basic audit log -- who did what, when

**Should have (competitive differentiators):**
- Per-key usage alerts (email/webhook) -- proactive management
- IP allowlisting per key -- extra security layer
- API playground (interactive docs) -- developer experience
- Usage-based billing tiers -- flexible pricing
- Custom translation packs per org -- domain-specific value

**Defer (v2+):**
- SSO/SAML integration -- high complexity, not table stakes for initial enterprise
- Team workspaces -- org-level content separation can wait
- Automated spam detection for enterprise -- high complexity
- Custom billing inside admin dashboard -- anti-feature (confuses roles)

### Architecture Approach

Enterprise API consumers require an API gateway layer -- the existing architecture where all clients query PostgREST directly is fine for consumers but leaks schema and provides no versioning or rate limiting. The new architecture introduces Edge Functions as an API proxy with explicit response schemas, Upstash Redis for rate limiting, and org-aware RLS policies throughout.

**Major components:**
1. **API Gateway (Edge Functions):** Proxies third-party requests, validates API keys, enforces rate limits, tracks usage, returns versioned response schemas
2. **Data Model Extensions:** New tables (`organizations`, `organization_members`, `api_keys`, `api_usage`) plus `org_id` columns on existing tables
3. **Admin Dashboard (Next.js routes):** Server-side auth, role-gated middleware, elevated RLS policies for cross-org admin queries
4. **Org-Aware RLS Layer:** SQL functions (`user_has_role`, `is_admin`) replace string metadata checks, all tables get org-scoped policies
5. **Edge Function Org Injection:** 4 of 6 existing Edge Functions need `org_id` parameter addition for org-level rate limits and routing

### Critical Pitfalls

1. **Exposing PostgREST directly as public API** -- Never proxy third-party consumers through PostgREST. Always use Edge Functions with explicit, versioned response schemas.
2. **API key leakage in client bundles** -- All auth keys must stay server-side. Use Edge Functions only for any API key-bearing requests. Implement key expiry and IP allowlisting.
3. **RBAC via string metadata doesn't scale** -- Current `raw_user_meta_data->>'role'` approach breaks for multi-org. Must migrate to proper `organization_members` join table with role column.
4. **Schema backfills cause downtime** -- Adding `org_id` to tables with existing data requires NULL-default columns, batched backfills with `pg_sleep()`, and low-traffic timing.
5. **Admin dashboard scope creep** -- Build API gateway first, admin UI last. MVP to user list, moderation, and role management. Defer charts, bulk ops, exports.

## Implications for Roadmap

Based on combined research, the dependency chain dictates a 3-phase structure after existing v3.1:

### Phase 29: API Gateway
**Rationale:** This is the revenue-generating capability and the most technically complex piece. It must exist before org-scoped API keys (Phase 30 extension) and before the admin dashboard monitors API usage. Rate limiting infrastructure (Upstash) is needed first.
**Delivers:** Third-party API via Edge Functions, API key CRUD (generate/scope/revoke), per-org rate limiting with Upstash, usage tracking, versioned response schemas, shared TypeScript response types
**Addresses features:** API key generation/revocation, per-key rate limiting, usage dashboard, key scoping, key naming
**Avoids:** PostgREST exposure (Pitfall 1), API key leakage in client bundles (Pitfall 2), per-key instead of per-org rate limiting (Pitfall 6), API response divergence (Pitfall 8)

### Phase 30: Data Model & RBAC
**Rationale:** Cannot safely build organization management without the role infrastructure. Must migrate from string metadata to proper join tables before any org-scoped data exists. Schema additions require careful batching.
**Delivers:** `organizations` and `organization_members` tables, `org_id` on all existing tables, RLS policy migration from metadata checks to SQL functions, migration functions for existing user data
**Addresses features:** Create organization, invite members, role hierarchy (Owner/Admin/Member/Viewer), remove/transfer ownership, email invites with expiry
**Avoids:** RBAC via string metadata (Pitfall 3), schema backfill downtime (Pitfall 4), consumer data orphan on org join (Pitfall 7), role escalation through org membership (Pitfall 9), RLS policy explosion (Pitfall 10), auth metadata confusion (Pitfall 11)

### Phase 31: Admin Dashboard
**Rationale:** Built last because it depends on the stable data model from Phase 30 and monitors the API gateway from Phase 29. Building it earlier creates scope creep and work against an unstable schema.
**Delivers:** Next.js `/admin/*` routes (user list with search/filter, content moderation queue, ban/suspend, role management, basic audit log), elevated RLS policies for admin queries, FCM admin alerts
**Addresses features:** User list, role management, content moderation, ban/suspend, audit log
**Avoids:** Admin scope creep (Pitfall 5), billing managed inside admin (anti-feature)

### Phase Ordering Rationale

- Phase 29 before Phase 31 because the admin dashboard monitors API usage data that Phase 29 produces
- Phase 30 runs in parallel with or immediately after Phase 29 because API keys reference `org_id` but Phase 29 can start with nullable `org_id` for individual-user keys
- Phase 31 is last because it depends on both stable API usage data (Phase 29) and the org-scoped data model (Phase 30)
- RLS policy changes (Phase 30) affect ALL existing clients -- must be tested before any Phase 31 admin UI goes live

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 29 (API Gateway):** Needs detailed research on Upstash token bucket implementation patterns with Deno Edge Functions, and API versioning strategy for the translate/stream endpoints
- **Phase 30 (Data Model & RBAC):** Needs careful research on batched migration scripts for the specific Supabase PostgreSQL instance, especially for tables with potential 1M+ rows

Phases with standard patterns (skip research-phase):
- **Phase 31 (Admin Dashboard):** Next.js + shadcn/ui + react-table patterns are well-documented and match the existing web app. Standard CRUD patterns with Supabase SSR are established.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations reuse existing infrastructure (Supabase + Next.js). Upstash is a well-documented serverless Redis option with native Deno support. |
| Features | HIGH | Table stakes derived from standard enterprise SaaS patterns. Complexity assessments are grounded in existing architecture. |
| Architecture | HIGH | Edge Function gateway, org-scoped RLS, and Next.js admin routes are proven patterns. Specific Supabase integration points verified against existing project. |
| Pitfalls | HIGH | All 12 pitfalls are specific to this project's architecture, not generic warnings. Each mapped to a phase with concrete prevention strategy. |

**Overall confidence:** HIGH

### Gaps to Address

- **Edge Function compatibility:** The 4 of 6 existing Edge Functions that need `org_id` injection have not been individually audited for parameter compatibility. This should be validated during Phase 29 planning.
- **Upstash cost modeling:** Rate limiting tokens for the entire API surface need cost estimation against projected API consumer volume before committing to the service.
- **Existing table row counts:** The migration safety of `ALTER TABLE` with batched backfills depends on actual data volume. Row counts for `users`, `community_phrases`, and `translations` tables should be checked before Phase 30.
- **Consumer client impact:** Adding RLS policies with org-scoped OR conditions may affect query performance for the 4 existing clients. Should be load-tested in Phase 30.

## Sources

### Primary (HIGH confidence)
- Supabase official documentation -- Edge Functions, RLS policies, PostgREST behavior, Auth metadata handling
- Upstash documentation -- Redis rate limiting with Deno, token bucket patterns
- PostgreSQL documentation -- ALTER TABLE locking behavior, batched UPDATE performance
- Next.js App Router documentation -- Server Components, middleware, SSR patterns with Supabase

### Secondary (MEDIUM confidence)
- Community patterns for multi-tenant Supabase applications -- org-scoped RLS policy design
- Standard enterprise SaaS API design -- key management, rate limiting, usage tracking patterns

### Tertiary (LOW confidence)
- Performance impact of OR-heavy RLS policies at scale -- needs validation with actual data volume

---
*Research completed: 2026-04-02*
*Ready for roadmap: yes*
