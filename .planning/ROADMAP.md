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

## Milestone v4.1: Security & Deployment Hardening ✅ COMPLETE

**Delivered:** 2026-04-02 — Admin auth guards, API IP allowlisting, consumer regression suite, email invites, deployment docs

Archive: `.planning/milestones/v4.1-ROADMAP.md`

---

## Milestone M007: AR/VR Mixed Reality

**Goal:** Extend WoofTalk to immersive platforms with Apple Vision Pro (ARKit) and Meta Quest (Unity) for spatial translation overlays, dog bark detection, and virtual dog avatars.
**Planned:** 2026-Q2

---

### Phase 38: AR Foundation

**Status:** Planned  
**Requirements:** AR-01, AR-02, AR-03, AR-04, AR-05, AR-06

**Plans:** 3 plans

**Plan list:**
- [ ] 38-01-PLAN.md — Project setup & infrastructure (Xcode visionOS project, entitlements, Supabase)
- [ ] 38-02-PLAN.md — Dog bark detection (Core ML, Vision framework, audio pipeline)
- [ ] 38-03-PLAN.md — Translation bubble & integration (RealityKit entity, Edge Function, spatial audio)

**Scope:**
- Vision Pro project setup, RealityKit, ARKit integration, Xcode configuration
- Core ML dog bark classifier trained on dog sound datasets (accuracy >85%)
- Real-time camera passthrough with ARView and session management
- Basic translation bubble rendering at fixed world position (2m in front)
- Edge Function API integration for translation calls (auth, error handling)
- Simple spatial audio playback anchored to bubble position

**Success Criteria:**
1. Xcode project builds and runs on Vision Pro simulator
2. Dog bark detection triggers with >70% confidence threshold
3. Translation bubble appears within 2 seconds, positioned 2m away facing user
4. Text readable (24pt), bubble dismissible via tap
5. Spatial audio plays from bubble location
6. No crashes or memory leaks in 10-minute session (90 FPS target)

---

### Phase 39: AR Spatial UX

**Status:** Planned  
**Requirements:** AR-07, AR-08, AR-09, AR-10, AR-11, AR-12

**Scope:**
- Gaze-based dog position estimation using ARKit raycast and hit-testing
- Bubble placement engine with distance clamping (1-10m), billboarding, occlusion checks
- Readability optimization (font size, contrast, drop shadow, background opacity)
- Performance tuning to maintain 90 FPS with 3+ active bubbles
- User-controlled bubble pinning and manual placement gestures
- Environmental awareness (avoid placing bubbles inside walls/furniture)

---

### Phase 40: VR Foundation

**Status:** Planned  
**Requirements:** VR-01, VR-02, VR-03, VR-04, VR-05, VR-06

**Scope:**
- Unity project with Meta XR SDK, Oculus Integration, Quest deployment target
- Dog avatar 3D model with idle, bark, and head-turn animations (FBX rig)
- Hand tracking integration (OVRHand) for menu navigation and gaze-based triggers
- Translation bubble system using TextMeshPro in world space, billboarded to user
- Bark detection using TensorFlow Lite model (accuracy >85%)
- Spatial audio via Oculus Spatializer with attenuation and direction

---

### Phase 41: VR Environments & Polish

**Status:** Planned  
**Requirements:** VR-07, VR-08, VR-09, VR-10, VR-11, VR-12

**Scope:**
- Multiple virtual environments (park, living room, beach) with modular assets
- Dog avatar customization (breed selection, color, accessories) using Supabase Storage
- Performance optimization for Quest 2 (72 FPS) and Quest 3 (90 FPS), quality presets
- Motion sickness mitigation (head-locked UI, comfort mode, session warnings)
- Environment selection menu, settings UI (volume, bubble opacity, comfort toggles)
- User testing and iteration on VR comfort and usability

---

### Phase 42: Cross-Platform Integration

**Status:** Planned  
**Requirements:** X-01, X-02, X-03, X-04, X-05, X-06, DATA-ARVR-01 through DATA-ARVR-06

**Scope:**
- Translation history sync across all platforms (iOS, Android, Web, Watch, AR, VR) via Supabase
- Shared user settings (bubble preferences, audio volume, default platform)
- Platform-specific analytics (session length, accuracy feedback, FPS metrics)
- visionOS App Store submission guide, TestFlight beta distribution
- Meta Quest Store submission (screenshots, videos, compliance checklist)
- Deployment documentation, user guides, fallback strategies (iPhone ARKit for non-Vision Pro)

---
