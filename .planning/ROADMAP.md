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

## Milestone v3.1: Web + Smartwatch (M005) COMPLETE

**Goal:** Expand WoofTalk to web (React/Next.js) and smartwatch (Wear OS) platforms for complete multi-platform coverage.
**Completed:** 2026-03-31

### Phases: 25-28
- Phase 25: Web Core
- Phase 26: Web Voice & Community
- Phase 27: Watch Core
- Phase 28: Integration

---

## Milestone v4.0: Enterprise

**Goal:** Open WoofTalk platform to third-party integrations via REST API, provide admin tools for content moderation and user management, and support team/organization collaboration with role-based access control.

## Phases

- [x] **Phase 29: API Gateway & Data Model** - Third-party API with Supabase Edge Functions, multi-tenant data model, API key management, rate limiting, usage tracking, versioned responses
- [x] **Phase 30: Admin Dashboard** - Next.js admin UI for user management, content moderation, analytics, audit log, bulk actions
- [x] **Phase 31: Organization & Team Management** - Org creation, member invites, RBAC role hierarchy, org-level API keys, team subdivisions
- [x] **Phase 32: Integration** - End-to-end validation across API gateway, admin dashboard, and org management; consumer client regression testing

## Phase Details

### Phase 29: API Gateway & Data Model
**Goal**: Third-party developers can call WoofTalk APIs with API keys that are validated, rate-limited, scoped, tracked, and versioned -- backed by a multi-tenant data model with org-scoped RLS policies
**Depends on**: Phase 28 (existing Supabase backend is stable)
**Requirements**: API-01, API-02, API-03, API-04, API-05, API-06, API-07, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06
**Success Criteria** (what must be TRUE):
  1. Third-party developer can call the translate API with a valid API key and receive a versioned JSON response matching the declared schema
  2. Requests exceeding the per-key rate limit are rejected with 429 status and retry-after header
  3. API key can be generated, named, scoped (read-only / translate-only / analytics-only), and revoked; scoped keys reject operations outside their scope
  4. API usage is tracked per key and queryable via a usage dashboard endpoint
  5. Multi-tenant database is operational: organizations/teams/api_keys tables exist, org_id columns on org-scoped tables, RLS policies enforce org isolation, and API key validation via SQL function (bcrypt hash) works for RLS evaluation
**Plans**: TBD

### Phase 30: Admin Dashboard
**Goal**: Platform admins can manage users, moderate content, view usage analytics, query audit logs, and execute bulk actions from a single Next.js dashboard
**Depends on**: Phase 29 (data model with org_id columns, RLS migration, api_key_usage table provides analytics data)
**Requirements**: ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05, ADMIN-06
**Success Criteria** (what must be TRUE):
  1. Admin can search, filter, and paginate through users; promote/demote user roles; ban or suspend accounts
  2. Admin can review flagged content in a moderation queue, approve or reject reports, and issue takedowns
  3. Admin can view a filterable audit log showing who did what and when across the platform
  4. Admin dashboard displays usage analytics including translations per day, active users, and API call volume
  5. Admin can perform bulk moderation actions: ban multiple users and delete multiple phrases in a single operation
**Plans**: TBD
**UI hint**: yes

### Phase 31: Organization & Team Management
**Goal**: Organizations can be created with members, role-based permissions, team subdivisions, and shared API key pools
**Depends on**: Phase 29 (organizations table, api_keys table, SQL validation functions)
**Requirements**: ORG-01, ORG-02, ORG-03, ORG-04, ORG-05, ORG-06
**Success Criteria** (what must be TRUE):
  1. User can create an organization with a name, slug, and plan type; the org is addressable by its unique slug
  2. Organization owner can invite members by email; invites have expiry timestamps and track pending/accepted/expired status
  3. Role hierarchy (Owner, Admin, Member, Viewer) is enforced with distinct permissions for org-scoped resources
  4. Owner can remove members or transfer ownership to another member; the org remains fully accessible after transfer
  5. Organization admin can generate, view, and revoke org-level API keys that are shared across team members
  6. Admin can create and manage team subdivisions within an organization with separate membership lists
**Plans**: TBD
**UI hint**: yes

### Phase 32: Integration
**Goal**: End-to-end validation that API gateway, admin dashboard, and organization management work together without breaking existing consumer clients
**Depends on**: Phases 29, 30, 31
**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04, E2E-05
**Success Criteria** (what must be TRUE):
  1. Complete enterprise flow works: create org -> invite member -> member generates org API key -> external service calls translate API -> usage appears in admin dashboard
  2. Admin can moderate content created via the API, issue ban, and verify that API key revocation takes effect immediately (401 on next call)
  3. RLS policies prevent cross-org data leakage: user in org A cannot read org B's data even with a valid API key
  4. Existing consumer clients (iOS, Android, Web, Watch) continue functioning correctly with the new RLS policies and data model
  5. All 25 v4.0 requirements are verified complete with zero critical or high-severity bugs
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. API Gateway & Data Model | Complete | Done | 2026-04-02 |
| 30. Admin Dashboard | Complete | Done | 2026-04-02 |
| 31. Organization & Team Management | Complete | Done | 2026-04-02 |
| 32. Integration | Complete | Done | 2026-04-02 |
