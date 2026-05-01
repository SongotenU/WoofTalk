# Code Review Report - Supabase & Backend
**Date**: 2026-04-30
**Scope**: Supabase functions and migrations
**Depth**: standard

## Summary
This review covers 7 Supabase Edge Functions and 4 SQL migrations. The codebase contains significant security gaps: multiple edge functions expose sensitive operations (financial data, push campaigns, webhook handling) without authentication or authorization checks. SQL migrations have data integrity risks including a potentially missing CHECK constraint and a table (`ab_experiments`) with no Row Level Security. Several functions contain race conditions, duplicate implementations, and incorrect business logic (churn calculation). Multiple BLOCKER-level issues must be resolved before shipping.

## Findings

### [BLOCKER] Missing Row Level Security on `ab_experiments` table
**File**: `supabase/migrations/0013_admin_analytics_features.sql:60-70`
**Severity**: BLOCKER
**Category**: Security
**Description**: The `ab_experiments` table is created but RLS is never enabled, and no policies are created. Any authenticated user can read/write experiments, including activating/deactivating experiments and modifying variant configurations.
**Evidence**:
```sql
CREATE TABLE IF NOT EXISTS public.ab_experiments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    ...
);
-- No ALTER TABLE ... ENABLE ROW_LEVEL_SECURITY;
-- No CREATE POLICY ...
```
**Recommendation**:
```sql
ALTER TABLE public.ab_experiments ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can manage experiments"
    ON public.ab_experiments FOR ALL
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));
```

### [BLOCKER] CHECK constraint may not be applied in migration 0016
**File**: `supabase/migrations/0016_subscription_snapshots.sql:4-17`
**Severity**: BLOCKER
**Category**: Bug
**Description**: The migration uses `CREATE TABLE IF NOT EXISTS` for `subscription_snapshots`, but migration 0013 already creates this table (without the CHECK constraint on `status`). Since 0013 runs first (lower number), the `CREATE TABLE` in 0016 becomes a no-op, and the CHECK constraint `CHECK (status IN ('trial', 'active', 'cancelled', 'expired', 'past_due'))` is never applied. This means invalid status values can be inserted.
**Evidence**:
```sql
-- 0013 creates table WITHOUT CHECK constraint on status
CREATE TABLE IF NOT EXISTS public.subscription_snapshots (
    ...
    status text NOT NULL,  -- No CHECK constraint
    ...
);

-- 0016 tries to create same table WITH CHECK constraint
CREATE TABLE IF NOT EXISTS public.subscription_snapshots (
    ...
    status text NOT NULL CHECK (status IN ('trial', 'active', 'cancelled', 'expired', 'past_due')),
    ...
);
-- This is a no-op if 0013 already ran!
```
**Recommendation**: Add the CHECK constraint explicitly in migration 0016:
```sql
ALTER TABLE public.subscription_snapshots
  ADD CONSTRAINT check_status_valid
  CHECK (status IN ('trial', 'active', 'cancelled', 'expired', 'past_due'))
  NOT VALID;  -- Use NOT VALID if data exists, then VALIDATE later
```

### [BLOCKER] No webhook signature verification in win-back function
**File**: `supabase/functions/ab-assign/index.ts:14-95`
**Severity**: BLOCKER
**Category**: Security
**Description**: The function handles RevenueCat webhooks (CANCELLATION/EXPIRATION events) but does not verify the webhook signature. Anyone can send a POST request with fake event data and trigger cancellation logic, win-back email generation, and subscription status updates. RevenueCat signs webhooks with a secret; this should be verified.
**Evidence**:
```typescript
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  // No signature verification!
  const { event, data } = await req.json() as Envelope;
```
**Recommendation**: Verify the `RC-Signature` header using the RevenueCat webhook secret stored in environment variables:
```typescript
const signature = req.headers.get('RC-Signature');
const body = await req.text();
// Verify HMAC signature before processing
```

### [BLOCKER] No authentication on MRR calculator endpoint
**File**: `supabase/functions/collect-error/index.ts:5-78`
**Severity**: BLOCKER
**Category**: Security
**Description**: The MRR calculator endpoint (despite the filename `collect-error`) exposes sensitive financial data (MRR, churn rate, active subscriptions) without any authentication or authorization check. Anyone with the function URL can access this data.
**Evidence**:
```typescript
serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    // No auth check - anyone can call this
    const { data: snapshots, error } = await supabase
      .from('subscription_snapshots')
      .select('*')
      ...
```
**Recommendation**: Add authentication check:
```typescript
const authHeader = req.headers.get('Authorization');
if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
// Verify the JWT and check for admin role
```

### [BLOCKER] No authentication on push campaign send endpoint
**File**: `supabase/functions/push-campaign-send/index.ts:7-87`
**Severity**: BLOCKER
**Category**: Security
**Description**: The push campaign send endpoint allows anyone to trigger push campaigns by sending a POST request with a `campaign_id`. There is no authentication or authorization check. An attacker could drain FCM quotas, spam users, or disrupt campaigns.
**Evidence**:
```typescript
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    ...
    const { campaign_id } = await req.json();
    if (!campaign_id) throw new Error('campaign_id is required');
    // No auth check - anyone can trigger campaigns
```
**Recommendation**: Add authentication and verify the caller has permission to send campaigns.

### [BLOCKER] No authentication on error collector endpoints
**File**: `supabase/functions/error-collector/index.ts:16-63` and `supabase/functions/win-back-campaign/index.ts:5-57`
**Severity**: BLOCKER
**Category**: Security
**Description**: Both error collector functions allow unauthenticated clients to insert error logs. While the RLS policy in migration 0015 allows service role to insert (`WITH CHECK (true)`), the edge functions themselves don't verify the caller's identity. Combined with the service role key usage, this is an open write endpoint.
**Evidence**:
```typescript
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    // No auth check
    const payload: ErrorPayload = await req.json();
    // Directly inserts into error_logs
```
**Recommendation**: Either add authentication, or restrict the endpoint to only accept requests from trusted sources (e.g., internal edge functions, with a shared secret).

### [BLOCKER] Race condition in A/B experiment assignment
**File**: `supabase/functions/mrr-calculator/index.ts:64-68`
**Severity**: BLOCKER
**Category**: Bug
**Description**: The A/B assignment function checks for existing assignments (lines 21-32) and then inserts a new assignment. Under concurrent requests for the same user+experiment, both requests could pass the "existing" check and attempt to insert, causing a unique constraint violation error (since `experiment_id, user_id` is UNIQUE). The function does not handle this error gracefully.
**Evidence**:
```typescript
// Check for existing (lines 21-32)
const { data: existing } = await supabase
  .from('experiment_assignments')
  .select('variant')
  ...
  .maybeSingle();

if (existing) { ... }

// Meanwhile, another request could have inserted...

// Store assignment (lines 64-68) - will fail with unique violation if concurrent
await supabase.from('experiment_assignments').insert({
  experiment_id: experiment.id,
  user_id,
  variant: assignedVariant,
});
```
**Recommendation**: Use `upsert` with `onConflict` or wrap in a transaction:
```typescript
const { data, error } = await supabase
  .from('experiment_assignments')
  .upsert({
    experiment_id: experiment.id,
    user_id,
    variant: assignedVariant,
  }, { onConflict: 'experiment_id,user_id' })
  .select('variant')
  .single();
```

### [BLOCKER] Campaign status stuck on error
**File**: `supabase/functions/push-campaign-send/index.ts:82-86`
**Severity**: BLOCKER
**Category**: Bug
**Description**: When an error occurs during push campaign sending, the catch block returns an error response but does not update the campaign status. Since the status was set to 'sending' on line 29, it remains 'sending' permanently, leaving the campaign in a broken state.
**Evidence**:
```typescript
// Line 29: status set to 'sending'
await supabase.from('push_campaigns').update({ status: 'sending' }).eq('id', campaign_id);

// Lines 82-86: on error, status is never updated
} catch (error: any) {
  return new Response(JSON.stringify({ error: error.message }), {
    status: 500, ...
  });
  // campaign status remains 'sending'!
}
```
**Recommendation**: Update campaign status to a failure state in the catch block:
```typescript
} catch (error: any) {
  await supabase.from('push_campaigns').update({ status: 'cancelled' }).eq('id', campaign_id);
  return new Response(JSON.stringify({ error: error.message }), { status: 500, ... });
}
```

### [WARNING] Churn calculation logic is incorrect
**File**: `supabase/functions/collect-error/index.ts:36-56`
**Severity**: WARNING
**Category**: Bug
**Description**: The churn calculation is intended to find users who were active last month but not this month. However, the "last month" snapshots include ALL snapshots with `snapshot_date <= lastMonthStr`, not just snapshots from the previous month. The `lastMonthActive` set includes the latest snapshot per user from ANY date before last month, which is incorrect.
**Evidence**:
```typescript
const lastMonth = new Date();
lastMonth.setMonth(lastMonth.getMonth() - 1);
const lastMonthStr = lastMonth.toISOString().slice(0, 10);

const lastMonthSnapshots = (snapshots || [])
  .filter((s: any) => s.snapshot_date <= lastMonthStr);  // Gets ALL snapshots before last month

// Then gets latest per user from this unfiltered set
const lmSeen = new Set();
const lastMonthActive: Set<string> = new Set();
lastMonthSnapshots.forEach((s: any) => {
  if (!lmSeen.has(s.user_id)) {
    lmSeen.add(s.user_id);
    if (s.status === 'active') lastMonthActive.add(s.user_id);
  }
});
```
**Recommendation**: Filter snapshots to only include those from the specific month being analyzed, or compare the latest snapshot from last month vs. the latest snapshot from this month properly.

### [WARNING] No segment filtering in push campaign send
**File**: `supabase/functions/push-campaign-send/index.ts:32-34`
**Severity**: WARNING
**Category**: Bug
**Description**: The campaign has a `segment_id` field and the code fetches `user_segments(*)`, but it ignores the segment and sends to ALL push tokens. This means targeted campaigns (e.g., "send to iOS users") will go to all users regardless of segment.
**Evidence**:
```typescript
// Gets campaign with segment, but doesn't use it
const { data: campaign, error: campaignError } = await supabase
  .from('push_campaigns')
  .select('*, user_segments(*)')
  .eq('id', campaign_id)
  .single();

// Gets ALL push tokens regardless of segment
let userQuery = supabase.from('push_tokens').select('fcm_token, user_id');
const { data: tokens, error: tokenError } = await userQuery;  // No filtering!
```
**Recommendation**: Implement segment filtering based on `campaign.segment_id` and the segment's `filters` JSONB.

### [WARNING] `parseFloat` can return NaN in MRR calculation
**File**: `supabase/functions/collect-error/index.ts:31-33`
**Severity**: WARNING
**Category**: Bug
**Description**: The MRR calculation uses `parseFloat(s.price_usd || 0)`, but if `price_usd` is a string that cannot be parsed as a number, `parseFloat` returns NaN, which propagates through the reduce and results in `NaN` for the total MRR.
**Evidence**:
```typescript
const mrr = latest
  .filter((s: any) => s.status === 'active')
  .reduce((sum: number, s: any) => sum + parseFloat(s.price_usd || 0), 0);
// If price_usd = "abc", parseFloat("abc") = NaN, sum + NaN = NaN
```
**Recommendation**:
```typescript
const mrr = latest
  .filter((s: any) => s.status === 'active')
  .reduce((sum: number, s: any) => {
    const price = parseFloat(s.price_usd || 0);
    return sum + (isNaN(price) ? 0 : price);
  }, 0);
```

### [WARNING] Race condition in `apply_referral_code` function
**File**: `supabase/migrations/0014_subscription_enhancements.sql:113-140`
**Severity**: WARNING
**Category**: Bug
**Description**: The `apply_referral_code` function checks `uses_remaining > 0` and then decrements it. Under concurrent calls with the same referral code, multiple calls could pass the check before any of them decrements, leading to negative `uses_remaining` or more uses than intended.
**Evidence**:
```sql
-- Check (line 123)
WHERE code = p_code AND is_active = TRUE AND (uses_remaining > 0 OR uses_remaining IS NULL)

-- Then decrement (lines 134-136)
UPDATE public.referral_codes
SET uses_remaining = uses_remaining - 1
WHERE code = p_code AND uses_remaining > 0;
-- Race condition: two concurrent calls both pass the SELECT before either UPDATEs
```
**Recommendation**: Use `SELECT ... FOR UPDATE` or atomic decrement:
```sql
UPDATE public.referral_codes
SET uses_remaining = uses_remaining - 1
WHERE code = p_code AND uses_remaining > 0
RETURNING uses_remaining INTO v_remaining;
-- Check if update actually happened
```

### [WARNING] Duplicate error collector functions
**File**: `supabase/functions/error-collector/index.ts` and `supabase/functions/win-back-campaign/index.ts`
**Severity**: WARNING
**Category**: Quality
**Description**: Two edge functions contain nearly identical error collection logic. `error-collector/index.ts` and `win-back-campaign/index.ts` both accept error payloads and insert into `error_logs`. This is confusing and maintenance burden - fixes must be applied in two places.
**Evidence**: Both files have identical logic for validating `platform`, `error_type`, `message` and inserting into `error_logs`.
**Recommendation**: Consolidate into a single error collector function, or refactor shared logic into a shared module.

### [WARNING] No batching in FCM sends
**File**: `supabase/functions/push-campaign-send/index.ts:48-68`
**Severity**: WARNING
**Category**: Quality
**Description**: The function sends FCM messages one-by-one in a sequential loop. For campaigns with many tokens (thousands), this will be extremely slow and may timeout. FCM supports batch send APIs.
**Evidence**:
```typescript
for (const token of tokens) {
  try {
    const payload = { to: token.fcm_token, ... };
    const response = await fetch(FCM_ENDPOINT, { ... });  // One request per token
    ...
  }
}
```
**Recommendation**: Use FCM batch send API or at minimum parallelize with concurrency limits:
```typescript
const results = await Promise.allSettled(
  tokens.map(token => sendToFCM(token, campaign))
);
```

### [WARNING] Using magiclink for win-back emails
**File**: `supabase/functions/ab-assign/index.ts:64-76`
**Severity**: WARNING
**Category**: Security
**Description**: The win-back email uses `generateLink` with type "magiclink", which creates a login link that automatically logs the user in. The link is sent to the user's email with a promo code in the URL. If the email is intercepted or forwarded, anyone with the link can access the user's account.
**Evidence**:
```typescript
const { error: emailError } = await supabaseClient.auth.admin.generateLink({
  type: "magiclink",
  email,
  options: {
    redirectTo: `${Deno.env.get("SITE_URL")}/subscribe?promo=${offerCode}`,
    ...
  },
});
```
**Recommendation**: Use a regular email (not magiclink) with a non-authenticating promo code, or use a time-limited token that only applies the promo without logging in.

### [WARNING] CORS wildcard on webhook endpoint
**File**: `supabase/functions/ab-assign/index.ts:4-7`
**Severity**: WARNING
**Category**: Security
**Description**: The CORS headers allow `Access-Control-Allow-Origin: "*"`, which allows any website to make requests to this webhook endpoint. While webhooks should only be called from RevenueCat, the CORS policy is irrelevant for server-to-server calls (CORS is a browser security feature). However, the wildcard origin combined with no auth creates a false sense of security.
**Evidence**:
```typescript
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  ...
};
```
**Recommendation**: For webhook endpoints that should only be called by specific services, either remove CORS headers entirely (they're not needed for server-to-server) or restrict to specific origins. More importantly, add webhook signature verification.

### [WARNING] FCM key not set doesn't error
**File**: `supabase/functions/push-campaign-send/index.ts:47-69`
**Severity**: WARNING
**Category**: Quality
**Description**: If `fcmServerKey` is not set in environment variables, the FCM send loop is skipped entirely, but the campaign status is still updated to 'sent' with 0 success and 0 failure. This is misleading - the campaign appears sent but no messages were actually sent.
**Evidence**:
```typescript
if (fcmServerKey) {
  for (const token of tokens) { ... }  // Only sends if key exists
}

await supabase.from('push_campaigns').update({
  status: 'sent',
  ...  // Reports 0 sent, but didn't actually try to send
});
```
**Recommendation**: Check for FCM key earlier and return an error or mark campaign as failed if missing.

### [WARNING] `hashCode` function confusion
**File**: `supabase/functions/feature-flag-evaluate/index.ts:60-68` and `supabase/functions/mrr-calculator/index.ts:80-88`
**Severity**: WARNING
**Category**: Quality
**Description**: The `hashCode` function includes `hash = hash & hash` which is a no-op (any number AND itself equals itself for integers). The likely intent was to convert to 32-bit integer, but `&` in JavaScript already converts to 32-bit signed integer. The line is either redundant or incorrectly implemented.
**Evidence**:
```typescript
function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;  // No-op! Remove or fix intent
  }
  return Math.abs(hash);
}
```
**Recommendation**: Remove the no-op line or clarify intent:
```typescript
hash = hash | 0;  // Explicitly convert to 32-bit signed integer
```

### [INFO] TODO comments in error collector
**File**: `supabase/functions/error-collector/index.ts:50`
**Severity**: INFO
**Category**: Quality
**Description**: A TODO comment indicates planned but unimplemented functionality for configurable alert thresholds.
**Evidence**:
```typescript
// TODO: Configurable alert thresholds (email/Slack webhook) - check thresholds and notify
```
**Recommendation**: Create a ticket for this work or remove the TODO if not planned.

### [INFO] Win-back offer not stored in database
**File**: `supabase/functions/ab-assign/index.ts:59-61`
**Severity**: INFO
**Category**: Quality
**Description**: The win-back offer code is generated and logged to console, but not stored in the database. The comment indicates a `win_back_offers` table was planned but not created.
**Evidence**:
```typescript
// Store offer in database (optional: create win_back_offers table)
// For now, log it
console.log(`Win-back offer for ${email}: ${offerCode}`);
```
**Recommendation**: Create the `win_back_offers` table and store offers, or remove the comment if not planned.

### [INFO] Seed data in migration 0013
**File**: `supabase/migrations/0013_admin_analytics_features.sql:186-193`
**Severity**: INFO
**Category**: Quality
**Description**: The migration inserts seed data for feature flags. While `ON CONFLICT DO NOTHING` makes it idempotent, mixing schema changes and data changes in migrations can be problematic for rollbacks.
**Evidence**:
```sql
INSERT INTO public.feature_flags (key, name, description, is_enabled, rollout_percentage)
VALUES
    ('ios_background_audio', ...),
    ...
ON CONFLICT (key) DO NOTHING;
```
**Recommendation**: Consider separating seed data into a separate seed file or using Supabase's seed functionality.

### [INFO] Redundant migrations 0015 and 0016
**File**: `supabase/migrations/0015_error_logs.sql` and `supabase/migrations/0016_subscription_snapshots.sql`
**Severity**: INFO
**Category**: Quality
**Description**: Both migrations create tables that are already created in migration 0013 (`error_logs` and `subscription_snapshots`). They use `CREATE TABLE IF NOT EXISTS`, so they're no-ops if 0013 has run, but they add policies and indexes. This redundancy is confusing.
**Recommendation**: Consolidate all schema changes into migration 0013, or ensure later migrations only add/modify (not recreate) tables.

## Findings by Severity
- BLOCKER: 8
- WARNING: 12
- INFO: 4

## Findings by Category
- Bug: 6
- Security: 9
- Quality: 9
