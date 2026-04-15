# Phase 51: Subscription Backend - Research

**Researched:** 2026-04-15
**Domain:** Server-side subscription authority with RevenueCat webhooks, Supabase RLS enforcement, Edge Function entitlement verification
**Confidence:** HIGH

## Summary

Phase 51 establishes the server-side subscription authority layer for WoofTalk. RevenueCat webhooks will update a `subscription_status` table in real time, RLS policies will enforce a hard gate of 3 translation INSERTs per calendar day (UTC) for free-tier users, and Edge Functions will verify entitlement before processing premium requests. The phase introduces two new Edge Functions (`entitlement-webhook` and `entitlement-check`), one new table (`subscription_status`), a new column on `user_profiles` (`revenuecat_id`), and updated RLS policies on the `translations` table.

The critical design decisions are already locked in CONTEXT.md: PostgreSQL ENUM for `subscription_tier`, `event_id` as idempotency key, `updated_at`-based 5-minute TTL for entitlement caching, and pure-SQL RLS enforcement (no Edge Function gate for daily limits -- but the translate Edge Function needs a manual tier check because it uses service role). The webhook handler must authenticate via Authorization header and return 200 OK immediately.

**Primary recommendation:** Build the migration and RLS policy first (they are the hard gate), then the webhook handler (it populates the data), then the entitlement-check Edge Function (it refreshes stale data). The translate Edge Function tier check is a small surgical addition to existing code.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Handle ALL RevenueCat webhook event types, not just the 5 listed in SUB-03. Every event type gets a handler (even if some are no-ops initially).
- **D-02:** Webhook Edge Function authenticates by verifying Authorization header against configured RevenueCat webhook secret. Reject unauthenticated with 401.
- **D-03:** Free-tier translation limit is 3 per calendar day with UTC midnight reset. RLS checks `COUNT(*) WHERE created_at >= CURRENT_DATE AND user_id = auth.uid()` against subscription_status tier.
- **D-04:** Daily limit enforced via RLS-only (pure SQL). No Edge Function enforcement. The translate Edge Function uses service role (bypasses RLS), so it must also do a manual tier check before inserting.
- **D-05:** subscription_tier uses PostgreSQL ENUM type (`'free'`, `'trial'`, `'pro'`). Type-safe, restricted values.
- **D-06:** Track purchase_platform column (values: `ios`, `android`, `web`, `none`).
- **D-07:** Store cancellation_reason column. Populated from RevenueCat webhook cancellation_reason field.
- **D-08:** 5-minute entitlement cache uses subscription_status table's updated_at column as TTL. If `updated_at < now() - interval '5 minutes'`, entitlement-check Edge Function re-fetches from RevenueCat REST API and UPDATEs the row. Survives deploys, shared across all Edge Function instances.
- **D-09:** No explicit cache invalidation needed. Webhooks update subscription_status immediately. The 5-min TTL guards against stale RevenueCat API data only.

### Claude's Discretion
- Exact column names and types beyond the decided ones (user_id, revenuecat_id, entitlements, subscription_tier, trial_ends_at, purchase_platform, cancellation_reason, updated_at)
- Index definitions for fast RLS lookups (likely user_id PK + updated_at index)
- Webhook handler internal structure (switch/map per event type)
- Error handling patterns for RevenueCat API failures in entitlement-check
- Whether translate Edge Function should check subscription_status table or call entitlement-check function
- RLS policy SQL for the 3/day limit (exact WHERE clause)
- Migration file naming and structure

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUB-01 | subscription_status table with user_id, revenuecat_id, entitlements, subscription_tier, trial_ends_at, updated_at | PostgreSQL ENUM type (D-05), JSONB for entitlements, schema design below |
| SUB-02 | revenuecat_id column added to user_profiles table | user_profiles table does NOT exist in migrations yet -- must be created or verified |
| SUB-03 | entitlement-webhook Edge Function handles RevenueCat events (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, TRIAL_STARTED) | RevenueCat webhook v1 API verified, all event types documented, Authorization header auth (D-02) |
| SUB-04 | Webhook handler uses event_id as idempotency key | RevenueCat event.id field confirmed in webhook payload [VERIFIED: Context7] |
| SUB-05 | Webhook handler returns 200 OK quickly, processes updates via idempotent UPDATE | Express/Deno pattern: respond first, process async; idempotent UPSERT pattern documented |
| SUB-06 | entitlement-check Edge Function verifies subscription via RevenueCat REST API | GET /v1/subscribers/{app_user_id} endpoint verified [VERIFIED: Context7] |
| SUB-07 | Server-side entitlement result cached for 5 minutes | updated_at TTL strategy (D-08) -- database-backed, survives deploys |
| SUB-08 | RLS policy on translations limits free users to 3 INSERTs per day | CURRENT_DATE UTC midnight reset, pure SQL (D-03/D-04) |
| SUB-09 | RLS policy checks subscription_tier from subscription_status table | Subquery in WITH CHECK clause against subscription_status |
| SUB-10 | Edge Functions check subscription_status before processing premium requests | translate Edge Function service role bypasses RLS -- needs manual check |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook event receipt | API / Backend (Edge Function) | -- | RevenueCat calls the webhook URL; must be server-side |
| Subscription state storage | Database / Storage (PostgreSQL) | -- | subscription_status is the authority; RLS queries it |
| Entitlement caching | Database / Storage (PostgreSQL) | -- | updated_at TTL in subscription_status; shared across instances |
| Daily limit enforcement | Database / Storage (RLS policy) | API / Backend (service role check) | RLS is hard gate; service role Edge Functions need manual check |
| Premium request gating | API / Backend (Edge Function) | -- | Edge Functions check subscription_status before processing |
| RevenueCat REST API calls | API / Backend (Edge Function) | -- | Server-side only; uses REVENUECAT_API_KEY secret |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Supabase Edge Functions (Deno) | std@0.168.0 | Webhook handler + entitlement check | Already used by 6 existing Edge Functions in project [VERIFIED: codebase] |
| @supabase/supabase-js | v2 (via esm.sh) | Supabase client in Edge Functions | Existing import pattern `https://esm.sh/@supabase/supabase-js@2` [VERIFIED: codebase] |
| PostgreSQL ENUM | 15+ | subscription_tier type safety | D-05 locked decision; native PG feature |
| RevenueCat REST API v1 | v1 | Server-side entitlement verification | GET /v1/subscribers/{app_user_id} [VERIFIED: Context7 RevenueCat docs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Deno std/http | 0.168.0 | `serve()` for Edge Function entry point | All Edge Functions |
| _shared/middleware.ts | existing | validateAuth, corsHeaders | Reuse for entitlement-check auth |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PostgreSQL ENUM for subscription_tier | TEXT with CHECK constraint | ENUM is more restrictive and type-safe per D-05; CHECK is more flexible for future tiers but loses type safety |
| updated_at TTL caching | Redis/Upstash caching | updated_at is simpler (no new infra), survives deploys, shared across instances per D-08. Redis would be faster but adds complexity for marginal gain at this scale |
| event_id idempotency check in DB | In-memory Set | DB check survives Edge Function cold starts and deploys. In-memory is lost on every deploy per D-04 |

**Installation:**
No new npm packages needed. All dependencies are Deno imports or existing Supabase infrastructure.

## Architecture Patterns

### System Architecture Diagram

```
RevenueCat
  │
  ├── Webhook POST ──▶ entitlement-webhook Edge Function
  │                       │
  │                       ├─ Verify Authorization header (D-02)
  │                       ├─ Return 200 OK immediately (SUB-05)
  │                       ├─ Extract event.id as idempotency key (SUB-04)
  │                       └─ Idempotent UPSERT to subscription_status
  │                           (handles ALL event types per D-01)
  │
  └── REST API ◀──── entitlement-check Edge Function
                        │
                        ├─ validateAuth (Bearer token)
                        ├─ Read subscription_status row
                        ├─ If updated_at stale (>5 min): GET /v1/subscribers/{uid}
                        │   └─ UPDATE subscription_status with fresh data
                        └─ Return entitlement result

Client App (any platform)
  │
  ├─ POST /translate ──▶ translate Edge Function
  │                       │
  │                       ├─ validateAuth (existing)
  │                       ├─ Check subscription_status.tier (NEW)
  │                       ├─ If free: check daily count < 3
  │                       └─ Insert to translations table
  │                           └─ RLS ALSO enforces 3/day (dual gate)
  │
  └─ Direct DB insert (from client)
       └─ RLS policy is hard gate (3/day for free tier)
```

### Recommended Project Structure
```
supabase/
├── functions/
│   ├── _shared/
│   │   ├── middleware.ts        # Existing: validateAuth, corsHeaders (REUSE)
│   │   └── subscription.ts     # NEW: shared tier-check helper, type definitions
│   ├── entitlement-webhook/     # NEW: RevenueCat webhook handler
│   │   └── index.ts
│   ├── entitlement-check/       # NEW: Server-side entitlement verification
│   │   └── index.ts
│   └── translate/
│       └── index.ts             # MODIFY: add subscription tier check
├── migrations/
│   └── 0013_subscription_status.sql  # NEW: table + ENUM + RLS + revenuecat_id
```

### Pattern 1: Idempotent Webhook Handler
**What:** Process RevenueCat webhook events with duplicate detection using event.id
**When to use:** Every incoming webhook from RevenueCat
**Example:**
```typescript
// Source: RevenueCat official docs (Context7) + project patterns
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  // D-02: Verify Authorization header
  const authHeader = req.headers.get('Authorization');
  if (authHeader !== `Bearer ${Deno.env.get('REVENUECAT_WEBHOOK_AUTH')}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const body = await req.json();
  const event = body.event;

  // SUB-05: Return 200 OK immediately
  // (In Deno Edge Functions, we process synchronously since
  //  we can't truly async-respond, but the logic is fast --
  //  a single UPSERT takes <50ms)

  // SUB-04: Use event.id as idempotency key
  const { data: existing } = await supabase
    .from('webhook_events')
    .select('event_id')
    .eq('event_id', event.id)
    .single();

  if (existing) {
    // Duplicate event -- already processed
    return new Response(JSON.stringify({ status: 'duplicate' }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Record the event and process it
  const eventType = event.type; // e.g., 'INITIAL_PURCHASE', 'RENEWAL', etc.
  // ... handle based on event type (D-01: handle ALL types)
});
```

### Pattern 2: updated_at-Based TTL Caching
**What:** Use subscription_status.updated_at as a TTL indicator for entitlement freshness
**When to use:** Every entitlement-check call
**Example:**
```typescript
// D-08: 5-minute TTL based on updated_at column
const { data: status } = await supabase
  .from('subscription_status')
  .select('*')
  .eq('user_id', userId)
  .single();

const isStale = !status ||
  new Date(status.updated_at) < new Date(Date.now() - 5 * 60 * 1000);

if (isStale) {
  // Re-fetch from RevenueCat REST API
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${userId}`,
    { headers: { 'Authorization': `Bearer ${Deno.env.get('REVENUECAT_API_KEY')}` } }
  );
  const data = await response.json();
  // UPDATE subscription_status with fresh data
  // ... (see Code Examples section for full pattern)
}
```

### Pattern 3: RLS Policy with Subquery for Tier Check
**What:** RLS WITH CHECK clause that queries subscription_status for the user's tier
**When to use:** translations table INSERT policy
**Example:**
```sql
-- D-03/D-04: Free-tier 3/day limit via pure SQL RLS
-- Replaces the existing "Users can insert own translations" policy
CREATE POLICY "Users can insert own translations with tier limit"
  ON public.translations FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      -- Premium/trial users: unlimited
      (SELECT subscription_tier FROM public.subscription_status
       WHERE user_id = auth.uid()) IN ('pro', 'trial')
      OR
      -- Free users: max 3 per calendar day (UTC)
      (
        COALESCE(
          (SELECT subscription_tier FROM public.subscription_status
           WHERE user_id = auth.uid()), 'free'
        ) = 'free'
        AND (
          SELECT COUNT(*) FROM public.translations
          WHERE user_id = auth.uid()
          AND created_at >= CURRENT_DATE
        ) < 3
      )
    )
  );
```

### Anti-Patterns to Avoid
- **INSERT instead of UPSERT for webhooks:** Using INSERT for subscription_status updates will cause duplicate key errors on retry. Always use `INSERT ... ON CONFLICT (user_id) DO UPDATE` (idempotent per SUB-05/D-04).
- **Edge Function as the daily limit gate:** D-04 explicitly says RLS is the hard gate. Do not add daily limit counting logic in Edge Functions for user-facing inserts (the translate Edge Function only needs a tier check because it uses service role).
- **In-memory caching for entitlements:** Edge Functions are stateless and cold-start. In-memory Maps reset on every deploy. Use database TTL (D-08) instead.
- **Returning non-200 from webhook handler:** RevenueCat retries non-200 responses for 72 hours. Always return 200 OK even if processing fails internally -- log the error and move on.
- **Checking subscription_status without COALESCE for missing rows:** New users may not have a subscription_status row yet. RLS policy must default to 'free' tier when the row is missing.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Webhook authentication | Custom HMAC/hash verification | Simple Bearer token comparison against REVENUECAT_WEBHOOK_AUTH | RevenueCat official docs use this pattern [VERIFIED: Context7] |
| Entitlement source of truth | Custom subscription tracking DB | RevenueCat REST API + local cache | RevenueCat validates all receipts; local cache reduces latency |
| Daily limit counting | Edge Function counter | PostgreSQL RLS with COUNT(*) subquery | RLS is the hard gate (D-04); can't be bypassed by client |
| Idempotency tracking | In-memory dedup Set | PostgreSQL table (webhook_events or INSERT ON CONFLICT) | Survives cold starts and deploys |
| Subscription tier validation | Application-level enum check | PostgreSQL ENUM type | D-05; type-safe at DB level, can't store invalid values |

**Key insight:** RevenueCat IS the subscription source of truth. The subscription_status table is a cache that the webhook updates and the entitlement-check refreshes. Never treat subscription_status as the authority -- RevenueCat is.

## Common Pitfalls

### Pitfall 1: Service Role Bypasses RLS
**What goes wrong:** The translate Edge Function uses SUPABASE_SERVICE_ROLE_KEY which bypasses all RLS policies. Free-tier users could get unlimited translations if only RLS is the enforcement mechanism.
**Why it happens:** Service role is used for operational convenience (insert without RLS friction). The planner forgot that service role = no RLS.
**How to avoid:** The translate Edge Function must explicitly query subscription_status and check tier + daily count before inserting. RLS protects direct client inserts; the Edge Function's manual check protects service role inserts. Dual enforcement (D-04).
**Warning signs:** Translations table growing with free users exceeding 3/day.

### Pitfall 2: Webhook Timeout on RevenueCat Retry
**What goes wrong:** Edge Function takes too long to process a webhook (complex DB queries, slow RevenueCat API calls). RevenueCat sees a timeout, retries the event, creating duplicate processing.
**Why it happens:** Deno Edge Functions have a ~400s timeout. If processing involves external API calls, it can exceed reasonable response times.
**How to avoid:** Return 200 OK as fast as possible. Do the minimum work: verify auth, check idempotency, UPSERT subscription_status. No external API calls in the webhook handler.
**Warning signs:** RevenueCat dashboard shows high webhook retry rates.

### Pitfall 3: Missing subscription_status Row for New Users
**What goes wrong:** New users have no row in subscription_status. RLS subquery returns NULL. If the policy checks `subscription_tier = 'free'` without handling NULL, the INSERT fails because NULL != 'free'.
**Why it happens:** subscription_status row is only created on first webhook event (INITIAL_PURCHASE or TRIAL_STARTED). Users who sign up but never start a trial have no row.
**How to avoid:** Use COALESCE in RLS policy: `COALESCE((SELECT subscription_tier ...), 'free') = 'free'`. Also consider creating a subscription_status row on user signup (via trigger on auth.users).
**Warning signs:** New users cannot insert translations at all; 500 errors on first translation attempt.

### Pitfall 4: CURRENT_DATE Timezone Mismatch
**What goes wrong:** RLS uses CURRENT_DATE which follows the PostgreSQL server timezone. If the server is not set to UTC, the daily limit resets at local midnight, not UTC midnight as specified (D-03).
**Why it happens:** Supabase PostgreSQL defaults to UTC, but this is a configuration-dependent assumption.
**How to avoid:** Verify Supabase PostgreSQL timezone is UTC. Use `CURRENT_DATE` (which is session-local) or be explicit with `(now() AT TIME ZONE 'utc')::date`. Supabase instances default to UTC [ASSUMED -- verify with `SHOW timezone`].
**Warning signs:** Users report daily limit resetting at unexpected times.

### Pitfall 5: Webhook Event Type Not Handled
**What goes wrong:** RevenueCat sends an event type not in the initial 5 (e.g., BILLING_ISSUE, PRODUCT_CHANGE, UNCANCELATION, SUBSCRIPTION_PAUSED). The webhook handler crashes or silently drops the event.
**Why it happens:** D-01 says handle ALL event types. RevenueCat has 15+ event types. If the handler uses a strict switch/case without a default, new event types cause errors.
**How to avoid:** Use a map/object for event handlers with a default "no-op" handler. Log unhandled event types for monitoring. The full known event types: TEST, INITIAL_PURCHASE, RENEWAL, CANCELLATION, UNCANCELATION, EXPIRATION, BILLING_ISSUE, PRODUCT_CHANGE, NON_RENEWING_PURCHASE, SUBSCRIPTION_PAUSED, SUBSCRIPTION_RESUMED, TRANSFER, TRIAL_STARTED, TRIAL_CONVERTED [VERIFIED: Context7 RevenueCat docs].
**Warning signs:** Missing subscription status updates for edge-case events.

### Pitfall 6: user_profiles Table Does Not Exist
**What goes wrong:** SUB-02 says "add revenuecat_id column to user_profiles table." But no migration in the codebase creates this table. The column addition ALTER TABLE will fail.
**Why it happens:** The planning docs reference user_profiles but it was never created in a migration. The project has user_settings and other user-related tables but not user_profiles.
**How to avoid:** The migration must CREATE TABLE user_profiles IF NOT EXISTS before adding the revenuecat_id column. Or create the entire user_profiles table in this phase. At minimum: user_id PK, revenuecat_id column.
**Warning signs:** Migration fails with "relation 'user_profiles' does not exist."

## Code Examples

### Webhook Event Payload Structure (v1 API)
Verified from RevenueCat official docs via Context7:
```typescript
// Source: https://github.com/revenuecat/docs/blob/main/docs/integrations/webhooks/event-types-and-fields.mdx
interface RevenueCatWebhookEvent {
  type: string;                    // Event type: INITIAL_PURCHASE, RENEWAL, etc.
  id: string;                      // Unique event ID -- idempotency key (SUB-04)
  app_user_id: string;             // RevenueCat customer ID (= Supabase auth.uid)
  original_app_user_id: string;    // Original user ID
  product_id: string;              // e.g., 'wooftalk_monthly', 'wooftalk_annual'
  entitlement_ids: string[];       // e.g., ['pro']
  period_type: string;             // 'NORMAL', 'TRIAL', 'INTRO'
  purchased_at_ms: number;         // Purchase timestamp
  expiration_at_ms: number;        // Expiration timestamp
  store: string;                   // 'APP_STORE', 'PLAY_STORE', 'STRIPE'
  environment: string;             // 'PRODUCTION', 'SANDBOX'
  price: number;                   // Price paid
  currency: string;                // Currency code
  cancel_reason?: string;          // For CANCELLATION: 'UNSUBSCRIBE', 'BILLING_ERROR', etc.
  expiration_reason?: string;      // For EXPIRATION
  is_trial_conversion?: boolean;   // For RENEWAL only
}

interface RevenueCatWebhookPayload {
  api_version: string;
  event: RevenueCatWebhookEvent;
}
```

### RevenueCat REST API: Get Subscriber
Verified from RevenueCat official docs via Context7:
```typescript
// Source: https://github.com/revenuecat/docs/blob/main/docs/customers/customer-info.mdx
// GET https://api.revenuecat.com/v1/subscribers/{app_user_id}
// Header: Authorization: Bearer YOUR_API_KEY

interface RevenueCatSubscriber {
  subscriber: {
    first_seen: string;
    original_app_user_id: string;
    subscriptions: Record<string, {
      purchase_date: string;
      expires_date: string;
      is_sandbox: boolean;
      unsubscribe_detected_at: string | null;
      billing_issue_detected_at: string | null;
      ownership_type: string;    // 'Purchase' | 'FamilySharing'
      period_type: string;       // 'normal' | 'trial' | 'intro'
    }>;
    entitlements: Record<string, {
      grant_date: string;
      expires_date: string;
      product_identifier: string;
      is_active: boolean;
      will_renew: boolean;
    }>;
  };
}
```

### subscription_status Migration SQL
```sql
-- Migration 0013: Subscription Backend (Phase 51)

-- D-05: PostgreSQL ENUM for subscription_tier
CREATE TYPE public.subscription_tier AS ENUM ('free', 'trial', 'pro');

-- purchase_platform ENUM (D-06)
CREATE TYPE public.purchase_platform AS ENUM ('ios', 'android', 'web', 'none');

-- SUB-01: subscription_status table
CREATE TABLE public.subscription_status (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  revenuecat_id TEXT NOT NULL UNIQUE,
  entitlements JSONB DEFAULT '{}'::jsonb,
  subscription_tier public.subscription_tier DEFAULT 'free',
  trial_ends_at TIMESTAMPTZ,
  purchase_platform public.purchase_platform DEFAULT 'none',
  cancellation_reason TEXT,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for RLS lookups (already PK on user_id, add updated_at for TTL checks)
CREATE INDEX idx_subscription_status_updated_at ON public.subscription_status(updated_at);

-- Auto-update updated_at trigger (reuse existing function)
CREATE TRIGGER update_subscription_status_updated_at
  BEFORE UPDATE ON public.subscription_status
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- SUB-02: Add revenuecat_id to user_profiles (or create table if missing)
-- NOTE: user_profiles table does not exist in current migrations.
-- Create it with minimal schema needed for Phase 51.
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  revenuecat_id TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS on subscription_status
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription status"
  ON public.subscription_status FOR SELECT
  USING (auth.uid() = user_id);

-- RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- SUB-08/SUB-09: Replace existing translations INSERT policy with tier-aware version
DROP POLICY IF EXISTS "Users can insert own translations" ON public.translations;

CREATE POLICY "Users can insert own translations with tier limit"
  ON public.translations FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      -- Premium or trial users: unlimited translations
      (SELECT subscription_tier FROM public.subscription_status
       WHERE user_id = auth.uid()) IN ('pro', 'trial')
      OR
      -- Free users (or users with no subscription_status row): max 3 per calendar day UTC
      (
        COALESCE(
          (SELECT subscription_tier FROM public.subscription_status
           WHERE user_id = auth.uid()), 'free'::public.subscription_tier
        ) = 'free'::public.subscription_tier
        AND (
          SELECT COUNT(*) FROM public.translations
          WHERE user_id = auth.uid()
          AND created_at >= CURRENT_DATE
        ) < 3
      )
    )
  );

-- Webhook events table for idempotency tracking (SUB-04)
CREATE TABLE public.webhook_events (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  app_user_id TEXT NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX idx_webhook_events_app_user_id ON public.webhook_events(app_user_id);
```

### entitlement-webhook Edge Function Pattern
```typescript
// Source: RevenueCat official docs pattern (Context7) + existing project middleware
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

// All known RevenueCat event types (D-01: handle ALL)
type WebhookEventType =
  | 'TEST'
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'CANCELLATION'
  | 'UNCANCELATION'
  | 'EXPIRATION'
  | 'BILLING_ISSUE'
  | 'PRODUCT_CHANGE'
  | 'NON_RENEWING_PURCHASE'
  | 'SUBSCRIPTION_PAUSED'
  | 'SUBSCRIPTION_RESUMED'
  | 'TRANSFER'
  | 'TRIAL_STARTED'
  | 'TRIAL_CONVERTED';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // D-02: Verify Authorization header
  const authHeader = req.headers.get('Authorization');
  const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_AUTH');
  if (!authHeader || authHeader !== `Bearer ${webhookSecret}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    const body = await req.json();
    const event = body.event;
    const eventType = event?.type as string;
    const eventId = event?.id as string;
    const appUserId = event?.app_user_id as string;

    // SUB-04: Idempotency check
    const { data: existing } = await supabase
      .from('webhook_events')
      .select('event_id')
      .eq('event_id', eventId)
      .single();

    if (existing) {
      return new Response(JSON.stringify({ status: 'duplicate' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Determine tier based on event type
    let tier: 'free' | 'trial' | 'pro' = 'free';
    let trialEndsAt: string | null = null;
    let platform: 'ios' | 'android' | 'web' | 'none' = 'none';
    let cancellationReason: string | null = null;

    switch (eventType) {
      case 'INITIAL_PURCHASE':
        tier = event.period_type === 'TRIAL' ? 'trial' : 'pro';
        trialEndsAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;
        platform = mapStore(event.store);
        break;
      case 'RENEWAL':
        tier = 'pro';
        platform = mapStore(event.store);
        break;
      case 'TRIAL_STARTED':
        tier = 'trial';
        trialEndsAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;
        platform = mapStore(event.store);
        break;
      case 'TRIAL_CONVERTED':
        tier = 'pro';
        platform = mapStore(event.store);
        break;
      case 'CANCELLATION':
        // Cancellation: subscription still active until expiration
        cancellationReason = event.cancel_reason || null;
        // Don't downgrade yet -- EXPIRATION event handles that
        tier = 'pro'; // Still active until period ends
        platform = mapStore(event.store);
        break;
      case 'EXPIRATION':
        tier = 'free';
        cancellationReason = event.expiration_reason || null;
        trialEndsAt = null;
        break;
      case 'UNCANCELATION':
        // User re-enabled auto-renew
        tier = 'pro';
        cancellationReason = null;
        break;
      // D-01: Handle remaining types as no-ops (just record)
      case 'BILLING_ISSUE':
      case 'PRODUCT_CHANGE':
      case 'NON_RENEWING_PURCHASE':
      case 'SUBSCRIPTION_PAUSED':
      case 'SUBSCRIPTION_RESUMED':
      case 'TRANSFER':
      case 'TEST':
        // Record but don't change tier
        break;
      default:
        // Unknown event type -- log but don't crash
        console.log(`Unknown webhook event type: ${eventType}`);
        break;
    }

    // Upsert subscription_status (idempotent per SUB-05)
    if (tier !== 'free' || eventType === 'EXPIRATION') {
      const { error: upsertError } = await supabase
        .from('subscription_status')
        .upsert({
          user_id: appUserId,
          revenuecat_id: appUserId, // auth.uid is the RevenueCat appUserID
          entitlements: event.entitlement_ids || [],
          subscription_tier: tier,
          trial_ends_at: trialEndsAt,
          purchase_platform: platform,
          cancellation_reason: cancellationReason,
        }, { onConflict: 'user_id' });

      if (upsertError) console.error('Failed to upsert subscription_status:', upsertError);
    }

    // Record the event for idempotency
    await supabase.from('webhook_events').insert({
      event_id: eventId,
      event_type: eventType,
      app_user_id: appUserId,
    });

  } catch (err) {
    console.error('Webhook processing error:', err);
    // Still return 200 to prevent RevenueCat retry
  }

  // SUB-05: Always return 200 OK
  return new Response(JSON.stringify({ status: 'ok' }), {
    status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});

function mapStore(store: string): 'ios' | 'android' | 'web' | 'none' {
  switch (store) {
    case 'APP_STORE': return 'ios';
    case 'PLAY_STORE': return 'android';
    case 'STRIPE': return 'web';
    default: return 'none';
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| RevenueCat API v1 webhooks | RevenueCat API v2 webhooks (new format) | 2024-2025 | v2 uses nested `event.app` and `event.subscriber` structure. v1 still supported. Project should use v1 format (simpler, well-documented). |
| In-memory Edge Function state | Database-backed caching via updated_at TTL | Standard pattern | Survives Deno cold starts and deploys |
| Separate webhook_events + subscription_status tables | Single subscription_status with event_id dedup | Depends on scale | webhook_events table recommended for audit trail and idempotency tracking |

**Deprecated/outdated:**
- RevenueCat legacy webhooks (pre-v1 format): No longer sent, but v1 format is current and stable [VERIFIED: Context7]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Supabase PostgreSQL timezone defaults to UTC | Pitfall 4 | Daily limit resets at wrong time for some users |
| A2 | user_profiles table needs to be created in this phase (not found in existing migrations) | Pitfall 6 | Migration fails if table already exists under different name |
| A3 | RevenueCat uses auth.uid as appUserID directly (no prefix/suffix) | Webhook handler | Webhook app_user_id won't match user_id in DB |
| A4 | Deno Edge Functions can process webhook + DB write within reasonable time (<5s) | Webhook handler | RevenueCat times out and retries, causing duplicate processing |
| A5 | The v1 webhook format is used (not v2 with nested app/subscriber structure) | Code Examples | Field access paths would be wrong |

## Open Questions

1. **Does a user_profiles table already exist outside of migrations?**
   - What we know: No migration creates it. Grep found no CREATE TABLE for it.
   - What's unclear: It might exist from an earlier phase not yet committed, or it might be created by Supabase Auth triggers.
   - Recommendation: Migration should use CREATE TABLE IF NOT EXISTS to handle both cases.

2. **Should webhook_events have a TTL/cleanup?**
   - What we know: event_id dedup requires storing processed events. Over time this table grows.
   - What's unclear: RevenueCat docs don't specify retention requirements for idempotency keys.
   - Recommendation: Add a pg_cron job or manual cleanup to purge webhook_events older than 72 hours (matching RevenueCat's max retry window).

3. **Should subscription_status row be created on user signup?**
   - What we know: Without a row, COALESCE defaults to 'free'. New users can insert translations.
   - What's unclear: Whether to proactively create the row via auth.users trigger or lazily on first webhook.
   - Recommendation: Use COALESCE in RLS (handles missing rows) and create rows lazily on first webhook event. Simpler and no trigger needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Deno CLI | Local Edge Function testing | N/A (not installed locally) | -- | Use `supabase functions deploy` + remote testing |
| Supabase CLI | Migration deployment | -- | -- | Apply migrations via Supabase dashboard |
| REVENUECAT_WEBHOOK_AUTH secret | Webhook auth (D-02) | Needs creation | -- | Must set in Supabase Edge Function secrets |
| REVENUECAT_API_KEY secret | Entitlement check REST API | Needs creation | -- | Must set in Supabase Edge Function secrets |

**Missing dependencies with no fallback:**
- REVENUECAT_WEBHOOK_AUTH: Must be configured as Supabase Edge Function secret before deploying entitlement-webhook
- REVENUECAT_API_KEY: Must be configured as Supabase Edge Function secret before deploying entitlement-check

**Missing dependencies with fallback:**
- Deno CLI: Not installed locally; Edge Functions can be tested via `supabase functions serve` (uses Deno in Docker) or deployed and tested remotely

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | No test framework detected in project |
| Config file | None |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUB-01 | subscription_status table created with correct schema | migration | Apply migration, verify table columns | Needs Wave 0 |
| SUB-02 | revenuecat_id column on user_profiles | migration | Apply migration, verify column exists | Needs Wave 0 |
| SUB-03 | Webhook handler processes RevenueCat events | integration | POST to Edge Function with mock event | Needs Wave 0 |
| SUB-04 | Idempotency: duplicate event_id ignored | integration | POST same event twice, verify one row | Needs Wave 0 |
| SUB-05 | Webhook returns 200 quickly | unit | Measure response time < 1s | Needs Wave 0 |
| SUB-06 | entitlement-check verifies via REST API | integration | Call with stale user, verify API call | Needs Wave 0 |
| SUB-07 | 5-minute TTL on entitlement cache | integration | Call within 5 min (no API), after 5 min (API) | Needs Wave 0 |
| SUB-08 | RLS limits free users to 3 INSERTs/day | integration | Insert 4 as free user, verify 4th rejected | Needs Wave 0 |
| SUB-09 | RLS checks subscription_tier | integration | Upgrade user, verify unlimited inserts | Needs Wave 0 |
| SUB-10 | Edge Function rejects premium requests from free users | integration | Call translate as free user 4x, verify 4th rejected | Needs Wave 0 |

### Sampling Rate
- **Per task commit:** Verify migration applies cleanly
- **Per wave merge:** Test webhook + RLS end-to-end with RevenueCat sandbox
- **Phase gate:** All 10 SUB requirements verified

### Wave 0 Gaps
- [ ] No test framework installed -- consider manual testing via Supabase SQL editor + Edge Function invocations
- [ ] RevenueCat sandbox environment needed for webhook testing
- [ ] Test data: need test users with different subscription tiers

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Bearer token auth via validateAuth (existing middleware) for entitlement-check; webhook auth via REVENUECAT_WEBHOOK_AUTH (D-02) |
| V3 Session Management | no | No session management in this phase |
| V4 Access Control | yes | RLS policies enforce free-tier limits; service role check in translate Edge Function |
| V5 Input Validation | yes | Webhook payload validation (event type, event_id); JSON schema for incoming events |
| V6 Cryptography | no | No custom cryptography; uses HTTPS for all API calls |

### Known Threat Patterns for Supabase Edge Functions + RevenueCat Webhooks

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook spoofing | Spoofing | Authorization header verification (D-02) |
| Webhook replay | Tampering | event_id idempotency key (SUB-04) |
| Free tier bypass via API | Elevation of Privilege | RLS hard gate + service role tier check (D-04) |
| Entitlement cache poisoning | Tampering | Webhook is write-source; entitlement-check refreshes from RevenueCat API |
| Excessive webhook calls (DoS) | Denial of Service | RevenueCat handles rate limiting on their side; Edge Function processes quickly |

## Sources

### Primary (HIGH confidence)
- Context7 /revenuecat/docs - Webhook event types, payload schema, REST API v1 subscribers endpoint
- Context7 /websites/revenuecat_api-v2 - API v2 customer active entitlements endpoint
- Codebase: supabase/migrations/ - 12 existing migrations showing table/RLS patterns
- Codebase: supabase/functions/ - 6 existing Edge Functions showing Deno import patterns
- Codebase: supabase/functions/_shared/middleware.ts - validateAuth, corsHeaders patterns

### Secondary (MEDIUM confidence)
- Context7 /revenuecat/docs - Webhook handler Express.js/Python examples (adapted to Deno)
- .planning/research/ARCHITECTURE.md - Data flow diagrams, subscription lifecycle
- .planning/research/STACK.md - RevenueCat REST API details, environment variables
- .planning/research/PITFALLS.md - Pitfall 3 (free tier bypass), Pitfall 6 (webhook idempotency)

### Tertiary (LOW confidence)
- A1: Supabase PostgreSQL timezone defaults to UTC (assumed, needs verification)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all libraries verified in codebase or Context7
- Architecture: HIGH - patterns match existing codebase; RevenueCat webhook/REST API confirmed
- Pitfalls: HIGH - 3 of 6 pitfalls from existing PITFALLS.md directly relevant; 3 new pitfalls from codebase analysis
- RLS policy: MEDIUM - SQL pattern is standard PostgreSQL but needs testing against actual data

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (30 days -- RevenueCat webhook API is stable)
