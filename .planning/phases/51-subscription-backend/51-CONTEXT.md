# Phase 51: Subscription Backend - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Server-side subscription authority: RevenueCat webhooks update subscription_status, RLS enforces free-tier translation limits (3/day calendar UTC), Edge Functions verify entitlement server-side before processing premium requests. Adds subscription_status table, revenuecat_id to user_profiles, entitlement-webhook and entitlement-check Edge Functions, and RLS policies for free-tier gating. Does NOT include paywall UI (Phase 52) or client-side feature gating (Phase 53).

</domain>

<decisions>
## Implementation Decisions

### Webhook Event Scope
- **D-01:** Handle ALL RevenueCat webhook event types — not just the 5 listed in SUB-03. Every event type gets a handler (even if some are no-ops initially). Extensibility over minimalism.
- **D-02:** Webhook Edge Function authenticates incoming requests by verifying the Authorization header against the configured RevenueCat webhook secret. Reject unauthenticated requests with 401.

### Daily Limit Counting
- **D-03:** Free-tier translation limit is 3 per calendar day with UTC midnight reset. RLS policy checks `COUNT(*) WHERE created_at >= CURRENT_DATE AND user_id = auth.uid()` against subscription_status tier.
- **D-04:** Daily limit enforced via RLS-only (pure SQL). No Edge Function enforcement needed — RLS is the hard gate. The existing translate Edge Function benefits from RLS automatically since it inserts via service role (bypasses RLS), so the translate function must also do a manual tier check before inserting.

### subscription_status Schema
- **D-05:** subscription_tier uses PostgreSQL ENUM type (`'free'`, `'trial'`, `'pro'`). Type-safe, restricted values, efficient storage.
- **D-06:** Track purchase_platform as column (values: `ios`, `android`, `web`, `none`). Useful for cross-platform debugging and analytics.
- **D-07:** Store cancellation_reason column. Populated from RevenueCat webhook cancellation_reason field. Enables v2 win-back analytics (MON-01).

### Entitlement Caching Strategy
- **D-08:** 5-minute entitlement cache uses subscription_status table's updated_at column as TTL. If `updated_at < now() - interval '5 minutes'`, entitlement-check Edge Function re-fetches from RevenueCat REST API and UPDATEs the row. Survives deploys, shared across all Edge Function instances.
- **D-09:** No explicit cache invalidation needed. Webhooks update subscription_status immediately — the entitlement-check Edge Function sees fresh data on next call. The 5-min TTL guards against stale RevenueCat API data only (e.g., if a webhook was missed).

### Claude's Discretion
- Exact column names and types beyond the decided ones (user_id, revenuecat_id, entitlements, subscription_tier, trial_ends_at, purchase_platform, cancellation_reason, updated_at)
- Index definitions for fast RLS lookups (likely user_id PK + updated_at index)
- Webhook handler internal structure (switch/map per event type)
- Error handling patterns for RevenueCat API failures in entitlement-check
- Whether translate Edge Function should check subscription_status table or call entitlement-check function
- RLS policy SQL for the 3/day limit (exact WHERE clause)
- Migration file naming and structure

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### RevenueCat Integration
- `.planning/research/ARCHITECTURE.md` — Data flow diagrams, subscription lifecycle, suggested build order
- `.planning/research/PITFALLS.md` — Pitfall 3 (free tier bypass via API), Pitfall 6 (webhook idempotency failures) directly relevant
- `.planning/research/STACK.md` — RevenueCat REST API details, webhook event schema

### Existing Supabase Patterns
- `supabase/functions/_shared/middleware.ts` — validateAuth, checkRateLimit, corsHeaders patterns to reuse
- `supabase/functions/translate/index.ts` — Existing Edge Function pattern for reference (Deno, service role client, auth validation)
- `supabase/migrations/` — Migration naming convention and structure

### Phase 50 Context
- `.planning/phases/50-revenuecat-sdk-integration/50-CONTEXT.md` — Prior decisions on auth.uid identity, dual enforcement, EntitlementManager wrapper

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`_shared/middleware.ts`**: validateAuth, checkRateLimit, corsHeaders — reuse for webhook auth and entitlement-check Edge Function
- **`translate` Edge Function**: Pattern for Deno-based Edge Functions with Supabase service role client. Currently inserts to `translations` table — will need subscription check added.
- **6 Edge Functions**: Established patterns for error handling, CORS, auth validation
- **12 migrations**: Naming convention (0001_, 0002_, etc.) and SQL structure

### Established Patterns
- **Edge Functions**: Deno runtime, `serve()` from std/http, service role client for bypassing RLS, Bearer token auth via validateAuth
- **Rate limiting**: In-memory `Map<string, bucket>` token bucket — per-instance only, resets on deploy
- **RLS policies**: 30+ existing policies across 8 tables. Policy naming follows `"{table}_{operation}_{condition}"` pattern.
- **Migrations**: Sequential numbered files in `supabase/migrations/`

### Integration Points
- **`user_profiles` table**: Add `revenuecat_id` column (SUB-02). Existing table with user data.
- **`translations` table**: RLS policy for free-tier INSERT limit (3/day). Currently no tier-aware policies.
- **`translate` Edge Function**: Needs subscription tier check before processing. Currently just validates auth and inserts.
- **RevenueCat webhook URL**: Will be configured in RevenueCat dashboard pointing to `entitlement-webhook` Edge Function.

</code_context>

<specifics>
## Specific Ideas

- Product IDs: `wooftalk_monthly`, `wooftalk_annual` — set in Phase 50 context
- Entitlement ID: `pro` — single entitlement that unlocks all premium features
- Webhook idempotency: Use `event_id` from RevenueCat as idempotency key — SUB-04. Idempotent UPDATE, not INSERT — SUB-05.
- Webhook must return 200 OK quickly, process updates async if needed — SUB-05
- Edge Functions that handle premium requests must check subscription_status before processing — SUB-10
- The translate Edge Function currently uses service role (bypasses RLS) — needs explicit tier check since RLS won't apply to service role inserts

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 51-subscription-backend*
*Context gathered: 2026-04-15*
