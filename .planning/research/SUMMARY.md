# Project Research Summary

**Project:** M007 AR/VR — Mixed Reality Translation Features
**Domain:** Extending WoofTalk to Augmented Reality (Vision Pro) and Virtual Reality (Meta Quest)
**Researched:** 2026-04-03
**Confidence:** HIGH

## Executive Summary

WoofTalk, a multi-platform dog-human translation app (iOS, Android, Web, Watch), is expanding into immersive computing: AR on Apple Vision Pro and VR on Meta Quest. The goal: enable users to see translations as spatial overlays in the real world (AR) or interact with virtual dogs in immersive environments (VR). This is a client-only extension — no new backend infrastructure needed. The existing Supabase backend, Edge Functions, and translation engine are reused; only new frontend applications are built using native ARKit/RealityKit (visionOS) and Unity/Meta XR SDK (Quest).

The primary technical challenge is **3D UI/UX**: placing readable translation bubbles in world space, estimating dog position without body tracking, and maintaining performance (90 FPS) while processing dog bark audio on-device. Dog body tracking does not exist in ARKit — we must use gaze direction, audio direction, and manual placement heuristics. VR is simpler because the dog is an avatar with known position.

Key risks: Vision Pro's tiny market share (~0.1%) may not justify development cost, but the PR/innovation value is high. Dog bark detection accuracy (80-90% in quiet environments) must be validated with real users. VR motion sickness is a serious concern requiring extensive comfort testing.

Recommended approach: **5-phase rollout** across 38-42, with AR first (simpler than VR in some ways, as no avatar needed), then VR implementation. Both platforms should be treated as premium showcases rather than primary user flows.

---

## Key Findings

### Recommended Stack

**AR (Vision Pro):**
- ARKit + RealityKit (native Apple frameworks)
- SwiftUI for UI overlay
- Vision framework for dog bark detection (custom Core ML model)
- Spatial Audio API for 3D sound
- Xcode 16+, Swift 6, visionOS SDK

**VR (Meta Quest):**
- Unity 2022 LTS + Meta XR SDK
- Oculus Integration for hand tracking/passthrough
- TextMeshPro for VR text rendering
- TensorFlow Lite for on-device bark detection
- Oculus Spatializer for 3D audio

**Backend:**
- No changes to existing Supabase + Edge Functions
- New 3D position storage: `spatial_position JSONB` in `translation_history`
- Platform tracking: `platform` column (ar_vision, vr_quest)

**What NOT to build:**
- No cross-platform AR/VR engine (Unity AR Foundation/Unreal) — native is better for this scope
- No custom dog body tracking computer vision (unsolved)
- No multi-user AR/VR networking (defer to V2)
- No cloud-based audio processing (on-device only)

---

### Platform Comparison

| Aspect | Vision Pro (AR) | Meta Quest (VR) |
|--------|-----------------|-----------------|
| **Development** | Swift + RealityKit (native) | Unity + Meta SDK (managed) |
| **Rendering** | 90 FPS, high pixel density | 72/90 FPS, lower resolution |
| **UI Paradigm** | Spatial - text in world space | Immersive - 2D/3D hybrid |
| **Dog Representation** | Real dog (via camera) | Virtual avatar (3D model) |
| **Tracking Challenge** | Dog body position unknown | Known (avatar position) |
| **Audio Source** | Real dog barks (microphone) | Virtual dog (pre-baked sounds) |
| **Input** | Hand tracking, eye tracking, voice | Hand tracking or controllers |
| **Market Size** | Very small (<1M) | Larger (~20M Quest users) |
| **App Store** | visionOS (separate review) | Quest Store (Meta review) |
| **Performance Budget** | 90 FPS (<11ms/frame) | 90 FPS (<11ms/frame) |

---

### Expected Features

**Must have (table stakes):**
- AR: Real-time camera passthrough, gaze-based translation bubble placement, dog bark detection, spatial audio
- VR: Virtual dog avatar, translation bubbles above avatar, hand-tracked navigation, environment selection
- Both: Sync translation history with cloud, user authentication via existing Supabase

**Should have (competitive differentiators):**
- AR: Dog size estimation (scale bubbles appropriately), environmental occlusion (bubbles don't clip through walls), breed-specific bark profiles
- AR: Multi-user AR (multiple Vision Pros sharing same space) - very advanced
- VR: Multiple virtual environments (park, home, beach), dog avatar customization (breed, color, accessories)
- VR: Hand-tracked gestures for "listen to dog" and "pin translation"

**Defer (V2):**
- True dog body tracking with custom CV model
- AR multi-user presence and shared translations
- Cross-platform AR/VR sessions (iPhone users join Quest VR)
- Cloud-based dog voice synthesis (bark → speech)

---

### Development Phases (5 Phases)

**Phase 38: AR Foundation & Dog Bark Detection**
- Vision Pro project setup, RealityKit sandbox, Core ML dog bark classifier
- Translation API integration (Edge Function calls)
- Deliver: Simple fixed-position AR translation bubble

**Phase 39: AR Spatial UX & Anchoring**
- Gaze-based dog position estimation, bubble placement engine, spatial audio
- Occlusion handling, readability optimization, performance tuning (90 FPS)
- Deliver: Usable AR translation MVP

**Phase 40: VR Foundation & Avatar System**
- Unity + Meta XR SDK setup, dog avatar with animations, translation bubble system
- Hand tracking integration, environment basics
- Deliver: Seated VR experience with virtual dog

**Phase 41: VR Environments & Polish**
- Multiple virtual scenes, performance optimization, motion sickness mitigation
- Comfort modes, user settings, bubble UI polish
- Deliver: Polished VR experience (Quest 2/3 compatible)

**Phase 42: Cross-Platform Sync & Store Deployment**
- History sync with mobile/web clients, platform analytics, store submissions (visionOS App Store, Quest Store)
- Documentation, user guides, beta testing
- Deliver: M007 complete, AR and VR shipped

---

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Dog body tracking unsolved | Certain | High (affects AR UX) | Use gaze/audio heuristics, defer true tracking |
| Vision Pro market too small | High | Medium (ROI) | Position as premium showcase, use iPhone ARKit fallback |
| Dog bark detection accuracy <80% | Medium | High | User-controlled activation, confidence threshold, feedback loop |
| VR motion sickness complaints | High | Medium (retention) | Head-locked UI, 90 FPS target, comfort toggle, session warnings |
| Performance misses 90 FPS | Medium | Medium | Aggressive GPU profiling, quality presets per device |
| App Store rejection (privacy) | Low | High | Clear camera usage disclosure, opt-in only |

---

### Success Criteria

**Product:**
- AR translation bubble appears within 2 seconds of dog bark
- VR dog avatar responds to barks within 1 second
- Translation accuracy feedback >70% positive from beta users
- Users complete at least 3 AR/VR sessions on average
- No critical bugs (crashes, framerate <60 FPS) in release builds

**Technical:**
- 90 FPS maintained on Vision Pro with 3+ bubbles active
- 90 FPS on Quest 3, 72 FPS on Quest 2
- Dog bark detection F1 score >0.85 in quiet environments
- End-to-end latency (bark → bubble) <3 seconds
- Zero cross-organizational data leakage in RLS

---

### Out of Scope (Explicit)

- ARCore (Android AR) - too fragmented, low penetration
- Unreal Engine - overkill, steeper learning curve than Unity
- OpenXR abstraction - native SDKs better for MVP
- Cloud-based dog ML - on-device only for privacy and latency
- Multi-user AR/VR networking - V2 feature
- Dog thought reading (emotional state beyond vocalization) - research phase
- Standalone AR glasses (not Vision Pro/iPad)
- Dog body language analysis (tail wag, ear position)

---

## Traceability

| Phase | Requirements | Stage |
|-------|--------------|-------|
| Phase 38 | AR Foundation, Bark Detection, Basic Overlay | Research Complete |
| Phase 39 | AR Anchoring, Spatial Audio, UX Polish | To Plan |
| Phase 40 | VR Avatar, Hand Tracking, Bubble System | To Plan |
| Phase 41 | VR Environments, Performance, Comfort | To Plan |
| Phase 42 | Cross-Platform Sync, Deployment | To Plan |

---

**Next steps:** Synthesize this research into `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`, then seek milestone approval.
