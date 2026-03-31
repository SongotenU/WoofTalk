# PROJECT.md

## What This Is

WoofTalk is an iOS app that translates between human and dog languages with voice input/output, Core Data persistence, and community features.

## Core Value

The core value is enabling natural communication between humans and dogs through bidirectional translation with voice capabilities.

## Current State

v3.0 (M004) Complete:
- Platform Expansion — Android app, Supabase backend, cross-platform sync (6 phases, 29 requirements, 81 files)

Current codebase includes:
- **iOS**: SwiftUI translation app with voice, community, AI, analytics
- **Android**: Kotlin + Jetpack Compose app with full iOS parity
- **Backend**: Supabase (PostgreSQL, 8 tables, 30+ RLS policies, 6 Edge Functions)
- **Cross-platform**: Shared auth, synced history, realtime activity feed

## Current Milestone: v3.1 Web + Smartwatch

**Goal:** Expand WoofTalk to web and smartwatch platforms for complete multi-platform coverage.

**Target features:**
- **Web app** (React/Next.js) — Full parity with mobile: translation, voice, community, social, sync
- **Smartwatch** (Wear OS) — Quick translation companion: voice input, quick translate, history
- **4-phase execution**: Web Core → Web Voice & Community → Watch Core → Integration

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