# Phase 39-01 Summary: Gaze-Based Placement Engine

**Date:** 2026-04-03  
**Status:** ✅ COMPLETE  
**Wave:** 1

---

## Overview

Implemented intelligent bubble positioning using gaze-based raycasting. Replaced Phase 38's fixed 2m offset with a dynamic placement engine that estimates dog position along the user's gaze direction, respects distance clamping (1-10m), and checks for occlusions.

## Files Created/Modified

| File | Status | Lines | Purpose |
|------|--------|-------|---------|
| `WoofTalkAR/Services/ARPlacementEngine.swift` | ✅ Created | 243 | Gaze-based placement with raycast, clamping, occlusion |
| `WoofTalkAR/ARCoordinator.swift` | ✅ Updated | +30 | Integrated placement engine, added fallback handling |
| `WoofTalkAR/Views/TranslationBubble.swift` | ✅ Updated | +100 | Added `configureForDistance`, text mesh caching |

**Total:** ~373 lines new/modified

---

## Key Implementation Details

### ARPlacementEngine

Singleton `actor` providing placement pipeline:

- `placeBubble(text:from:in:)` — main entry point
  - Calls `estimateDogPosition` (raycast along camera forward)
  - Checks `isPositionVisible` for occlusion
  - Clamps distance to [1m, 10m]
  - Returns `PlacementResult` with position, distance, usedFallback flag

- `estimateDogPosition` — raycast query:
  ```swift
  let raycastQuery = ARRaycastQuery(
      origin: cameraPos,
      direction: forward,
      allowing: .estimatedPlane,
      alignment: .any
  )
  ```
  - Uses `.estimatedPlane` to hit any detected surface
  - Fallback: if no hit, returns position at random 4-6m along gaze

- `isPositionVisible` — occlusion check:
  - Raycast from camera to target position
  - If any hit occurs before target (within 10cm), returns false
  - Prevents bubbles appearing behind walls

- `clampDistance` — enforces min/max bounds:
  - Clamps to 1.0-10.0m range
  - Preserves direction, adjusts magnitude

- SIMD extensions on `simd_float4x4` for convenient access:
  - `translation` (column 3)
  - `forward` (negative column 2, normalized)

### ARCoordinator Integration

- `showBubble` now uses `ARPlacementEngine.shared.placeBubble`
- If placement succeeds: sets bubble position and calls `configureForDistance(distance)`
- If placement fails (nil or occluded): falls back to legacy 2m offset
- Logs fallback usage for debugging

### TranslationBubble Enhancements

- `configureForDistance(_:)`: adjusts background opacity based on distance
  - Near (≤3m): opacity 0.85
  - Far (>3m): opacity 0.95
- Static text mesh cache (`NSCache<NSString, MeshResource>`)
  - Cache key: `"\(text)_\(fontSize)"`
  - Reduces `MeshResource.generateText` allocations
- `generateOrCacheText` method for cached text generation

---

## Verification Checklist

✅ **ARPlacementEngine**:
- Compiles as actor singleton
- Raycast uses camera forward vector correctly
- Fallback activates when raycast returns empty
- Distance clamping enforces 1-10m bounds
- Occlusion check returns false when geometry blocks line-of-sight
- `PlacementResult` struct provides position, distance, usedFallback

✅ **ARCoordinator**:
- Imports ARPlacementEngine
- Calls `placeBubble` in `showBubble`
- Fallback to legacy 2m positioning when placement returns nil
- Calls `bubble.configureForDistance(distance)`

✅ **TranslationBubble**:
- `configureForDistance` updates background material opacity
- Text mesh cache reduces regenerate calls
- Cache key combines text and font size

---

## Dependencies

- **38-03:** Existing bubble system (TranslationBubble, ARCoordinator)
- No new Swift packages
- Uses RealityKit ARKit APIs (already present)

---

## Acceptance Criteria

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Gaze-based positioning via raycast | ✅ | ARPlacementEngine.estimateDogPosition uses ARRaycastQuery |
| Distance clamped 1-10m | ✅ | clampDistance enforces min/max |
| Occlusion checks | ✅ | isPositionVisible raycasts to target, rejects blocked |
| Fallback positioning | ✅ | Returns random 4-6m if raycast fails |
| ARCoordinator integration | ✅ | showBubble calls placement engine |
| TranslationBubble accepts dynamic position | ✅ | entity.position set after placement |

---

## Performance Considerations

- Raycast per bubble placement (not per-frame) — acceptable cost (~1-2ms)
- Text mesh caching avoids repeated `generateText` allocations
- Placement engine is actor-isolated (thread-safe)

---

## Next Steps

- **39-02:** Readability optimizations (dynamic font scaling) and FPS profiling
- **39-03:** User interactions (pinning, manual placement), occlusion refinement

---

**Phase:** 39-ar-spatial-ux  
**Plan:** 39-01 (Gaze-Based Placement Engine)  
**Requirements:** AR-07, AR-08  
**Status:** ✅ COMPLETE
