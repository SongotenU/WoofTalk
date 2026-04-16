---
phase: 51
slug: subscription-backend
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — manual testing via Supabase SQL editor + Edge Function invocations |
| **Config file** | none |
| **Quick run command** | `supabase db push && supabase functions deploy` |
| **Full suite command** | Manual: apply migration, invoke webhook + entitlement-check, verify RLS |
| **Estimated runtime** | ~60 seconds (manual) |

---

## Sampling Rate

- **After every task commit:** Apply migration / deploy Edge Function, verify no errors
- **After every plan wave:** End-to-end: webhook → subscription_status → RLS enforcement
- **Before `/gsd-verify-work`:** All 10 SUB requirements manually verified
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | SUB-01 | — | subscription_status table with correct schema | migration | `SELECT * FROM subscription_status LIMIT 0` | ❌ W0 | ⬜ pending |
| 51-01-02 | 01 | 1 | SUB-02 | — | revenuecat_id column on user_profiles | migration | `SELECT revenuecat_id FROM user_profiles LIMIT 0` | ❌ W0 | ⬜ pending |
| 51-01-03 | 01 | 1 | SUB-08 | T-51-03 | RLS limits free users to 3 INSERTs/day | integration | Insert 4 rows as free user, verify 4th rejected | ❌ W0 | ⬜ pending |
| 51-01-04 | 01 | 1 | SUB-09 | T-51-03 | RLS checks subscription_tier | integration | Upgrade user, verify unlimited inserts | ❌ W0 | ⬜ pending |
| 51-02-01 | 02 | 1 | SUB-03 | T-51-01 | Webhook handler processes RevenueCat events | integration | POST mock event to Edge Function | ❌ W0 | ⬜ pending |
| 51-02-02 | 02 | 1 | SUB-04 | T-51-02 | Idempotency: duplicate event_id ignored | integration | POST same event twice, verify one row | ❌ W0 | ⬜ pending |
| 51-02-03 | 02 | 1 | SUB-05 | — | Webhook returns 200 OK quickly | unit | Measure response time < 1s | ❌ W0 | ⬜ pending |
| 51-03-01 | 03 | 2 | SUB-06 | — | entitlement-check verifies via REST API | integration | Call with stale user, verify API call | ❌ W0 | ⬜ pending |
| 51-03-02 | 03 | 2 | SUB-07 | — | 5-minute TTL on entitlement cache | integration | Call within 5 min (no API), after 5 min (API) | ❌ W0 | ⬜ pending |
| 51-04-01 | 04 | 2 | SUB-10 | T-51-03 | Edge Function rejects premium requests from free users | integration | Call translate as free user 4x, verify 4th rejected | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] RevenueCat sandbox environment configured for webhook testing
- [ ] Test users with different subscription tiers (free, trial, pro)
- [ ] REVENUECAT_WEBHOOK_AUTH secret set in Supabase Edge Function secrets
- [ ] REVENUECAT_API_KEY secret set in Supabase Edge Function secrets

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Webhook receives real RevenueCat events | SUB-03 | Requires RevenueCat dashboard webhook URL config + sandbox purchase | 1. Configure webhook URL in RevenueCat dashboard 2. Make sandbox purchase 3. Verify subscription_status updated |
| RLS enforces 3/day limit for real client inserts | SUB-08 | Requires authenticated client connecting to real Supabase | 1. Sign in as free user 2. Insert 3 translations via client 3. Verify 4th rejected |
| Entitlement cache refreshes after 5 minutes | SUB-07 | Requires waiting 5+ minutes between calls | 1. Call entitlement-check 2. Note no RevenueCat API call 3. Wait 5 min 4. Call again, verify API call made |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
