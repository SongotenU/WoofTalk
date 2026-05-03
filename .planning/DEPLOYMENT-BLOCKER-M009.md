
# 🚧 M009 Deployment Blocker — Phase 51 Subscription Backend

**Status**: Code Complete | Deployment Pending
**Date**: 2026-05-03
**Milestone**: M009 Subscription & Payments (v1.0.0)

---

## ⚠️ Blocked Items (5 UAT Tests)

All 5 pending UAT items require **live Supabase deployment** before verification:

| # | Test | Type | Dependencies |
|---|------|------|-------------|
| 1 | Deploy migrations + Edge Functions | Server/Infra | Supabase project, service role key |
| 2 | Webhook endpoint test | Server/Integration | RevenueCat webhook config |
| 3 | Entitlement check API | Server/Integration | Valid JWT, DB state |
| 4 | RLS enforcement | Server/Security | Supabase RLS policies |
| 5 | RevenueCat webhook URL | Third-party | RevenueCat ↔ Supabase connection |

---

## 🔧 What Needs to Be Deployed

### 1. Supabase Database Migrations
- `supabase/migrations/0013_admin_analytics_features.sql`
- `supabase/migrations/0014_subscription_enhancements.sql`
- Creates tables: `subscription_status`, `user_profiles`, `webhook_events`
- Implements RLS policies for free-tier blocking

### 2. Edge Functions
- `entitlement-webhook` — Receives RevenueCat webhooks, updates subscription status
- `entitlement-check` — Returns current tier/entitlements for authenticated users
- `translate` — Translation service function

### 3. Third-Party Configuration
- RevenueCat dashboard: Configure webhook URL → Supabase Edge Function
- Stripe account: Connected to RevenueCat products
- Supabase: Service role key for webhook auth

---

## 📦 Untracked Build Artifacts (50+ files)

These are auto-generated and safe to ignore:

```
.build/                          # SPM build/checkouts directories
.claude/worktrees/               # Git worktree leftovers  
tmp_build/                       # Temp compilation artifacts
*.lock                            # Lock files
```

**Action Taken**: Added to `.gitignore` on 2026-05-03

---

## 🚀 Deployment Steps

```bash
# 1. Link to Supabase project
supabase link --project-ref <your-project-ref>

# 2. Deploy database
supabase db push

# 3. Deploy Edge Functions
supabase functions deploy entitlement-webhook
supabase functions deploy entitlement-check
supabase functions deploy translate

# 4. Get service role key from Supabase dashboard
# Settings → API → Service Role Key

# 5. Configure RevenueCat webhook
# Dashboard → Settings → Webhooks
# URL: https://<project>.supabase.co/functions/v1/entitlement-webhook
# Secret: <service_role_key>

# 6. Run UAT tests
# See .planning/reviews/UAT-AUDIT-REPORT.md for test details
```

---

## ✅ Verification Checklist

- [ ] Supabase migrations deployed (tables exist)
- [ ] Edge Functions deployed and responding
- [ ] RevenueCat webhook configured and active
- [ ] Webhook test returns 200 + updates DB
- [ ] Entitlement check returns tier data
- [ ] RLS blocks free user INSERT attempts

---

## 📊 Current State

**Code**: ✅ Complete and reviewed  
**Tests**: ✅ 24/29 UAT passed (5 require live deployment)  
**Deployment**: ⏳ Pending — needs Supabase + RevenueCat access  
**Documentation**: ✅ Complete  

**Next**: Await credentials or schedule deployment window

---

## 🔗 Related

- Phase 51: Subscription Backend
- UAT Report: `.planning/reviews/UAT-AUDIT-REPORT.md`
- Verification: `VERIFICATION.md` (Phase 50, 52, 53, 54)
