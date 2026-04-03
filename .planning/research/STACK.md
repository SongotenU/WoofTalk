# Technology Stack — AR/VR Addendum

**Project:** WoofTalk
**Scope:** AR and VR translation features (M007)
**Researched:** 2026-04-03
**Extends:** Existing stacks from v3.0/v3.1 (Android, iOS, Web) and v4.0 (API Gateway)

---

## Executive Summary

This document covers AR/VR technology additions for M007. WoofTalk currently spans iOS, Android, Web, and Watch. M007 adds **two new frontend platforms**: AR (primarily Apple Vision Pro / ARKit) and VR (Meta Quest). Both will reuse the existing translation engine and Supabase backend but require new UI paradigms (3D spatial interfaces, immersive audio, mixed reality pass-through).

Guiding principle: **Leverage platform-native AR/VR SDKs first**. Don't try to build cross-platform AR/VR abstraction (Unity/Unreal) unless justified by massive code reuse. Given the unique nature of AR vs VR and the small scope (translation overlay + dog sound detection), native development on each platform is simpler than a unified engine.

---

## Recommended Stack Additions

### 1. Augmented Reality (ARKit on Vision Pro / iOS)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **ARKit** | iOS 18+ | Core AR tracking (plane detection, object anchoring, People Occlusion) | Apple's native framework, best Vision Pro integration, no cost |
| **RealityKit** | iOS 18+ | 3D rendering and spatial UI | Higher-level than SceneKit, better performance, Vision Pro optimized |
| **SwiftUI + 3D** | iOS 18+ | UI overlay on AR content | Existing WoofTalk iOS stack already uses SwiftUI |
| **Vision framework** | iOS 18+ | Dog bark detection via on-device ML | Apple's ML stack, privacy-preserving (on-device) |
| **Spatial Audio API** | iOS 18+ | 3D-positioned audio feedback | Native to Vision Pro, works with RealityKit |
| **RoomPlan (optional)** | iOS 18+ | Room scanning for persistent AR placement | Advanced - may defer to V2 |

**Why NOT cross-platform (Unity/Unreal for AR):**
- WoofTalk's AR use case is relatively simple (text overlays, minimal 3D)
- SwiftUI + RealityKit integrates seamlessly with existing iOS codebase
- Vision Pro market share still small; Unity adds unnecessary complexity
- Apple's ARKit is best-in-class for Vision Pro; cross-platform tools lag behind

**Target device:** Apple Vision Pro (primary), iPadOS with LiDAR (secondary)

---

### 2. Virtual Reality (Meta Quest)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Meta XR SDK (Unity)** | 63.x | VR development framework for Quest | Official Meta SDK, mature ecosystem, best Quest integration |
| **Unity 2022 LTS** | 2022.3+ | Rendering engine and physics | Most accessible VR dev platform, large asset store |
| **Oculus Integration** | Unity package | Device-specific features (hand tracking, passthrough) | Required for Quest hardware integration |
| **SteamVR (optional)** | -- | PC VR support (Valve Index, etc.) | If choosing to support PC VR beyond Quest |
| **Spatial Audio SDK** | Meta Spatializer | 3D audio in virtual environments | Integrates with Unity's audio system |

**Why Unity for VR but NOT for AR:**
- Unity's AR Foundation supports multiple AR platforms (ARKit, ARCore) but lacks Vision Pro polish
- VR development is significantly more complex (full 3D scenes, locomotion, performance critical)
- Unity's asset ecosystem valuable for VR (pre-made environments, shaders, interactions)
- Meta Quest dominates VR market; Unity is their recommended platform
- Development velocity: Unity's editor and rapid iteration crucial for immersive UX

**Target device:** Meta Quest 3 (primary), Quest 2 (backward compatible)

---

### 3. Audio Processing (Both AR & VR)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Dog bark classifier model** | Custom Core ML / ONNX | Detect and classify dog vocalizations | Needs custom training on dog sound datasets |
| **AudioKit (iOS/visionOS)** | 5.x | Audio capture, preprocessing, playback | Well-maintained audio framework for Apple platforms |
| **FFmpeg / libsndfile** | -- (Unity asset) | Audio format conversion, waveform analysis | For VR/Unity pipeline |
| **On-device ML** | Core ML (Apple), TensorFlow Lite (Quest) | Real-time bark detection without cloud latency | Privacy + offline operation required |

**Dog sound dataset sources:**
-公开数据集: AudioSet (Google), ESC-50
- Commercial: Dog sound effect libraries
-自建: Record from WoofTalk user base (with consent)

**Model architecture:**
- CNN on mel-spectrograms (proven for animal sound classification)
- Lightweight (<10MB) for on-device inference (<100ms latency)
- Breed-specific fine-tuning (optional phase 40)

---

### 4. Backend Integration (Existing)

| Technology | Existing | Changes for AR/VR |
|------------|----------|------------------|
| **Supabase PostgreSQL** | ✓ | No changes - translation history, user data, phrases |
| **Supabase Edge Functions** | ✓ (6 functions) | Add new endpoints for AR/VR-specific data (3D models, spatial positions) |
| **Supabase Auth** | ✓ | Same OAuth flow, device registration for AR/VR platforms |
| **Realtime subscriptions** | ✓ | Push notifications for shared AR/VR experiences (optional) |
| **Storage (dog avatar 3D models)** | ✓ | Use Supabase Storage for user-uploaded dog models, textures |

---

## Platform-Specific Notes

### Apple Vision Pro (ARKit)

- **Development environment:** Xcode 16+, Swift 6, RealityKit 5
- **UI paradigm:** Spatial computing - UI elements exist in 3D space, anchored to world
- **Input:** Hand tracking (Vision Pro), eye tracking, voice (SiriKit integration)
- **Performance target:** 90 FPS for smooth AR (Vision Pro native refresh rate)
- **Distribution:** VisionOS App Store (separate from iOS App Store, but shared binary possible)
- **Testing:** Xcode Simulator with Vision Pro virtual device

**Key ARKit APIs:**
- `ARView` - main AR container
- `AnchorEntity` - fix translation bubbles to dog position (requires dog tracking, see Pitfalls)
- `Text` / `ModelEntity` - render translation bubbles
- `SpatialTrackingProvider` - track hand gestures for interaction
- `SceneReconstruction` - understand room geometry

**Initial scope limitation:** Without robust dog body tracking, will anchor to user's gaze or manual placement.

---

### Meta Quest (Unity + Meta XR SDK)

- **Development environment:** Unity 2022.3+, Meta XR SDK, Android SDK
- **UI paradigm:** Immersive 3D with hand tracking or controller input
- **Input:** Touch controllers (default), hand tracking (Quest Pro/3)
- **Performance target:** 72/90 FPS depending on Quest model
- **Distribution:** Meta Quest Store (side-loading for development)
- **Testing:** Meta Quest Developer Hub (MQDH), Link cable for PC testing

**Key Unity/Meta APIs:**
- `OVRCameraRig` - camera and tracking
- `OVRHand` - hand tracking
- `OVRAnchor` - persistent world anchors (store translation positions)
- `OculusSpatializer` - spatial audio

**Initial scope limitation:** Start with seated/room-scale VR without complex locomotion.

---

## What NOT to Add

- **No ARCore (Android AR)** - Market fragmentation, low ARCore device penetration vs Vision Pro focus
- **No OpenXR abstraction** - Simplicity over cross-platform; native SDKs are better for this MVP
- **No Unreal Engine** - Overkill for simple translation overlays, steeper learning curve than Unity
- **No custom 3D engine** - Rendering is solved problem; use RealityKit/Unity
- **No cloud-based inference** - On-device ML only for privacy and latency
