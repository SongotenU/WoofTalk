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

## Next Milestone Goals

**M004: Platform Expansion**
- Android app development
- Web version
- Smartwatch companion app
- Cross-platform sync

## Architecture / Key Patterns

- SwiftUI for modern, declarative UI
- Core Data for persistence (translation history, user data, community phrases)
- AVFoundation for voice input/output capabilities
- Rule-based translation for MVP, can enhance with AI later
- Community features for user engagement and content diversity
- Subscription model for premium features

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [x] M001: Core Translation App — Complete iOS app with translation, voice, community, and premium features
- [x] M002: Community Features — Complete with all 6 slices
- [x] M003: Advanced Features — AI translation, real-time, multi-language, analytics, performance, integration
- [ ] M004: Platform Expansion — Android, Web, and Smartwatch
- [ ] M005: Enterprise — API access, admin features, and enterprise solutions
- [ ] M006: AR/VR — Augmented reality and virtual reality translation features