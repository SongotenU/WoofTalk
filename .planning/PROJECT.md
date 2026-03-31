# PROJECT.md

## What This Is

WoofTalk is an iOS app that translates between human and dog languages with voice input/output, Core Data persistence, and community features.

## Core Value

The core value is enabling natural communication between humans and dogs through bidirectional translation with voice capabilities.

## Current State

v1.0 (M001 + M002) Complete:
- Core Translation Engine (M001) - shipped
- Community Features (M002) - shipped with all 6 slices complete

v2.0 (M003) Complete:
- Advanced Features (M003) - all 6 slices complete (AI translation, real-time, multi-language, analytics, performance, integration)

Current codebase includes:
- Translation engine with voice input/output
- Core Data persistence
- AI translation with quality scoring
- Real-time streaming translation
- Multi-language support (Dog, Cat, Bird)
- Advanced analytics with dashboard
- Performance optimization (memory, battery, network)
- Community phrase contribution system
- Social features (sharing, following, leaderboards)
- Moderation and quality control
- Offline-first architecture
- Error reporting infrastructure

## Current Milestone: v3.0 Platform Expansion

**Goal:** Expand WoofTalk from iOS-only to Android with shared cloud backend and full cross-platform account sync.

**Target features:**
- Shared cloud backend (Firebase/Supabase) for auth, database, cloud sync
- Android app (Kotlin + Jetpack Compose) — full feature parity with iOS
- Cross-platform account sync — shared history, phrases, social graph
- 6-phase execution: Backend → Android Core → Android Voice → Android Community → Sync → Integration

## Current Milestone: v3.0 Platform Expansion

**Goal:** Expand WoofTalk from iOS-only to Android with shared cloud backend and full cross-platform account sync.

**Target features:**
- Shared cloud backend (Firebase/Supabase) for auth, database, cloud sync
- Android app (Kotlin + Jetpack Compose) — full feature parity with iOS
- Cross-platform account sync — shared history, phrases, social graph
- 6-phase execution: Backend → Android Core → Android Voice → Android Community → Sync → Integration

## Current Milestone: v3.0 Platform Expansion

**Goal:** Expand WoofTalk from iOS-only to Android with shared cloud backend and full cross-platform account sync.

**Target features:**
- Shared cloud backend (Firebase/Supabase) for auth, database, cloud sync
- Android app (Kotlin + Jetpack Compose) — full feature parity with iOS
- Cross-platform account sync — shared history, phrases, social graph
- 6-phase execution: Backend → Android Core → Android Voice → Android Community → Sync → Integration

## Next Milestone Goals

**M005: Platform Expansion (continued)**
- Web version
- Smartwatch companion app

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

### Shared Backend (v3.0 — New)
- Firebase or Supabase for auth, database, cloud sync
- REST/GraphQL API for cross-platform data access
- Real-time sync for community features and social graph

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
- [ ] M005: Platform Expansion (continued) — Web, Smartwatch
- [ ] M006: Enterprise — API access, admin features, and enterprise solutions
- [ ] M007: AR/VR — Augmented reality and virtual reality translation features