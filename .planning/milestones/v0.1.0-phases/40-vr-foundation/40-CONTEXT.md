# Phase 40 Context: VR Foundation

## Phase Overview

**Phase:** 40  
**Name:** VR Foundation  
**Milestone:** M007 — AR/VR Mixed Reality  
**Goal:** Establish Unity project for Meta Quest with dog avatar, hand tracking, translation bubbles, and bark detection

**Requirements:** VR-01, VR-02, VR-03, VR-04, VR-05, VR-06

---

## Current State

Phase 38-39 delivered AR Foundation on Apple Vision Pro (visionOS + RealityKit + Swift). Phase 40 shifts platforms entirely:

- **Target platform:** Meta Quest 2/Quest 3 (Android-based VR headset)
- **Engine:** Unity 2022 LTS
- **SDK:** Meta XR SDK (formerly Oculus Integration)
- **Primary language:** C# (instead of Swift)
- **3D rendering:** Unity's built-in renderer (URP or built-in RP)

This is a **greenfield** implementation — no shared code with visionOS AR implementation. Common concepts (bubble UI, detection pipeline) will be reimplemented using Unity/XR APIs.

---

## Problem Statement

Users need the same core WoofTalk functionality in VR:
- Dog bark detection (same ML model, but TensorFlow Lite for Unity)
- Translation bubbles showing dog speech in 3D space
- Spatial audio from bubble positions
- Hand tracking for UI interaction (pinching, pointing)
- Dog avatar representing the "speaking dog"

Phase 40 builds the foundation: a functional VR prototype that demonstrates these core interactions on Quest hardware.

---

## Technical Approach

### VR-01: Unity Project Setup

**Tasks:**
- Create Unity 2022 LTS project (3D template)
- Install Meta XR SDK via Package Manager (or Unity Asset Store)
- Configure XR plugin: Oculus
- Set build target: Android (Quest)
- Configure Android SDK/NDK paths, JDK
- Set up project structure:
  - `Assets/Scripts/` — C# code
  - `Assets/Prefabs/` — reusable GameObjects (bubble prefab, avatar)
  - `Assets/Models/` — FBX dog avatar
  - `Assets/Audio/` — spatial audio clips
  - `Assets/Plugins/` — native libs (TensorFlow Lite)
- Basic scene: OVRCameraRig prefab with tracking origin

**Key configurations:**
- Target API level: Android 33+ (Quest requirement)
- Minimum SDK: Android 23 (or as per Meta guidelines)
- App ID: set in Oculus Developer Dashboard
- Permissions: microphone (for live bark detection — optional for Phase 40)

### VR-02: Dog Avatar

**3D Model Requirements:**
- FBX format with rigging (humanoid or custom)
- Animations (can be placeholder for Phase 40):
  - Idle (breathing subtle movement)
  - Bark (mouth open, head forward)
  - Head-turn (look left/right)
- Import settings: scale, read/write enabled, optimize for performance
- Create `DogAvatar` prefab with:
  - Animator component + Animator Controller
  - SkinnedMeshRenderer
  - Optional: colliders for interaction

**Avatar behavior:**
- Spawn in scene at a reasonable distance (2-3m from player)
- Rotate to face camera on spawn
- Trigger bark animation when translation occurs
- Could be voice-activated: microphone hears bark → avatar animates

**Fallback:** If no model available, use simple geometric shape (capsule/box) labeled "Dog"

### VR-03: Hand Tracking Integration

**OVRHand Component:**
- Add `OVRCameraRig` prefab (includes hand anchors)
- Enable hand tracking in OVR Manager:
  - Tracking: Hands (no controllers)
  - Hand tracking: true
- Use `OVRHand` components to get hand poses
- Hand presence: visualize hands with simple sphere/capsule proxies or custom hand models

**Menu Navigation:**
- Create UI Canvas in world space (at comfortable height)
- Buttons for: toggle detection, toggle avatar, settings
- Ray interaction from index finger tip → Button onClick
- Alternatively: gaze-based selection (look at button for 2s)

**Gaze-based triggers:**
- Use `OVREyeGaze` or hand pointer for pointing
- Detect when user "points" at bubble for pinning (similar to AR long-press but via pinch)

**Implementation notes:**
- Hand tracking adds CPU overhead; target 72/90 FPS may require reducing other effects
- Hand presence not required for MVP — can use controller buttons instead

### VR-04: Translation Bubble System

**TextMeshPro in World Space:**
- Create `VRTranslationBubble` prefab:
  - Canvas (World Space) with TextMeshPro text component
  - Background Panel (UIImage or SpriteRenderer) for readability
  - Billboard script to face camera (or face user's head)
  - Auto-dismiss after N seconds (configurable)
- Positioning: at dog avatar position + slight offset (0.5m Y up)
- Multiple bubbles: pool of 3-5, FIFO eviction
- Tap/dismiss: raycast from hand pointer to bubble → remove

**Key differences from AR (RealityKit):**
- Unity uses GameObject/Component instead of Entity/Component
- TextMeshPro provides superior text rendering (vs MeshResource.generateText)
- Billboard via script: `transform.LookAt(camera.transform)`
- Gestures via physics raycast + colliders

**Pipeline integration:**
- BarkDetector (VR-05) triggers → spawn bubble at avatar position
- Show translation text, auto-dismiss timer
- Optional: pin via hand pinch gesture

### VR-05: Bark Detection (TensorFlow Lite)

**Model port:**
- Convert existing Core ML model to TensorFlow Lite (.tflite)
- Use Unity's Barracuda or TensorFlow Lite plugin
- Model input: 1024-sample Float32 audio buffer (same as AR)
- Model output: class probabilities (bark, howl, whine, silence)
- Confidence threshold: >70%

**Audio capture:**
- Unity `Microphone` API: record from device mic
- Buffer size: 1024 samples
- Sample rate: 48,000 Hz (match model training)
- Streaming: continuously capture, feed to model inference

**Inference pipeline:**
1. Audio capture → PCM buffer
2. Convert to TensorFlow Lite input tensor (1×1024 float)
3. Run interpreter
4. Get output probabilities
5. Apply threshold → classify
6. Debounce (1s) to prevent spam

**Integration:** Output classification triggers `VRBubbleManager.showBubble(translationText)`

**Note:** Microphone permission required in Android manifest; Quest supports mic

### VR-06: Spatial Audio

**Oculus Spatializer:**
- Install Meta XR Audio SDK (includes spatializer plugin)
- Configure audio source on bubble prefab:
  - `AudioSource` component
  - Spatializer plugin: OculusSpati...
  - Attenuation: distance-based rolloff
  - Direction: 3D sound
- Play translation audio (TTS or pre-recorded) from bubble position
- Listener: attached to player's head (OVRCameraRig)

**Audio sources:**
- Option A: Text-to-Speech (TTS) via Unity `SpeechSynthesizer` (system) or cloud API
- Option B: Pre-recorded bark/translation audio clips (simpler for Phase 40)
- Option C: Generate simple tone placeholder (like AR)

**Latency target:** <50ms from bubble spawn to audio start

---

## Implementation Plan Structure

**Suggested 3 plans:**

### Plan 40-01: Unity Project & Dog Avatar
- VR-01 (Unity setup, Meta SDK)
- VR-02 (Dog avatar FBX import, animations, prefab)

### Plan 40-02: Bubbles & Hand Tracking
- VR-04 (TextMeshPro bubble system, billboard, auto-dismiss)
- VR-03 (OVR hand tracking, basic menu, pointer interaction)

### Plan 40-03: Bark Detection & Spatial Audio
- VR-05 (TensorFlow Lite integration, audio capture)
- VR-06 (Oculus Spatializer, audio playback)

**Wave 1:** Project scaffolding + avatar  
**Wave 2:** Core user-facing UI (bubbles + hands)  
**Wave 3:** Core functionality (detection + audio)

---

## Dependencies

- **Phase 38-39:** AR Foundation provides requirements and reference architecture (but not code reuse)
- **No shared codebase:** Swift vs C#, visionOS vs Unity — separate project entirely
- **Model training:** Need to convert Core ML → TensorFlow Lite (use `onnx` or `tf2tflite`)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Unity/Android build toolchain complexity | Setup may take hours | Document exact versions; use Meta's OVN (Oculus Version) templates |
| TensorFlow Lite conversion fails | Detection breaks | Export to ONNX first, then use `tf2tflite`; validate with test data |
| Hand tracking FPS cost | Lower frame rate | Allow fallback to controller input; optimize hand visuals |
| Audio capture permissions | Mic blocked | Test on device; use simulated audio for early testing |
| FBX model not ready | Avatar missing | Use placeholder capsule with "Dog" label |

---

## Success Criteria

**Phase-level:**
- Unity project builds and runs on Quest (or simulator)
- Dog avatar present in scene with basic animations
- Hand tracking recognized (or controller pointer works)
- Translation bubbles appear and auto-dismiss
- Bark detection triggers bubble (with test audio file)
- Spatial audio plays from bubble location

All 6 VR-01..VR-06 requirements satisfied.

---

## Next Phase Preview

Phase 41 (VR Environments & Polish) will:
- Add multiple virtual scenes (park, living room, beach)
- Avatar customization (breed, color, accessories)
- Performance optimization for Quest 2/Quest 3
- Motion sickness mitigation (comfort mode, head-locked UI)
- Settings UI (volume, bubble opacity, comfort toggles)

Phase 40 provides the foundation to polish.

---

**Phase author:** Claude Code (2026-04-03)
