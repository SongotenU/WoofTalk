---
phase: 51-subscription-backend
plan: 02
subsystem: api
tags: [revenuecat, webhook, idempotency, edge-function, deno, subscription]

# Dependency graph
requires:
  - phase: 51-01
    provides: subscription_status table, webhook_events table, _shared/subscription.ts
provides:
  - entitlement-webhook Edge Function processing all 14 RevenueCat event types
  - Bearer token webhook authentication via REVENUECAT_WEBHOOK_AUTH
  - event_id idempotency check preventing duplicate processing
  - Always-200 response pattern preventing RevenueCat retry storms
affects: [51-03, 52-paywall-ui, 53-client-gating]

# Tech tracking
tech-stack:
  added: [revenuecat-webhook-handler]
  patterns: [bearer-token-webhook-auth, event-id-idempotency, always-200-response, shouldUpsert-flag-for-noops]

key-files:
  created:
    - supabase/functions/entitlement-webhook/index.ts
  modified: []

key-decisions:
  - "shouldUpsert flag controls which event types trigger subscription_status upsert — no-op events (BILLING_ISSUE, PRODUCT_CHANGE, etc.) are recorded in webhook_events but don't modify subscription state"
  - "REVENUECAT_WEBHOOK_AUTH secret must be configured before deployment — function rejects all requests without valid Bearer token"

patterns-established:
  - "Webhook auth pattern: verify Authorization header against env var, reject with 401, no validateAuth from middleware"
  - "Always-200 response: return 200 outside try/catch so RevenueCat never retries"
  - "shouldUpsert flag: only state-changing events (INITIAL_PURCHASE, RENEWAL, TRIAL_STARTED, TRIAL_CONVERTED, CANCELLATION, EXPIRATION, UNCANCELATION) trigger upsert; no-op events just log and record"

requirements-completed: [SUB-03, SUB-04, SUB-05]

# Metrics
duration: 4min
completed: 2026-04-16
---

# Phase 51 Plan 02: Entitlement Webhook Summary

**RevenueCat webhook Edge Function with Bearer token auth, 14-event-type switch handler, event_id idempotency, and always-200 response pattern**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-16T02:55:41Z
- **Completed:** 2026-04-16T02:59:47Z
- **Tasks:** 1 of 2 (1 requires manual execution)
- **Files modified:** 1

## Accomplishments
- Created entitlement-webhook Edge Function (168 lines) that processes all 14 known RevenueCat webhook event types
- Implemented Bearer token authentication via REVENUECAT_WEBHOOK_AUTH environment variable (D-02)
- Built idempotency check using event_id against webhook_events table (SUB-04)
- Ensured always-200 response pattern to prevent RevenueCat 72-hour retry storms (SUB-05)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create entitlement-webhook Edge Function** - `36829b2` (feat)
2. **Task 2: Deploy webhook function and verify with test event** - NOT EXECUTED (Supabase CLI unavailable in worktree; requires manual `supabase functions deploy entitlement-webhook`)

## Files Created/Modified
- `supabase/functions/entitlement-webhook/index.ts` - RevenueCat webhook handler with auth, idempotency, all-event-type handling, and always-200 response

## Decisions Made
- Used `shouldUpsert` flag pattern to separate state-changing events from no-op events — no-op events (BILLING_ISSUE, PRODUCT_CHANGE, NON_RENEWING_PURCHASE, SUBSCRIPTION_PAUSED, SUBSCRIPTION_RESUMED, TRANSFER, TEST) are logged and recorded in webhook_events but don't trigger subscription_status upsert
- CANCELLATION event sets tier to 'pro' (not 'free') because the subscription remains active until EXPIRATION event fires — the cancel_reason is stored for analytics
- EXPIRATION event clears trialEndsAt to null and sets tier to 'free', matching the end-of-lifecycle semantics

## Deviations from Plan

None - plan executed exactly as specified for Task 1. Task 2 (deployment) could not be executed due to environment limitations and is flagged for manual intervention.

## Issues Encountered

**Deployment requires manual execution:**
- Supabase CLI not installed in worktree environment
- The function code is complete and correct; deployment must be run manually after merge
- Verification command: `supabase functions deploy entitlement-webhook`
- Test command: `curl -X POST <EDGE_FUNCTION_URL>/entitlement-webhook -H "Authorization: Bearer <secret>" -H "Content-Type: application/json" -d '{"event":{"type":"TEST","id":"test-001","app_user_id":"test-user","store":"APP_STORE","entitlement_ids":[]}}'`
- REVENUECAT_WEBHOOK_AUTH secret must be set before deployment: `supabase secrets set REVENUECAT_WEBHOOK_AUTH=<your-secret-value>`

## User Setup Required

**Edge Function deployment and secret configuration require manual execution.** After this branch is merged:
1. Set the webhook auth secret: `supabase secrets set REVENUECAT_WEBHOOK_AUTH=<your-secret-value>`
2. Deploy the function: `supabase functions deploy entitlement-webhook`
3. Verify deployment: `supabase functions list | grep entitlement-webhook`
4. Test with a sample event using curl (see test command in Issues Encountered)
5. Configure RevenueCat dashboard webhook URL to point to the deployed Edge Function

## Next Phase Readiness
- Webhook Edge Function code-complete, ready for deployment and RevenueCat dashboard configuration
- Plan 51-03 (entitlement-check Edge Function) can be built independently — it reads from subscription_status and calls RevenueCat REST API
- The translate Edge Function tier check (Plan 51-03) will query subscription_status rows that this webhook populates

## Self-Check: PASSED

All files verified present, commit hash confirmed, all 14 event types present in code, REVENUECAT_WEBHOOK_AUTH/webhook_events/subscription_status/onConflict/shouldUpsert all verified.

---
*Phase: 51-subscription-backend*
*Completed: 2026-04-16*
