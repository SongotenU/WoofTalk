# Project Roadmap

## Milestone v1.0: Core Translation Engine (M001) COMPLETE

**Status:** All phases complete and shipped

### Phases:
- S01: Core Translation Engine & Basic UI
- S02: Voice Input & Advanced Translation Features
- S03: Community Phrases & Social Features
- S04: Settings & Personalization
- S05: Advanced Features & Analytics
- S06: Final Integration & Testing

---

## Milestone v1.0: Community Features (M002) COMPLETE

**Completed Slices:** S01-S06 (User Auth, Contribution, Browser, Social, Moderation, Integration)

---

## Milestone v2.0: Advanced Features (M003) COMPLETE

**Completed Slices:** S01-S06 (AI Translation, Real-time, Multi-language, Analytics, Performance, Integration)

---

## Milestone v3.0: Platform Expansion (M004) COMPLETE

**Goal:** Expand WoofTalk from iOS-only to Android with shared cloud backend and full cross-platform account sync.
**Completed:** 2026-03-31
**Total Files:** 69 new files across 5 phases
**Total Requirements:** 29 (all delivered)

### Phases: 19-24
- Phase 19: Backend Infrastructure
- Phase 20: Android Core Translation
- Phase 21: Android Voice I/O
- Phase 22: Android Community & Social
- Phase 23: Cross-Platform Sync
- Phase 24: Final Integration

---

## Milestone v3.1: Web + Smartwatch (M005) ✅ COMPLETE

**Goal:** Expand WoofTalk to web (React/Next.js) and smartwatch (Wear OS) platforms for complete multi-platform coverage.
**Completed:** 2026-03-31

### Phases: 25-28
- Phase 25: Web Core ✅ — Next.js app with React, TypeScript, Tailwind CSS, shadcn/ui
- Phase 26: Web Voice & Community ✅ — Web Speech API voice I/O, community phrases, social
- Phase 27: Watch Core ✅ — Wear OS + Compose for Wearables, voice input, Supabase sync
- Phase 28: Integration ✅ — E2E flows validated, Vercel/Play Store deployment configs

---

## Milestone v4.0: Enterprise ✅ COMPLETE

**Goal:** Open WoofTalk platform to third-party integrations via REST API, provide admin tools for content moderation and user management, and support team/organization collaboration with role-based access control.
**Delivered:** 2026-04-02 — 107 files, 30/30 requirements

## Phases

- [x] **Phase 29: API Gateway & Data Model** — 9 migrations, 2 Edge Functions, API keys, rate limiting
- [x] **Phase 30: Admin Dashboard** — 6 pages, 7 API routes, bulk moderation
- [x] **Phase 31: Organization & Team Management** — 4 pages, 6 API routes, invites, teams
- [x] **Phase 32: Integration** — E2E validation, cross-org isolation, consumer regression verified

---

## Milestone v4.1: Security & Deployment Hardening

**Goal:** Close security gaps from v4.0 execution — admin route guards, API IP allowlisting, consumer regression testing, email invites, and E2E verification against live Supabase.
**Target date:** 2026-04-03

## Phases

- [x] **Phase 33: Admin Auth** ✅ — middleware.ts, admin-auth.ts, 7 API routes protected
- [x] **Phase 34: API Security Hardening** ✅ — IP allowlist, OpenAPI spec, CORS lockdown
- [ ] **Phase 35: Consumer Client Regression** — Automated tests for 4 existing Edge Functions against new RLS
- [ ] **Phase 36: Email & Invites** — Resend/SendGrid integration for org invites, `/invite/:token` acceptance
- [ ] **Phase 37: Deployment & E2E Verification** — Live test run, VERIFICATION.md

## Phase Details

### Phase 33: Admin Auth
**Goal**: No unauthorized access to admin pages or API routes
**Depends on**: Phase 29 (org tables, `is_admin()` function)
**Requirements**: SEC-AUTH-01, SEC-AUTH-02, SEC-AUTH-03
**Success Criteria**:
  1. Unauthenticated request to `/admin/users` redirects to `/403`
  2. Non-admin user hitting `/api/admin/users/role` gets 401
  3. Admin user can access all admin routes normally

### Phase 34: API Security Hardening
**Goal**: Close exposed API surface gaps
**Depends on**: Phase 29 (api_keys table, api-gateway)
**Requirements**: SEC-API-01 (IP allowlist), SEC-API-02 (OpenAPI spec), SEC-API-03 (CORS)
**Success Criteria**:
  1. API key with non-empty `allowed_ips` rejects requests from other IPs with 403
  2. `GET /v1/openapi.json` returns valid OpenAPI 3.1 spec
  3. CORS only allows configured origins, not wildcard `*`

### Phase 35: Consumer Regression Suite
**Goal**: Existing clients not broken by v4.0 RLS migration
**Depends on**: Phase 29 (RLS policy migration)
**Requirements**: SEC-REG-01, SEC-REG-02
**Success Criteria**:
  1. All 4 existing Edge Functions (translate, phrases-search, leaderboard, activity-batch) return correct responses with session auth
  2. Consumer users (org_id IS NULL) can still read/write their own data
  3. Script runs in CI, blocks merge on failure

### Phase 36: Email & Invites
**Goal**: Complete org invitation flow
**Depends on**: Phase 31 (invites in DB, invite_token column)
**Requirements**: SEC-EMAIL-01 (delivery), SEC-EMAIL-02 (acceptance), SEC-EMAIL-03 (expiry)
**Success Criteria**:
  1. Invite email sent with token and expiry date
  2. Visiting `/invite/:token` with valid token joins org and redirects to `/org`
  3. Expired token returns clear error message

### Phase 37: Deployment & E2E Verification
**Goal**: Validate complete v4.0 + v4.1 stack against live Supabase
**Depends on**: Phases 33, 34, 35, 36
**Requirements**: SEC-DEPLOY-01, SEC-DEPLOY-02, SEC-DEPLOY-03
**Success Criteria**:
  1. `e2e-enterprise-test.sh` passes against live deployment with 0 failures
  2. All env vars documented, secrets rotation guide written
  3. VERIFICATION.md generated with test results

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 33. Admin Auth | Planned | Pending | — |
| 34. API Security Hardening | Planned | Pending | — |
| 35. Consumer Regression Suite | Planned | Pending | — |
| 36. Email & Invites | Planned | Pending | — |
| 37. Deployment & E2E Verification | Planned | Pending | — |
