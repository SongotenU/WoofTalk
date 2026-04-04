---
phase: 40
phase_slug: vr-foundation
date: "2026-04-03"
---

# Phase 40: VR Foundation - Validation Strategy

## Wave Coverage

| Wave | Plan | Validation Method | Automated |
|------|------|-------------------|-----------|
| Wave 1 | 40-01 | Android build attempt + DogAvatarTests | Partial |
| Wave 2 | 40-02 | BubbleManagerTests + billboard verification | Yes |
| Wave 3 | 40-03 | BarkDetectorTests + manual spatial audio check | Partial |

## Validation Dimensions

### Dimension 1: Build Validation (VR-01)
- Unity project opens without errors
- Android build target configured (API 33+)
- Meta XR SDK packages installable
- AndroidManifest.xml contains RECORD_AUDIO, hand tracking features
- Quest deployment produces valid APK

### Dimension 2: Avatar Validation (VR-02)
- DogAvatar prefab spawns at correct position
- Animator has 3 states: idle, bark, head-turn
- DogAvatarController triggers bark animation on command
- Idle animation plays by default

### Dimension 3: Hand Tracking Validation (VR-03)
- OVRHand component initializes
- PinchDetect detects pinch gesture at 0.02f threshold
- VRMenuButton responds to pinch input
- Fallback to controller input when hand tracking unavailable

### Dimension 4: Bubble UI Validation (VR-04)
- TranslationBubble spawns at 0.5m offset above avatar
- TextMeshPro text readable at 24pt+ font size
- BillboardVR keeps bubble facing camera via LateUpdate LookAt
- Auto-dismiss timer removes bubble after configured seconds
- Bubble pool maintains max 5 active bubbles

### Dimension 5: Bark Detection Validation (VR-05)
- BarkDetector captures audio via OnAudioFilterRead
- BarkClassifier returns classification within 500ms
- Confidence threshold 70% correctly filters false positives
- Debounce of 1s prevents spam triggers
- Mock fallback works when TFLite model not loaded

### Dimension 6: Spatial Audio Validation (VR-06)
- AudioSource spatialBlend set to 1.0f
- Oculus Spatializer configured in AudioManager.asset
- Audio plays from bubble position, not center
- AudioListener on OVRCameraRig centerEyeAnchor
- Latency <50ms from bubble spawn to audio start

## Validation Methods

### Editor Tests (Automated)
- Unity Test Framework (com.unity.test-framework) built into Unity 2022 LTS
- Run via Unity Test Runner window > Run All
- Tests cover: DogAvatarTests, BubbleManagerTests, BarkDetectorTests, BuildValidation

### Play Mode Tests (Automated + Editor)
- Bubble spawn/dismiss lifecycle
- Billboard positioning accuracy
- Bark detection debounce timing

### Manual Testing (Requires Quest Device)
- Hand tracking initialization and pinch detection
- Spatial audio 3D positioning verification
- FPS performance measurement (target: 72 FPS Quest 2, 90 FPS Quest 3)
- Microphone permission prompts and audio capture

## Acceptance Criteria

Phase 40 is complete when:
1. Unity project builds Android APK for Quest 2/3
2. DogAvatar prefab spawns with idle animation
3. Translation bubbles appear and auto-dismiss
4. Billboard script keeps bubbles facing camera
5. Bark detection triggers bubble (with simulated audio if TFLite unavailable)
6. Spatial audio configured for bubble positions
7. Hand tracking or controller fallback functional
