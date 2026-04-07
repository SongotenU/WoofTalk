# PROJECT.md

## What This Is

WoofTalk is an iOS app that translates between human and dog languages with voice input/output, Core Data persistence, and community features.

## Core Value

The core value is enabling natural communication between humans and dogs through bidirectional translation with voice capabilities.

## Current State

v3.1 (M005) Complete:
- Web + Smartwatch — Next.js web app, Wear OS companion app (4 phases, 24 requirements)

v4.0 (Enterprise) Complete:
- REST API gateway, admin dashboard, org/team management (4 phases, 107 files, 30 requirements)

v4.1 (Security & Deployment) Complete:
- Admin auth guards, API IP allowlisting, consumer regression suite, email invites, deployment docs (5 phases)

Current codebase includes:
- **iOS**: SwiftUI translation app with voice, community, AI, analytics
- **Android**: Kotlin + Jetpack Compose app with full iOS parity
- **Backend**: Supabase (PostgreSQL, 8 tables, 30+ RLS policies, 6 Edge Functions)
- **Cross-platform**: Shared auth, synced history, realtime activity feed
- **Web**: Next.js app with voice I/O, community, social, PWA, Supabase sync
- **Watch**: Wear OS companion app with voice input, glanceable results, Supabase sync
- **API Gateway**: RESTful API with API key auth, rate limiting, usage tracking
- **Admin Dashboard**: Full CMS for user management, content moderation, analytics

## Current Milestone: M008 — Production Hardening (Complete)

**Status:** Complete ✅ — All 7 phases (43-49) shipped on 2026-04-07
**Shipped:** 2026-04-07

**Scope:**
- Phase 43: Memory Leak Elimination
- Phase 44: Structural Cleanup
- Phase 45: Performance Hot Paths
- Phase 46: Resilience Infrastructure
- Phase 47: CI/CD + Production Deployment
- Phase 48: Observability + Monitoring
- Phase 49: Scale Testing

**Artifacts:**
- Phase directories: `.planning/phases/43-49/`
- Archive: `.planning/milestones/v0.2.0-ROADMAP.md`, `.planning/milestones/v0.2.0-REQUIREMENTS.md`
- State: `.planning/STATE.md` (milestone complete)

---

## Next Milestone Goals

**v1.0 — Planning Phase** (Current)

The project is now production-ready with full CI/CD, observability, and resilience. Next steps:

- Define v1.0 feature set and requirements
- Research user experience improvements
- Plan MVP scope for public release
- Establish development velocity baselines

**Start planning:** Run `/gsd-new-milestone` to begin v1.0 definition.

## Architecture / Key Patterns

### iOS (Existing)
- SwiftUI for modern, declarative UI
- Core Data for persistence (translation history, user data, community phrases)
- AVFoundation for voice input/output capabilities
- Rule-based translation for MVP, can enhance with AI later
- Community features for user engagement and content diversity
- Subscription model for premium features

### Android (v3.0 — New)
- Kotlin + Jetpack Compose for modern, declarative UI
- Room Database for local persistence (Core Data equivalent)
- SpeechRecognizer + TextToSpeech for voice I/O
- Translation engine logic ported from Swift to Kotlin
- Shared cloud backend for cross-platform sync

### Web (v3.1 — New)
- React/Next.js for modern web app
- Web Speech API for voice I/O
- Supabase client for shared backend
- Tailwind CSS + shadcn/ui for UI components
- PWA support for offline functionality

### Smartwatch (v3.1 — New)
- Wear OS (Kotlin) for watch app
- SpeechRecognizer for voice input
- Quick translation companion experience
- Synced with phone app via Supabase

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [x] M001: Core Translation App — Complete iOS app with translation, voice, community, and premium features
- [x] M002: Community Features — Complete with all 6 slices
- [x] M003: Advanced Features — AI translation, real-time, multi-language, analytics, performance, integration
- [x] M004: Platform Expansion — Android, Web, and Smartwatch
- [x] M005: Platform Expansion (continued) — Web, Smartwatch → v3.1
- [x] M006: Enterprise — Complete as v4.0 (API gateway, admin dashboard, org/team management)
- [x] M007: AR/VR — Augmented reality and virtual reality translation features (Vision Pro + Quest)
- [ ] M008: Production Hardening — Current Milestone

## Notes

- M006 (Enterprise) was implemented as v4.0 milestone (completed 2026-04-02)
- M007 (AR/VR Mixed Reality) completed 2026-04-04 — research, requirements, and all 5 phases defined
- M008 is the next active milestone, focusing on production hardening and deployment
- v4.1 (Security & Deployment Hardening) was a security cleanup milestone following v4.0
- Last updated: 2026-04-04 after v0.1.0 milestone
