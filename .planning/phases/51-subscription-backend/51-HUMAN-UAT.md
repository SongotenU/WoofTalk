---
status: partial
phase: 51-subscription-backend
source: [51-VERIFICATION.md]
started: 2026-04-16T04:10:00Z
updated: 2026-04-16T04:10:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Deploy migration and Edge Functions to Supabase
expected: subscription_status, user_profiles, webhook_events tables created; entitlement-webhook, entitlement-check, translate functions deployed
result: [pending]

### 2. Send test webhook event via curl to entitlement-webhook
expected: 200 response with {status: 'ok'}, subscription_status row reflects event data
result: [pending]

### 3. Call entitlement-check with authenticated user token
expected: 200 response with {tier, entitlements, trial_ends_at, purchase_platform, cached} fields
result: [pending]

### 4. Verify RLS enforcement: free user 4th translation INSERT blocked
expected: RLS policy blocks INSERT (new row violates WITH CHECK expression)
result: [pending]

### 5. Configure RevenueCat dashboard webhook URL
expected: Webhook events reach Edge Function and update subscription_status
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
