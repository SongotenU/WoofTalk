# Phase 39 Context: AR Spatial UX

## Phase Overview

**Phase:** 39  
**Name:** AR Spatial UX  
**Milestone:** M007 — AR/VR Mixed Reality  
**Goal:** Enhance AR translation bubbles with intelligent spatial placement, improved readability, and interactive user controls

**Requirements:** AR-07, AR-08, AR-09, AR-10, AR-11, AR-12

---

## Current State (Phase 38 Baseline)

Phase 38 delivered:
- Translation bubbles at **fixed 2m position** in front of camera
- Simple billboard effect (Y-axis only)
- Auto-dismiss after 10s, max 3 bubbles FIFO
- Basic tap-to-dismiss
- No gaze-aware positioning
- No environmental awareness
- No performance tuning (90 FPS target unvalidated)
- Readability: fixed 24pt text on semi-transparent dark background

---

## Problem Statement

The Phase 38 implementation, while functional, has significant UX limitations:

1. **Arbitrary positioning:** Bubbles always appear 2m in front, regardless of where the dog actually is. This breaks immersion.
2. **No occlusion:** Bubbles may appear behind walls or objects, making them unreadable or unrealistic.
3. **Static appearance:** No user control over bubble placement or persistence.
4. **Readability unoptimized:** Text may be too small/large depending on distance, no contrast adjustments for bright environments.
5. **Performance unknown:** Multiple bubbles could degrade FPS below 90 target on Vision Pro.
6. **No spatial context:** Bubbles don't respect real-world geometry or user intent.

Phase 39 addresses these by introducing an intelligent bubble placement engine that respects gaze direction, environmental constraints, and user preferences.

---

## Technical Approach

### AR-07: Gaze-Based Dog Position Estimation

**Goal:** Estimate the likely position of a dog relative to the user based on ARKit camera transform and gaze direction.

**Approach:**
- Use `ARView.session.currentFrame?.camera.transform` to get camera pose
- Extract forward vector (column 2 of transform matrix)
- Cast ray from camera along forward vector using `ARView.raycast(from:allowing:alignment:)`
- Raycast hits provide real surface geometry; use first valid hit as "likely dog position"
- If no hit (e.g., open space), estimate position at distance clamp (e.g., 3-8m)
- Incorporate bark sound source localization if available (phase 40+ may add audio-based triangulation)

**Implementation:**
```swift
func estimateDogPosition(from cameraTransform: simd_float4x4, in arView: ARView) -> SIMD3<Float>? {
    let rayOrigin = cameraTransform.translation
    let rayDirection = cameraTransform.forward

    let results = arView.raycast(
        from: rayOrigin,
        allowing: .existingPlaneGeometry,
        alignment: .any
    )

    if let firstHit = results.first {
        return firstHit.worldTransform.translation
    }

    // Fallback: place at clamped distance along gaze
    let distance: Float = 5.0  // avg dog distance
    return rayOrigin + rayDirection * distance
}
```

**Considerations:**
- Raycast may be expensive; cache results or limit frequency (e.g., once per detection)
- User may be looking away from dog; need fallback heuristics (e.g., last known position, sound direction)
- Multiple dogs: need tracking IDs (defer to phase 40+)

---

### AR-08: Bubble Placement Engine

**Goal:** Place bubbles at estimated dog positions with distance clamping, proper billboarding, and occlusion checks.

**Components:**

1. **Placement Strategy:**
   - Primary: Gaze-based raycast result (from AR-07)
   - Fallback: Fixed distance along camera forward (3–8m range)
   - Clamp distance to [1m, 10m] per requirement

2. **Occlusion Checks:**
   - Before placing bubble, raycast from camera to target position
   - If hit distance < distance to bubble → bubble is behind something
   - Options: (a) don't place, (b) place closer (at hit point - 0.5m), or (c) place on near side of occluder
   - Simpler: Only place if unobstructed; otherwise suppress or find alternate position

3. **Billboarding:**
   - Current: `BillboardComponent(mode: .y)` — horizontal rotation only
   - Consider: Full billboard (`.all`) or custom transform update to face camera exactly
   - Cost: Slightly higher CPU but improves readability; acceptable if FPS allows

4. **Lifecycle Management:**
   - Keep max 3 bubbles active (FIFO eviction)
   - Each bubble gets `lifecycleTimer` (10s default, configurable)
   - Pinned bubbles (AR-11) exempt from auto-dismiss

**API Design:**
```swift
actor ARPlacementEngine {
    private let maxDistance: Float = 10.0
    private let minDistance: Float = 1.0

    func placeBubble(
        text: String,
        from cameraTransform: simd_float4x4,
        in arView: ARView
    ) -> SIMD3<Float>? {
        // 1. Estimate position (gaze-based or fallback)
        guard let position = estimatePosition(...) else { return nil }

        // 2. Check occlusion
        guard isPositionVisible(from: cameraTransform, to: position, in: arView) else {
            return nil  // or adjust position
        }

        // 3. Clamp distance
        let clamped = clampDistance(position, from: cameraTransform)

        return clamped
    }
}
```

---

### AR-09: Readability Optimization

**Goal:** Ensure translated text is legible at varying distances and lighting conditions.

**Parameters to tune:**

1. **Dynamic Font Scaling:**
   - Current: fixed font size 0.05 (≈24pt at 2m)
   - Scaling: `fontSize = baseSize * (distance / referenceDistance)`
   - Clamp font size to [12pt, 48pt] range to avoid extremes
   - Or use screen-space size (meters to degrees → pt) for constant angular size

2. **Contrast & Visibility:**
   - Background opacity increase for distant bubbles (e.g., alpha 0.85 → 0.95 beyond 5m)
   - Drop shadow or outline (extrude mesh) to improve contrast against bright backgrounds
   - Background color: dark (0.1, 0.1, 0.1) with slight transparency works in most conditions
   - Consider emissive text (glow) for high ambient light

3. **Bubble Size:**
   - Scale background plane proportionally to text bounds
   - Add padding (e.g., 0.05m margin around text)
   - Auto-size based on text length (short bark vs long translation)

4. **Testing:**
   - Validate readability at 1m, 3m, 5m, 8m, 10m distances
   - Test under bright ARKit lighting (outdoor) and dim (indoor)
   - User A/B testing if possible

**Implementation location:** Extend `TranslationBubble` with `configureForDistance(_:)` method.

---

### AR-10: Performance Tuning

**Goal:** Maintain 90 FPS with 3+ active bubbles on Vision Pro.

**Profiling targets:**
- Frame time budget: 11.11ms per frame (90 FPS)
- Current: AR session ~5-6ms, leaves ~5ms for bubble rendering and inference
- 3 bubbles: each must average <1.5ms to stay within budget

**Optimizations:**

1. **RealityKit Entity Count:**
   - Each bubble = 2 entities (background plane + text mesh)
   - 3 bubbles = 6 entities total (acceptable)
   - Entity creation/destruction expensive → object pool (reuse entities instead of remove+add)
   - Pool size 3-5 (pre-allocate on startup)

2. **Text Mesh Regeneration:**
   - `MeshResource.generateText` is expensive; cache per unique string
   - Cache key: `(text, font, size)` → `MeshResource`
   - Invalidate cache on bubble dismiss; reuse for repeated phrases

3. **Material Reuse:**
   - Shared `UnlitMaterial` instances for background and text (immutable)
   - Don't create new materials per bubble

4. **Gesture Collision:**
   - `installGestures([.tap])` generates collision shapes recursively
   - For planes, collision is simple box; consider custom collision shape for performance
   - Disable gestures on bubbles that auto-dismiss (only needed for pinned)

5. **Billboarding:**
   - `BillboardComponent` is cheap (system-managed)
   - Avoid per-frame manual transform updates if possible

6. **Spatial Audio:**
   - `AVAudioEngine` + `AVAudioEnvironmentNode` runs on separate audio thread
   - Should not impact FPS significantly; profile audio buffer underruns

**Metrics to track:**
- Frame rate (Xcode FPS gauge)
- Render time (Metal debugger)
- Memory allocation (entity count, mesh vertices)
- Battery drain (extended session)

**Fallback:**
If FPS < 80 with 3 bubbles, reduce:
- Max active bubbles from 3 → 2
- Disable drop shadows (AR-09)
- Use simpler font (system font instead of custom)
- Reduce billboarding frequency (every 2-3 frames)

---

### AR-11: User-Controlled Pinning & Manual Placement

**Goal:** Allow users to pin bubbles in place and manually reposition them.

**Interactions:**

1. **Pin/Unpin Toggle:**
   - Default: bubbles auto-dismiss after 10s
   - Pin action: long-press on bubble → pin (stops auto-dismiss timer)
   - Visual indicator: pin icon overlay or border color change
   - Unpin: another long-press or separate UI control

2. **Manual Placement Gesture:**
   - **Drag:** Touch-and-drag bubble to new location (world anchor moves with user's finger raycast)
   - **Rotate:** Two-finger rotation to adjust orientation (if billboarding disabled)
   - **Scale:** Pinch to adjust size (optional)

3. **Selection & Focus:**
   - Tap selects bubble (highlight border)
   - Selected bubble shows UI affordance (pin button, delete button)
   - Voice command integration: "Pin this" (future)

4. **Persistence:**
   - Pinned bubbles persist until explicitly dismissed
   - State stored in `ARCoordinator` with `isPinned` flag per bubble
   - Eviction policy: only auto-dismiss unpinned bubbles

**Implementation complexity:** Medium-high. Requires gesture recognition on RealityKit entities (custom `Entity` subclass with `CollisionComponent` and hit-testing).

**Trade-off:** Manual placement may conflict with AR-08 automatic placement. Need UX decision: either automatic OR manual, or hybrid (auto-place then allow user to reposition).

**Recommendation:** Start with pin-only (AR-11a), defer manual drag to later iteration or next phase.

---

### AR-12: Environmental Awareness

**Goal:** Prevent bubbles from appearing inside solid geometry (walls, furniture).

**Approach:**

1. **Raycast Occlusion Check:**
   - From camera to target position, raycast with `.existingPlaneGeometry`
   - If raycast `distance` < `distanceToTarget`, then target is behind occluder
   - Response: choose a position on near side of occluder (hit point + small epsilon)

2. **Alternative: Depth Buffer:**
   - Use `ARView.sceneDepth` (visionOS provides depth map)
   - Query depth at bubble's projected screen position
   - If bubble depth > scene depth, bubble is behind something → move forward to surface

3. **Heuristic:**
   - Prefer placing bubbles in open space (no hit within 0.5m of target)
   - If occluded, retry with slightly different ray direction (jitter ±5°)
   - After N attempts, place anyway with warning visual (dimmed, translucent)

4. **Real-time Update:**
   - As user moves, bubbles may become occluded
   - Option: shift bubble to maintain line-of-sight (expensive)
   - Simpler: leave as-is; occlusion detection only at placement time

**Performance:** Raycast per bubble placement is fine (not per-frame). ~1-2ms per raycast acceptable.

---

## Implementation Plan Structure

Given 6 requirements, suggest **3 execution plans**:

### Plan 39-01: Gaze-Based Placement Engine
- AR-07 (gaze estimation) + AR-08 core (placement logic)
- New: `ARPlacementEngine` actor
- Modify `ARCoordinator` to use placement engine instead of fixed 2m

### Plan 39-02: Readability & Performance
- AR-09 (readability optimization)
- AR-10 (performance tuning)
- Enhance `TranslationBubble` with dynamic font sizing, contrast adjustments
- Profiling and optimization pass; introduce entity pooling if needed

### Plan 39-03: User Controls & Environmental Awareness
- AR-11 (pinning + manual placement)
- AR-12 (occlusion avoidance)
- Gesture handling for pinning
- Occlusion raycast integration
- UI affordances (pin icon, selection)

**Wave 1:** Placement logic (independent of rendering)  
**Wave 2:** Rendering enhancements (bubble appearance)  
**Wave 3:** Interaction & environment (user control + occlusion)

---

## Dependencies

- **Phase 38 complete:** ARCoordinator, TranslationBubble, ARView setup
- **No external research required** (ARKit APIs are known)
- **Potential new Swift packages:** None expected
- **ML model:** unchanged (Phase 38 model sufficient for testing)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gaze raycast performance cost | FPS drop if called per-detection | Cache results, limit to 1-2 Hz, reuse across multiple bubbles |
| Manual placement gesture complexity | Large implementation effort | Defer to later; implement pin-only first |
| Readability tuning subjective | Hard to determine "optimal" | Use heuristics (distance→font), user testing later |
| FPS target not achievable on hardware | Phase fails verification | Early profiling (Wave 2); have fallbacks ready |
| Occlusion raycast misses some geometry | Bubbles still inside walls | Use multiple raycast checks, depth buffer fallback |

---

## Traceability

| Requirement | Plan | Verification Approach |
|-------------|------|----------------------|
| AR-07 | 39-01 | Gaze raycast visible in code; bubble appears along gaze direction |
| AR-08 | 39-01 | Clamp distance 1-10m; bubble respects occlusions |
| AR-09 | 39-02 | Font scales with distance; contrast adjustable; user test |
| AR-10 | 39-02 | FPS ≥ 90 with 3 bubbles (profiler validation) |
| AR-11 | 39-03 | Pin gesture works; pinned bubbles persist past auto-dismiss |
| AR-12 | 39-03 | No bubbles inside walls (occlusion check verified in test scene) |

---

## Success Criteria

**Phase-level:**
- All 6 AR-07..AR-12 requirements satisfied
- FPS ≥ 90 with 3 active bubbles (measured on Vision Pro simulator/device)
- User can pin at least 1 bubble and it persists
- Bubbles respect environmental occlusion (no bubble-in-wall)
- Readability validated at distances 1m-10m

**Exit:**

Phase 39 complete when:
- 3 plans executed, 3 summaries written
- All acceptance criteria in PLAN files met
- Verification audit passes (`gsd-verifier` agent)
- ROADMAP.md updated, Phase 39 marked ✅

---

## Next Phase Preview

Phase 40 (VR Foundation) will port these AR concepts to Unity/Meta Quest:
- Dog avatar instead of just bubbles
- Hand tracking (OVRHand) for user interaction
- TensorFlow Lite for bark detection
- Oculus Spatializer for audio

Phase 39's placement engine and readability work will inform VR UX design.

---

**Phase author:** Claude Code (2026-04-03)  
**Review needed:** User confirmation of technical approach (raycast vs. alternatives, manual placement scope)
