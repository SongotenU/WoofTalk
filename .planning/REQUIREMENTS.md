# Requirements

---

# v3.1 Requirements — Web + Smartwatch ARCHIVED

**Milestone:** v3.1 Web + Smartwatch
**Date:** 2026-03-31
**Status:** Complete — see `.planning/milestones/v3.1-ROADMAP.md`

## Web Core (Phase 25)

- [x] **WEB-01**: Next.js app with React, TypeScript, Tailwind CSS, and shadcn/ui components
- [x] **WEB-02**: Supabase client integration for auth, database, and realtime subscriptions
- [x] **WEB-03**: Translation engine port to TypeScript with same vocabulary and output as iOS/Android
- [x] **WEB-04**: Translation UI with text input, language selector, result display, and history
- [x] **WEB-05**: PWA support with service worker, offline caching, and install prompt
- [x] **WEB-06**: Responsive design for mobile, tablet, and desktop viewports

## Web Voice & Community (Phase 26)

- [x] **WEB-VOICE-01**: Web Speech API (SpeechRecognition) for voice input
- [x] **WEB-VOICE-02**: Web Speech API (SpeechSynthesis) for voice output with configurable speed/pitch
- [x] **WEB-COMMUNITY-01**: Community phrase browser with search, filter, and pagination
- [x] **WEB-COMMUNITY-02**: Phrase contribution with submission, validation, and spam detection
- [x] **WEB-SOCIAL-01**: Social features: follow/unfollow, leaderboards, activity feed
- [x] **WEB-SHARE-01**: Share translations via Web Share API and copy-to-clipboard
- [x] **WEB-SYNC-01**: Cross-platform sync with iOS and Android (shared auth, history, social graph)

## Watch Core (Phase 27)

- [x] **WATCH-01**: Wear OS app with Kotlin and Compose for Wearables
- [x] **WATCH-02**: Voice input using SpeechRecognizer optimized for watch form factor
- [x] **WATCH-03**: Quick translation UI with glanceable result display
- [x] **WATCH-04**: Translation history accessible from watch
- [x] **WATCH-05**: Supabase integration for sync with phone app and cloud
- [x] **WATCH-06**: Complication for quick translation launch from watch face

## Integration (Phase 28)

- [x] **INTEGRATION-WEB-01**: End-to-end web flow: voice → translate → share → sync to mobile
- [x] **INTEGRATION-WATCH-01**: End-to-end watch flow: voice → translate → sync to phone
- [x] **INTEGRATION-CROSS-01**: Cross-platform sync validation across iOS, Android, Web, Watch
- [x] **INTEGRATION-PERF-01**: Web performance: LCP <2.5s, FID <100ms, CLS <0.1
- [x] **INTEGRATION-DEPLOY-01**: Web deployment configured (Vercel/Netlify), Watch app ready for Play Store

---

# v4.0 Requirements — Enterprise

**Milestone:** v4.0 Enterprise
**Date:** 2026-04-02
**Goal:** Open WoofTalk platform to third-party integrations via REST API, provide admin tools for content moderation and user management, and support team/organization collaboration with role-based access control.

## API Gateway (Phase 29)

- [ ] **API-01**: REST API endpoints exposed via Supabase Edge Functions (translation, phrases, analytics)
- [ ] **API-02**: API key generation, naming, and revocation
- [ ] **API-03**: Per-key rate limiting with configurable limits
- [ ] **API-04**: API key scoping (read-only, translate-only, analytics-only)
- [ ] **API-05**: Usage tracking and per-key usage dashboard
- [ ] **API-06**: API response versioning (v1, v2) with deprecation headers
- [ ] **API-07**: Request/response schema validation (zod) at API boundary

## Admin Dashboard (Phase 30)

- [ ] **ADMIN-01**: User list with search, filter, and pagination
- [ ] **ADMIN-02**: User role management (promote/demote, ban/suspend)
- [ ] **ADMIN-03**: Content moderation queue (report review, approve/reject, takedown)
- [ ] **ADMIN-04**: Audit log (who did what, when — queryable and filterable)
- [ ] **ADMIN-05**: Usage analytics dashboard (translations/day, active users, API usage)
- [ ] **ADMIN-06**: Bulk moderation actions (ban multiple, delete multiple phrases)

## Organization & Team Management (Phase 31)

- [ ] **ORG-01**: Create and configure organization (name, slug, plan type)
- [ ] **ORG-02**: Invite members by email (with expiry and status tracking)
- [ ] **ORG-03**: Role hierarchy: Owner, Admin, Member, Viewer with distinct permissions
- [ ] **ORG-04**: Remove member and transfer ownership
- [ ] **ORG-05**: Organization-level API key pool (shared keys across team members)
- [ ] **ORG-06**: Team subdivision within organizations (optional group structure)

## Data Model & Security (Infrastructure — Phase 29)

- [ ] **DATA-01**: New database tables: `organizations`, `organization_members`, `teams`, `team_members`, `api_keys`, `api_key_usage`
- [ ] **DATA-02**: `org_id` column added to all existing org-scoped tables (with batched migration)
- [ ] **DATA-03**: RLS policy migration: extend 30+ existing policies with org-scoped variants
- [ ] **DATA-04**: Migrate existing `raw_user_meta_data->>'role'` checks to `organization_members.role` join table
- [ ] **DATA-05**: API key validation via SQL function (bcrypt hash comparison for RLS policies)
- [ ] **DATA-06**: Rate limit enforcement via Upstash Redis (token bucket algorithm)

## Integration (Phase 32)

- [ ] **E2E-01**: End-to-end enterprise flow (org → invite → API key → external call → dashboard usage)
- [ ] **E2E-02**: Admin moderation of API-created content with immediate revocation effect
- [ ] **E2E-03**: Cross-org data leakage prevention (RLS isolation validation)
- [ ] **E2E-04**: Consumer client regression testing (iOS, Android, Web, Watch unaffected)
- [ ] **E2E-05**: Verification of all 25 v4.0 requirements, zero critical bugs

---

## Future Requirements (Deferred)

| Requirement | Description | Rationale for Deferral |
|-------------|-------------|------------------------|
| **SSO-01** | SSO/SAML integration for enterprise orgs | Requires Supabase Pro plan ($25/mo), validate budget before committing |
| **BILLING-01** | Usage-based billing tiers per org | Complex; defer until org usage patterns are understood |
| **API-08** | API playground (interactive documentation) | Developer experience, not revenue-critical |
| **API-09** | Per-key IP allowlisting | Security hardening, can be added after launch |
| **API-10** | SDK for API consumers (TypeScript, Python) | Post-launch developer ecosystem play |
| **ORG-07** | Team-level workspaces with separate content | Complex content isolation; start with org-level only |
| **ADMIN-07** | Automated spam detection with trust scores | ML complexity; manual moderation is table stakes |

## Out of Scope (Explicit Exclusions)

| Feature | Reason |
|---------|--------|
| Web push notifications | Still deferred — not an enterprise driver |
| Apple Watch app | No change from v3.1 decision |
| Dedicated backend server | Supabase Edge Functions are sufficient; no separate infra needed |
| Full Salesforce-style admin panel | Scope creep risk — scope to moderation and user management only |
| GraphQL API | REST is sufficient for WoofTalk's API surface; revisit at >10K API consumers |
| Self-hosted RBAC service (Permit.io, Oso) | Supabase RLS is sufficient and database-level |

---

## Traceability

| Phase | Requirements | Success Criteria | Status |
|-------|-------------|-----------------|--------|
| Phase 29: API Gateway & Data Model | API-01 through API-07, DATA-01 through DATA-06 | Third-party can call translate API with a key, get rate-limited response, see usage in dashboard; multi-tenant DB operational | Not started |
| Phase 30: Admin Dashboard | ADMIN-01 through ADMIN-06 | Admin can find, ban, and moderate content from a single dashboard | Not started |
| Phase 31: Organization & Team Management | ORG-01 through ORG-06 | Organization can be created, members invited, roles assigned, and org API keys managed | Not started |
| Phase 32: Integration | E2E-01 through E2E-05 | End-to-end enterprise flow works, RLS prevents cross-org leakage, consumer clients unaffected | Not started |

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Phase 29 | Pending |
| API-02 | Phase 29 | Pending |
| API-03 | Phase 29 | Pending |
| API-04 | Phase 29 | Pending |
| API-05 | Phase 29 | Pending |
| API-06 | Phase 29 | Pending |
| API-07 | Phase 29 | Pending |
| DATA-01 | Phase 29 | Pending |
| DATA-02 | Phase 29 | Pending |
| DATA-03 | Phase 29 | Pending |
| DATA-04 | Phase 29 | Pending |
| DATA-05 | Phase 29 | Pending |
| DATA-06 | Phase 29 | Pending |
| ADMIN-01 | Phase 30 | Pending |
| ADMIN-02 | Phase 30 | Pending |
| ADMIN-03 | Phase 30 | Pending |
| ADMIN-04 | Phase 30 | Pending |
| ADMIN-05 | Phase 30 | Pending |
| ADMIN-06 | Phase 30 | Pending |
| ORG-01 | Phase 31 | Pending |
| ORG-02 | Phase 31 | Pending |
| ORG-03 | Phase 31 | Pending |
| ORG-04 | Phase 31 | Pending |
| ORG-05 | Phase 31 | Pending |
| ORG-06 | Phase 31 | Pending |
| E2E-01 | Phase 32 | Pending |
| E2E-02 | Phase 32 | Pending |
| E2E-03 | Phase 32 | Pending |
| E2E-04 | Phase 32 | Pending |
| E2E-05 | Phase 32 | Pending |

**Coverage:** 30/30 v4.0 requirements mapped to 4 phases
