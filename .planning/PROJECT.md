# PROJECT.md

## What This Is

WoofTalk is an iOS app that translates between human and dog languages with voice input/output, Core Data persistence, and community features.

## Core Value

The core value is enabling natural communication between humans and dogs through bidirectional translation with voice capabilities.

## Current State

v3.1 (M005) Complete:
- Web + Smartwatch — Next.js web app, Wear OS companion app (4 phases, 24 requirements)

Current codebase includes:
- **iOS**: SwiftUI translation app with voice, community, AI, analytics
- **Android**: Kotlin + Jetpack Compose app with full iOS parity
- **Backend**: Supabase (PostgreSQL, 8 tables, 30+ RLS policies, 6 Edge Functions)
- **Cross-platform**: Shared auth, synced history, realtime activity feed
- **Web**: Next.js app with voice I/O, community, social, PWA, Supabase sync
- **Watch**: Wear OS companion app with voice input, glanceable results, Supabase sync

## Current Milestone: v4.0 Enterprise

**Goal:** Open WoofTalk platform to third-party integrations via REST API, provide admin tools for content moderation, and support organization/team collaboration with RBAC.

**Target features:**
- **API Gateway** (Supabase Edge Functions) — REST API with API key auth, rate limiting, usage tracking
- **Admin Dashboard** (Next.js) — User management, content moderation, analytics, bulk actions
- **Organization & Team Management** — Multi-org hierarchy, role-based access control, org-level API keys
- **Data Model Expansion** — org-scoped tables, RLS policy migration, schema migration from consumer to multi-tenant
- **4-phase execution**: API Gateway & Data Model → Admin Dashboard → Organization & Team → Integration

## Next Milestone Goals

**M006: Enterprise**
- API access, admin features, and enterprise solutions

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
- [ ] M006: Enterprise — API access, admin features, and enterprise solutions
- [ ] M007: AR/VR — Augmented reality and virtual reality translation features