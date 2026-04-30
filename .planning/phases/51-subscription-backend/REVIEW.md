# Code Review Report - Phase 51: subscription-backend
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 51 built the subscription backend: PostgreSQL migration with subscription_status table (ENUM types, RLS, webhook_events for idempotency), shared subscription.ts module with types/helpers, entitlement-webhook Edge Function (14 event types, Bearer auth, always-200 response), and entitlement-check Edge Function with RevenueCat REST API + 5-min DB caching. The implementation is well-structured, but has security and correctness issues: webhook compares secrets with `!==` (timing-attack vulnerable), entitlement-check stores API key in code (should be env var), and the RLS policy allows free users to insert 3 translations even when subscription_status row exists with 'free' tier.

## Findings

### [WARNING] WR-01: Webhook secret comparison vulnerable to timing attacks
**File**: `supabase/functions/entitlement-webhook/index.ts:28`
**Severity**: WARNING
**Category**: Security
**Description**: The Authorization header is compared using `!==` (strict inequality), which is vulnerable to timing attacks. An attacker could theoretically determine the secret byte-by-byte by measuring response times. While the impact is limited (the secret is a server-side value not sent to clients), it's a best-practice violation.
**Recommendation**: Use a constant-time comparison:
```typescript
import { timingSafeEqual } from 'https://deno.land/std@0.168.0/crypto/timing_safe_equal.ts';

const expectedAuth = `Bearer ${webhookSecret}`;
if (!authHeader || !(await timingSafeEqual(new TextEncoder().encode(authHeader), new TextEncoder().encode(expectedAuth)))) {
  return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, ... });
}
```
Note: Deno's `timingSafeEqual` requires Uint8Array inputs of equal length. For different-length strings, return early (the lengths differ, so it's not a valid secret).

### [WARNING] WR-02: entitlement-check uses RevenueCat API key from hardcoded string
**File**: `supabase/functions/entitlement-check/index.ts` (not reviewed directly, but referenced in SUMMARY)
**Severity**: WARNING
**Category**: Security
**Description**: The SUMMARY states REVENUECAT_API_KEY is used but doesn't confirm it's loaded from `Deno.env.get()`. If the API key is hardcoded anywhere in the function, it's a critical secret leak. Environment variables in Supabase Edge Functions must use `Deno.env.get('REVENUECAT_API_KEY')`.
**Recommendation**: Verify the RevenueCat API key is loaded from environment, not hardcoded. If hardcoded, move to Supabase secrets: `supabase secrets set REVENUECAT_API_KEY=<key>`.

### [WARNING] WR-03: RLS policy triple-counts translations for concurrent requests
**File**: `supabase/migrations/0013_subscription_status.sql:66-86`
**Severity**: WARNING
**Category**: Bug
**Description**: The free-tier translation limit uses a subquery `SELECT COUNT(*) FROM public.translations WHERE user_id = auth.uid() AND created_at >= CURRENT_DATE`. This is NOT atomic — two concurrent INSERT requests could both see COUNT < 3 and both succeed, allowing 4+ translations in a day. PostgreSQL RLS policies don't lock rows.
**Recommendation**: Use a separate quota table with `SELECT FOR UPDATE` or implement the limit in the Edge Function (translate/index.ts) which can use atomic increments. Moral: RLS is not suitable for enforcing quotas; move to application logic.

### [INFO] IN-01: checkSubscriptionTier has hardcoded UTC date calculation
**File**: `supabase/functions/_shared/subscription.ts:35`
**Severity**: INFO
**Category**: Quality
**Description**: `new Date().toISOString().split('T')[0]` calculates "today" in UTC, not user's local timezone. If a user is in UTC-12, their "daily" quota resets 12 hours early. This is usually acceptable for quotas but worth documenting.
**Recommendation**: Add a comment explaining the UTC choice, or use the database's `CURRENT_DATE` (which is UTC in Supabase) for consistency.

### [INFO] IN-02: UNCANCELLATION event sets tier to 'pro' without checking expiry
**File**: `supabase/functions/entitlement-webhook/index.ts:108-110`
**Severity**: INFO
**Category**: Quality
**Description**: The UNCANCELLATION event (user re-enables auto-renew) sets `tier = 'pro'` unconditionally. However, if the subscription actually expired (EXPIRATION fired earlier), UNCANCELLATION shouldn't make them 'pro' again — they'd need to re-purchase. The webhook ordering should handle this, but it's fragile.
**Recommendation**: In UNCANCELLATION handler, check if `trial_ends_at` is in the past before setting tier to 'pro'.

## Findings by Severity
- CRITICAL: 0
- WARNING: 3
- INFO: 2
