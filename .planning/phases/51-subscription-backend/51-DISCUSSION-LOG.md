# Phase 51: Subscription Backend - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 51-subscription-backend
**Areas discussed:** Webhook event scope, Daily limit counting, subscription_status schema, Entitlement caching strategy

---

## Webhook Event Scope

| Option | Description | Selected |
|--------|-------------|----------|
| SUB-03 only (5 events) | Handle INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, TRIAL_STARTED only. Other events logged but no state change. | |
| Extended (8 events) | Also handle BILLING_ISSUE, PRODUCT_CHANGE, TRANSFER. Real lifecycle events. | |
| All events | Handle every RevenueCat webhook event type. Most comprehensive. | ✓ |

**User's choice:** All events — handle every RevenueCat webhook event type
**Notes:** User wants comprehensive handling upfront. Extensibility over minimalism.

| Option | Description | Selected |
|--------|-------------|----------|
| Verify webhook secret | Validate Authorization header against configured RevenueCat webhook secret. Prevents spoofed calls. | ✓ |
| No verification | No authentication on webhook endpoint. Simpler but insecure. | |

**User's choice:** Verify webhook secret — validate Authorization header on every request
**Notes:** Standard approach to prevent spoofed webhook calls.

---

## Daily Limit Counting

| Option | Description | Selected |
|--------|-------------|----------|
| Calendar day (UTC reset) | Counter resets at 00:00 UTC. Simple RLS: COUNT where created_at >= CURRENT_DATE. | ✓ |
| Rolling 24h window | 3 translations in any 24-hour sliding window. Harder in RLS. | |
| Calendar day (user-local) | Calendar day but user's timezone. Requires storing timezone preference. | |

**User's choice:** Calendar day with UTC midnight reset
**Notes:** Simplest to implement in RLS SQL. Predictable for users.

| Option | Description | Selected |
|--------|-------------|----------|
| RLS-only (pure SQL) | RLS policy checks tier + COUNT today's inserts < 3. No Edge Function needed for enforcement. | ✓ |
| Edge Function check | Edge Function checks before inserting. More flexible but bypassable via direct Supabase calls. | |
| Dual (RLS + Edge Function) | Both RLS hard gate and Edge Function soft check. Most secure but most code. | |

**User's choice:** RLS-only pure SQL — COUNT today's inserts < 3 for free tier
**Notes:** RLS is the hard gate. Note: translate Edge Function uses service role (bypasses RLS), so it needs explicit tier check added.

---

## subscription_status Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Enum | PostgreSQL ENUM type for subscription_tier. Type-safe, restricted values. | ✓ |
| TEXT + CHECK constraint | Flexible, can add tiers without migration. Slight typo risk. | |

**User's choice:** PostgreSQL ENUM type
**Notes:** Type safety preferred. Tiers: free, trial, pro.

| Option | Description | Selected |
|--------|-------------|----------|
| Track platform | Add purchase_platform column (ios/android/web/none). Useful for analytics and debugging. | ✓ |
| Don't track | No platform column. RevenueCat has this data. Simpler schema. | |

**User's choice:** Track platform — add purchase_platform column
**Notes:** Useful for cross-platform debugging and analytics.

| Option | Description | Selected |
|--------|-------------|----------|
| Store cancellation reason | Add cancellation_reason column. Enables v2 win-back analytics. | ✓ |
| Don't store | No cancellation reason. RevenueCat has this data. Simpler now. | |

**User's choice:** Store cancellation_reason column
**Notes:** Low cost now, enables MON-01 win-back offers in v2.

---

## Entitlement Caching Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Table-based TTL | Use subscription_status.updated_at column. If >5min old, re-fetch from RevenueCat API. Survives deploys, shared across instances. | ✓ |
| In-memory (like rate limiter) | Same Map pattern as rate limiting. Fast but resets on deploy, per-instance. | |
| Upstash Redis | Fast, shared, survives deploys. Adds external dependency. | |

**User's choice:** Table-based TTL using subscription_status.updated_at
**Notes:** No new infrastructure. Survives deploys. All Edge Function instances share same cache.

| Option | Description | Selected |
|--------|-------------|----------|
| Webhook-driven | Webhook updates subscription_status immediately. No explicit invalidation needed. 5-min TTL is guard for missed webhooks. | ✓ |
| Explicit invalidation | Set flag/timestamp on webhook to force next entitlement-check to skip cache. | |

**User's choice:** Webhook-driven (no explicit invalidation)
**Notes:** Webhooks already update the table in real time. Cache TTL is just a safety net for missed webhooks.

---

## Claude's Discretion

- Exact column names and types beyond decided ones
- Index definitions for fast RLS lookups
- Webhook handler internal structure (switch/map per event type)
- Error handling patterns for RevenueCat API failures
- Whether translate Edge Function checks subscription_status table directly or calls entitlement-check function
- RLS policy SQL for the 3/day limit
- Migration file naming and structure

## Deferred Ideas

None — discussion stayed within phase scope
