# Pitfalls Research

**Domain:** M006 Enterprise — Adding API Access, Admin Dashboard, Team/Org Management to Existing Multi-Platform Product
**Researched:** 2026-04-02
**Confidence:** HIGH

## Critical Pitfalls (5)

### Pitfall 1: Exposing PostgREST Directly as Public API

**What goes wrong:**
Using Supabase's auto-generated PostgREST API as the consumer-facing API leaks database schema, provides no versioning control, and ties API contracts to internal table structures. When you inevitably change your database schema, all third-party integrations break.

**Why it happens:**
Supabase makes PostgREST so easy that it's tempting to just "let API consumers hit it directly." But PostgREST is designed for your own clients, not third-party consumers.

**Prevention:**
1. Always proxy API access through Edge Functions (already the recommended architecture)
2. Define explicit API response schemas independent of database tables
3. Version your API from day 1 (`/v1/`, `/v2/`)
4. Monitor API key usage separately from user sessions

**Phase to address:** Phase 29: API Gateway

### Pitfall 2: API Key Leakage in Client Bundles

**What goes wrong:**
Placing API keys or secrets in Next.js client bundles, iOS Info.plist, or Android strings.xml. Keys get extracted, leading to unlimited unauthorized usage and unexpected Supabase costs.

**Why it happens:**
Easy to confuse server-side API calls with client-side API calls in Next.js App Router. `use client` files get bundled and shipped.

**Prevention:**
1. Never expose API keys in any client code — all API key auth goes through Edge Functions
2. Use Supabase service keys only in server-side contexts (Edge Functions, server components)
3. Implement IP allowlisting for admin API access
4. Set key expiry with automatic rotation

**Phase to address:** Phase 29: API Gateway

### Pitfall 3: RBAC via String Metadata — Doesn't Scale

**What goes wrong:**
Current auth uses `raw_user_meta_data->>'role'` (string check in PostgreSQL) for admin/moderator flags. This pattern does not scale to multi-org RBAC where a user can be Owner in org_A, Admin in org_B, and just a consumer elsewhere. String comparisons in RLS policies become exponentially complex.

**Why it happens:**
Starts simple for a small app. When orgs are added, the metadata approach collides with org-scoped role requirements.

**Prevention:**
1. Create proper `organization_members` join table with role column (not metadata)
2. Use SQL functions like `user_has_role(user_id, org_id, role)` in RLS policies
3. Migrate existing `raw_user_meta_data` roles to the new table structure
4. Keep `raw_user_meta_data->>'role'` as a fallback during migration transition

**Phase to address:** Phase 30: Data Model & RBAC

### Pitfall 4: Schema Backfills Cause Downtime

**What goes wrong:**
Adding `org_id UUID` column to tables with existing user data (users, community_phrases, translations) requires full table scans. PostgreSQL 14+ acquires an ACCESS EXCLUSIVE lock during ALTER TABLE, blocking all reads/writes for the duration.

**Why it happens:**
Supabase's managed PostgreSQL makes it easy to run migrations interactively. On a table with 1M+ rows, `ALTER TABLE ... ADD COLUMN` can take minutes.

**Prevention:**
1. Use `ALTER TABLE ... ADD COLUMN ... DEFAULT NULL` (fast in PG 11+)
2. Backfill in batches with `UPDATE` chunks and `pg_sleep()` between batches
3. Run migrations during low-traffic windows
4. Consider adding org_id columns during v3.1→v4.0 transition when user base is still manageable

**Phase to address:** Phase 30: Data Model & RBAC

### Pitfall 5: Admin Dashboard Scope Creep

**What goes wrong:**
Starting with "just a simple user management panel" and building a full Salesforce-style admin tool before the actual enterprise features (API access, RBAC) exist. This delays revenue-generating capabilities by months.

**Why it happens:**
Admin dashboards feel productive — you can see and touch them. The invisible infrastructure work (API gateway, RLS policies) is harder to demo.

**Prevention:**
1. Scope admin MVP to: user list, content moderation (ban/report), role management
2. Defer: charts/dashboards, bulk operations, export features
3. Build admin UI last, after the data model it manages is stable
4. Prioritize API gateway before admin — real customers pay for API access, not admin panels

**Phase to address:** Phase 31: Admin Dashboard

## Moderate Pitfalls (4)

### Pitfall 6: Rate Limiting Per-Key Instead of Per-Org

**What goes wrong:**
Each API key has its own rate limit. An org with 5 keys can hit 5x the intended rate, defeating per-org pricing tiers.

**Prevention:** Rate limit at the org level (upstash key = `rl:org:{org_id}`), allow per-key overrides only as enterprise exceptions.

**Phase to address:** Phase 29: API Gateway

### Pitfall 7: Consumer Users Lose Data During Org Migration

**What goes wrong:**
When a consumer user joins an org, their existing translation history and community contributions become orphaned if the migration doesn't properly link their personal `org_id` to the organization.

**Prevention:** Implement explicit migration flow: `UPDATE translations SET org_id = ? WHERE user_id = ? AND org_id IS NULL` when user accepts org invite.

**Phase to address:** Phase 30: Data Model & RBAC

### Pitfall 8: API Response Shapes Diverge from Consumer App

**What goes wrong:**
The API returns data in a different format than the mobile/web clients expect, forcing you to maintain parallel response serializers or break one side.

**Prevention:** Use shared response types (TypeScript interfaces) between Edge Functions and web app. Document API response format explicitly.

**Phase to address:** Phase 29: API Gateway

### Pitfall 9: Role Escalation Through Org Membership

**What goes wrong:**
A user is org Admin, but the RLS policy accidentally allows them to promote themselves to Owner, or they retain admin privileges after leaving the org because the old `raw_user_meta_data->>'role'` check still passes.

**Prevention:** Explicit role transition logic (owner transfer requires current owner approval). Clean up old metadata roles during migration.

**Phase to address:** Phase 30: Data Model & RBAC

## Supabase-Specific Pitfalls (3)

### Pitfall 10: RLS Policy Explosion

**What goes wrong:**
30 RLS policies today → 90+ after adding org-scoped variants for every table. Debugging becomes impossible; policies contradict each other.

**Prevention:**
1. Use consistent naming convention: `{table}_{action}_{scope}` (e.g., `phrases_select_org_member`)
2. Test RLS policies with `EXPLAIN` to verify indexes are used
3. Consider combining OR conditions into single policies where possible
4. Document each policy's intent as a comment

### Pitfall 11: Auth Metadata Confusion

**What goes wrong:**
Existing Edge Function `is_admin()` checks `raw_user_meta_data->>'role'`. After adding org roles, there are now two places roles can live, and functions check the wrong one.

**Prevention:** Deprecate `is_admin()` during migration. Replace with `has_global_role('admin')` and `has_org_role(org_id, 'admin')`.

### Pitfall 12: Edge Functions Need org_id Awareness

**What goes wrong:**
Existing 6 Edge Functions don't accept or validate `org_id` parameters. Third-party API calls through the gateway bypass org-scoped business logic.

**Prevention:** Add org_id extraction from API key (join `api_keys → organizations`) and pass through all translate/stream functions.

## Pitfall-to-Phase Mapping

| Pitfall | Severity | Phase | Prevention |
|---------|----------|-------|------------|
| PostgREST as public API | CRITICAL | Phase 29: API Gateway | Always proxy through Edge Functions |
| API key leakage | CRITICAL | Phase 29: API Gateway | Server-side only, IP allowlisting |
| RBAC via string metadata | CRITICAL | Phase 30: Data Model & RBAC | Proper org_members table |
| Schema backfills downtime | CRITICAL | Phase 30: Data Model & RBAC | NULL columns, batched backfill |
| Admin scope creep | CRITICAL | Phase 31: Admin Dashboard | API first, admin last |
| Per-key rate limiting | MODERATE | Phase 29: API Gateway | Org-level rate limiting |
| Consumer data orphan | MODERATE | Phase 30: Data Model & RBAC | Explicit migration on join |
| API response divergence | MODERATE | Phase 29: API Gateway | Shared response types |
| Role escalation | MODERATE | Phase 30: Data Model & RBAC | Explicit role transitions |
| RLS policy explosion | MINOR | Phase 30: Data Model & RBAC | Naming convention, documentation |
| Auth metadata confusion | MINOR | Phase 30: Data Model & RBAC | Deprecate old patterns |
| Edge functions org-blind | MINOR | Phase 29: API Gateway | Pass org_id explicitly |

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Schema leaked to public API | MEDIUM | Migrate to Edge Function proxy, communicate breaking change to API consumers |
| API key compromise | LOW | Rotate all keys, implement key expiry, add IP allowlisting |
| Role escalation exploit | HIGH | Audit all org memberships, reset suspicious roles, add audit logging |
| RLS policy contradiction | HIGH | Full policy audit, simplify with OR conditions, add tests for each policy |
| Admin dashboard overbuilt | MEDIUM-HIGH | Defer admin features, focus engineering on API and RBAC |

---

*Pitfalls research for: M006 Enterprise — Adding API access, admin dashboard, team/org management*
*Researched: 2026-04-02*
