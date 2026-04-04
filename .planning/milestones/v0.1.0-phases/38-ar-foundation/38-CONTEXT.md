# Phase 38: AR Foundation — Context

**Gathered:** 2026-04-03
**Status:** Ready for planning
**Source:** Research complete via `/gsd:plan-phase 38` (auto-detected existing research)

---

## Domain

AR/VR Mixed Reality — Building WoofTalk for Apple Vision Pro (ARKit + RealityKit).

This is a client-only extension of the existing WoofTalk platform. No new backend infrastructure required. Build a visionOS app that:
- Uses RealityKit for spatial UI
- Detects dog barks via Core ML + Vision framework
- Shows translation bubbles anchored in 3D space
- Integrates with existing Supabase auth and Edge Functions
- Maintains sync with translation history

---

## Phase Boundary

**What this phase delivers:**
- Complete Xcode project for visionOS (Swift 6, RealityKit)
- Dog bark detection component (Core ML model integrated)
- Basic AR translation bubble anchored at fixed position (2m)
- Edge Function API integration with auth
- Spatial audio playback from bubble position
- Verification that all 6 requirements (AR-01 to AR-06) are met

**What happens next (Phase 39):**
- Gaze-based dog position estimation (instead of fixed 2m)
- Bubble placement engine with occlusion checks
- Readability optimization (shadows, contrast)
- Performance tuning to 90 FPS with multiple bubbles
- Advanced UX (pinning, manual placement)

---

## Implementation Decisions

### Platform Stack (from research)
- **Framework**: RealityKit + ARKit (native Apple)
- **Language**: Swift 6, Xcode 16+
- **UI**: SwiftUI overlays (no UIKit)
- **Audio**: AVAudioEnvironmentNode (spatial audio)
- **ML**: Vision framework with custom Core ML model
- **Auth**: Supabase Swift SDK (existing auth flow)
- **API**: Existing Edge Functions (`/v1/translate`)

### Dog Position Strategy
- **Phase 38**: Fixed position at 2m in front of user (world anchor at camera transform + forward * 2)
- **Rationale**: Simplest possible anchoring; avoids body tracking complexity which is unsolved
- **Phase 39**: Upgrade to gaze-based raycast + manual override

### Performance Budget
- Target: 90 FPS (<11ms per frame)
- Bubble effects: Minimal (single textured plane, no real-time shadows)
- Detection: Audio buffer analysis on background queue (20ms windows)

### Success Criteria Interpretation
All criteria must be met for phase completion:
1. **Build success**: No compiler errors, runs on Vision Pro simulator (device optional)
2. **Detection triggers**: At least 3 detections in 5-minute test with sample barks
3. **Bubble appearance**: Within 2 seconds (audio capture → Edge Function → bubble render)
4. **Positioning**: 2m ±0.25m from camera origin, facing camera (billboard)
5. **Readability**: Text legible at 2m distance (equivalent to 24pt at 1m)
6. **Dismissible**: Tap gesture recognized, bubble removed with animation
7. **Audio**: Audible spatial effect (sound pans as user turns head)
8. **Stability**: No memory leaks (detected via Xcode memory gauge), no crashes

---

## Claude's Discretion

Areas not explicitly covered in research/requirements (implementation choices):

1. **Project structure**:
   - Use standard Xcode visionOS app template
   - Separate modules: `BarkDetection`, `TranslationAPI`, `ARExperience`, `SpatialAudio`

2. **Core ML model format**:
   - Use `.mlmodel` compiled from Python (scikit-learn or TensorFlow)
   - Expected input: audio spectrogram (Mel-frequency cepstral coefficients)
   - Expected output: probability distribution over {bark, howl, whine, silence}
   - Training dataset: dog sound datasets from online sources (must be curated)

3. **Audio processing pipeline**:
   - Use `AVAudioEngine` with input node
   - Buffer size: 20ms (1024 samples @ 48kHz)
   - Overlap: 50% for smooth detection
   - Inference on background queue, results dispatch to main

4. **Bubble UI design**:
   - Simple rounded rectangle with slight shadow
   - Background: semi-transparent dark (alpha 0.8)
   - Text: white, dynamic type scaling but minimum 24pt
   - Dismiss: tap anywhere on bubble
   - Auto-dismiss: 10 seconds if no interaction

5. **Error handling**:
   - Auth token expired → show login sheet
   - Edge Function error → toast with "Retry" button
   - Detection unavailable (microphone denied) → show placeholder with instructions

6. **Testing approach**:
   - Unit tests: BarkDetection classification accuracy (with test audio fixtures)
   - Integration tests: Mock Edge Function responses
   - Manual test script provided in VERIFICATION.md

---

## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Project Documentation
- `.planning/REQUIREMENTS.md` — AR-01 through AR-06 requirements (source of truth for coverage)
- `.planning/research/SUMMARY.md` — Executive summary, success criteria, risks
- `.planning/research/ARCHITECTURE.md` — System architecture, data flow
- `.planning/research/STACK.md` — Deep dive on visionOS, RealityKit, Core ML
- `.planning/research/FEATURES.md` — Full M007 feature breakdown
- `.planning/research/PITFALLS.md` — Known pitfalls (dog tracking, performance, privacy)
- `.planning/STATE.md` — Project decisions, previous milestone context

### External Standards
- Existing codebase patterns: `ios/` directory (Swift conventions, error handling, Supabase usage)
- Supabase Swift SDK: `ios/Package.swift` (version, configuration)
- Edge Function API schema: `.supabase/functions/translate/index.ts` (request/response shape)

---

## Specific Ideas

**From research that MUST be honored:**

- Dog bark accuracy target >85% (research says 80-90% realistic)
- 90 FPS performance target on Vision Pro
- Spatial audio anchored to bubble position
- Fixed position 2m for Phase 38 (not dynamic)
- Reuse existing Edge Functions — no new backend
- Platform tracking: add `platform='ar_vision'` to translation_history records
- Spatial position storage: `spatial_position JSONB` column (x,y,z in device space)

---

## Deferred Ideas (Phase 39+)

- Gaze-based anchoring and raycasting
- Occlusion detection (bubble behind walls)
- Dog size estimation (bubble scaling)
- Breed-specific bark profiles
- Multi-user AR networking
- Advanced bubble styling (rich text, animations)
- Voice commands for "pin bubble," "dismiss all"

---

## Notes

- This is a **native visionOS app** — not React Native, not Unity. Pure Swift + RealityKit.
- The AR Foundation phase (38) is intentionally minimal — get a working bubble ASAP.
- Edge Function auth uses existing Supabase session — no new auth flows.
- The app will be a separate target in existing Xcode workspace? Or standalone? Standalone for now, but can integrate later if needed.
- Mobile WoofTalk app (iOS) could theoretically use ARKit too, but Vision Pro has better passthrough and hand tracking. Fallback to iPhone ARKit mentioned in research but out of scope for Phase 38.
