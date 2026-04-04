# Phase 38: AR Foundation — Research

**Researched:** 2026-04-03  
**Confidence:** HIGH  
**Source:** `.planning/research/` (M007 milestone research)

---

## Executive Summary

WoofTalk is expanding into AR on Apple Vision Pro. Phase 38 focuses on the foundation:
- Vision Pro project setup with RealityKit/ARKit
- Core ML dog bark classifier
- Basic translation bubble overlay
- Spatial audio playback
- Edge Function API integration

This is a client-only extension; no new backend infrastructure needed.

---

## Key Technical Decisions

### Platform Stack
- **visionOS**: RealityKit + ARKit for spatial UI
- **Swift 6** with Xcode 16+
- **Core ML**: Custom dog bark classifier (target >85% accuracy)
- **Supabase**: Auth + existing Edge Functions for translation
- **Spatial Audio**: Apple's Spatial Audio API

### Dog Position Strategy
**Problem:** ARKit cannot track dog body position (no dog body tracking).
**Solution:** Use gaze direction + manual placement fallback. For Phase 38, use a fixed position (2m in front) as specified.

---

## Implementation Approach

### 1. Xcode Project Setup
- Create new visionOS app (SwiftUI + RealityKit template)
- Configure entitlements: camera, microphone, motion
- Add Supabase client library (via Swift Package Manager)
- Configure ARKit session for world tracking

### 2. Dog Bark Detection
- Use Vision framework with custom Core ML model
- Train on dog sound datasets (bark, howl, whine classes)
- Real-time audio buffer analysis (20ms windows)
- Confidence threshold: >70% to trigger translation
- Provide UI toggle to enable/disable detection

### 3. Translation Bubble
- RealityKit `Entity` with `ModelComponent` (plane geometry)
- `TextMaterial` from RealityUI or custom shader for crisp text
- Anchor to `ARWorldAnchor` at fixed position (2m in front of user)
- Billboard effect: always face camera
- Auto-dismiss after 10 seconds or user tap

### 4. Edge Function Integration
- Call existing `/v1/translate` Edge Function
- Include user session token from Supabase Auth
- Handle auth errors (redirect to login)
- Show loading indicator while translation processing

### 5. Spatial Audio
- Use `AVAudioEnvironmentNode` for 3D audio positioning
- Anchor sound to bubble's world position
- Play dog bark original + translated speech sequentially

---

## Phase 38 Scope (AR-01 through AR-06)

| Req | Description | Implementation |
|-----|-------------|----------------|
| AR-01 | Vision Pro project setup, RealityKit, ARKit, Xcode | New Xcode project with proper config |
| AR-02 | Core ML dog bark classifier (>85% accuracy) | Train/export model, integrate Vision framework |
| AR-03 | Real-time camera passthrough with ARView | ARKit session management, world tracking |
| AR-04 | Basic translation bubble at fixed world position (2m) | RealityKit entity with anchored position |
| AR-05 | Edge Function API integration (auth, error handling) | Supabase client, session management, error UI |
| AR-06 | Simple spatial audio anchored to bubble | AVAudioEnvironmentNode with position |

---

## Dependencies

- **AR-05** depends on Edge Functions being deployed (Phase 29 already complete ✅)
- **AR-06** depends on AR-04 (bubble position known)

---

## Success Criteria

Functional AR MVP:
- [ ] Xcode project builds and launches on Vision Pro simulator/device
- [ ] Dog bark detection triggers at least 3 times per test session
- [ ] Translation bubble appears within 2 seconds of detection
- [ ] Bubble positioned 2m in front, facing user
- [ ] Translation text readable (minimum 24pt equivalent)
- [ ] Spatial audio audible from bubble direction
- [ ] User can dismiss bubble by tapping it
- [ ] No crashes or memory leaks during 10-minute session

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Dog bark detection accuracy <85% | Lower confidence threshold, rely on user confirmation |
| Vision Pro hardware unavailable | Use Vision Pro simulator; defer device testing |
| Performance <90 FPS | Reduce bubble effects, disable shadows, simplify shader |
| Supabase auth token expired | Auto-refresh token, clear error message if fails |
| ARKit session interruption (phone call) | Pause detection, resume on session restore |

---

## Out of Scope for Phase 38 (Deferred to Phase 39)

- Gaze-based anchoring (will use raycast from camera center)
- Bubble occlusion (check if behind objects)
- Readability optimization (font size, contrast, shadows) — basic only
- Performance tuning beyond baseline 90 FPS
- Dog size estimation
- Multi-user AR (V2)

---

## References

**Must Read:**
- `.planning/research/ARCHITECTURE.md` — System architecture diagrams
- `.planning/research/STACK.md` — Deep dive on visionOS/RealityKit
- `.planning/research/FEATURES.md` — Full feature breakdown for M007
- `.planning/research/PITFALLS.md` — Known pitfalls and mitigations
- `.planning/REQUIREMENTS.md` — Requirement IDs AR-01 through AR-06

**External Documentation:**
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [ARKit Session Management](https://developer.apple.com/documentation/arkit)
- [Vision Framework for Audio Classification](https://developer.apple.com/documentation/vision)

---
