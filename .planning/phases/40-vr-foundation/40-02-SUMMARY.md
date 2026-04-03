---
phase: 40-vr-foundation
plan: 02
type: execute
wave: 2
subsystem: vr-quest
tags:
  - vr
  - unity
  - ui
  - hand-tracking
  - textmeshpro
dependency_graph:
  requires:
    - phase40-01-dogavatar-prefab
    - phase40-01-experience-scene
  provides:
    - VR-03: Hand tracking with VR menu
    - VR-04: Translation bubble system
  affects:
    - phase40-03: Bark-to-bubble wiring
tech_stack:
  added:
    - name: TextMeshPro
      version: Unity integrated
      purpose: World-space 3D text rendering for translation bubbles
    - name: Meta XR SDK (OVRHand)
      version: Unity integrated
      purpose: Hand tracking pinch detection via GetFingerIsPinching()
    - name: Unity.UI
      version: Built-in
      purpose: VR menu button interactions
  patterns:
    - object-pooling
    - billboard-facing
    - edge-detection
key_files:
  created:
    - vr-quest/Assets/Scripts/UI/BillboardVR.cs
    - vr-quest/Assets/Scripts/UI/TranslationBubble.cs
    - vr-quest/Assets/Scripts/UI/BubbleManager.cs
    - vr-quest/Assets/Scripts/UI/PinchDetect.cs
    - vr-quest/Assets/Scripts/UI/VRMenuButton.cs
    - vr-quest/Assets/Scripts/UI/VRMenu.cs
    - vr-quest/Assets/Prefabs/TranslationBubble.prefab
    - vr-quest/Assets/Prefabs/VRMenu.prefab
    - vr-quest/Assets/Tests/PlayMode/BubbleManagerTests.cs
  modified:
    - vr-quest/Assets/Scenes/Experience.unity
decisions:
  - decision: Pool size set to 5 bubbles
    rationale: "Balances memory usage with concurrent bubble display. Research showed 3-5 range, chose upper end for comfort."
  - decision: LateUpdate used for BillboardVR (not Update)
    rationale: "Research Pattern 2 warned of one-frame jitter when billboard updates before camera tracking."
  - decision: Auto-dismiss timeout at 5 seconds
    rationale: "Research Pattern 4 showed 3s too fast, 10s too slow. 5s default gives user time to read most translations."
  - decision: Activation distance at 2cm (0.02f)
    rationale: "Close enough to prevent accidental triggers while in VR, far enough to feel responsive."
  - decision: Pinch threshold at 0.8f confidence
    rationale: "High confidence prevents false positives from OVRHand finger tracking noise."
  - decision: BillboardVR.Added SetCameraTarget(public void) instead of reflection
    rationale: "Deviation from plan -- initially used reflection to set private serialized field. Changed to public method for cleaner code."
  - decision: VRMenu starts hidden (SetActive false in Awake)
    rationale: "Per plan spec -- menu should be toggle-visible, not always-on."
metrics:
  duration: "<15 min"
  completed_date: "2026-04-03"
  tasks_completed: 2
  tasks_total: 2
  files_created: 8
  files_modified: 1
  tests_written: 5
  commit_1: 88410f3
  commit_2: ab1ad0a

---

# Phase 40 Plan 02: Translation Bubbles & Hand Tracking Summary

**One-liner:** Translation bubble system with TextMeshPro world-space UI, camera billboard, 5-bubble object pool, and OVRHand-based pinch detection for VR menu button interaction with 3-button layout (Toggle Detection, Toggle Avatar, Settings stub).

## Files Created

| File | Purpose |
|------|---------|
| `BillboardVR.cs` | Y-axis constrained camera-facing rotation (LateUpdate) |
| `TranslationBubble.cs` | Per-bubble text, background, auto-dismiss + pool return events |
| `BubbleManager.cs` | Queue-based object pool (poolSize=5), ShowBubble, FIFO eviction, DismissAfter coroutine |
| `PinchDetect.cs` | OVRHand.GetFingerIsPinching() edge detection with OnPinchStarted/OnPinchReleased events |
| `VRMenuButton.cs` | Distance (2cm) + pinch activation, scale visual feedback at 0.95f |
| `VRMenu.cs` | ToggleVisibility/Show/Hide, 3 stub callbacks for detection, avatar, settings |
| `TranslationBubble.prefab` | WorldSpace Canvas (480x180, scale 0.002), TMP_Text fontSize 28, dark bg rgba(30,30,30,230), X dismiss button |
| `VRMenu.prefab` | WorldSpace VerticalLayout Canvas (400x300), 3 buttons with VRMenuButton + TMP labels, dark panel |
| `BubbleManagerTests.cs` | 5 PlayMode tests: spawn position, billboard assignment, text content, dismiss/pool return, FIFO eviction |

## Files Modified

| File | Changes |
|------|---------|
| `Experience.unity` | Added BubbleManager at origin, VRMenu at (0,1.5,-1), PinchDetectRight on RightHandAnchor |

## Verification Results

**VR-04 (Translation Bubble System):**
- BillboardVR.cs: LateUpdate ✓, LookAt ✓
- TranslationBubble.cs: SetText ✓, TMP_Text ✓
- BubbleManager.cs: Queue ✓, poolSize=5 ✓, ShowBubble ✓, Enqueue ✓
- TranslationBubble.prefab: fontSize ✓, WorldSpace Canvas ✓, dark background ✓
- BubbleManagerTests.cs: 5 test attributes ✓

**VR-03 (Hand Tracking Integration):**
- PinchDetect.cs: GetFingerIsPinching ✓, OnPinchStarted ✓
- VRMenuButton.cs: activationDistance ✓, Vector3.Distance ✓
- VRMenu.cs: ToggleVisibility ✓, menuPanel ✓
- VRMenu.prefab: VRMenuButton references ✓
- Experience.unity: OVRCameraRig ✓, BubbleManager ✓, DogAvatar ✓, VRMenu ✓, PinchDetectRight ✓

## Deviations from Plan

### Auto-Fixed Issues

**1. [Rule 3 - Blocking] Replaced reflection with public method for BillboardVR cameraTarget**
- **Found during:** Task 1 - BubbleManager.cs
- **Issue:** BubbleManager needed to assign cameraTarget to BillboardVR after spawn, but the plan specified `[SerializeField] private Transform cameraTarget`
- **Fix:** Added `public void SetCameraTarget(Transform target)` method to BillboardVR, removed reflection extension class
- **Files modified:** BillboardVR.cs (added SetCameraTarget), BubbleManager.cs (simplified call, removed reflection)

## Known Stubs

None. All components are fully wired for their plan scope. The VRMenu button callbacks (OnToggleDetection, OnToggleAvatar, OnSettings) are stubs as per plan spec -- wired in Plan 40-03+ with actual functionality.

## Notes for Plan 40-03

Expected interfaces available:
- `BubbleManager.ShowBubble(string text, Transform anchorPoint)` -- wire to BarkDetector
- `DogAvatarController.PlayBark()` -- available for bark animation triggers
- `VRMenu.OnToggleDetection()` -- wire to bark detection toggle
- `VRMenu.OnToggleAvatar()` -- wire to DogAvatar set active/inactive
- `TranslationBubble.onPinned` event -- implement pin to prevent auto-dismiss
- `TranslationBubble.poolReturn` event -- used by BubbleManager for pool management

## Authentication Gates

None. All code created as Unity C# scripts with prefab YAML.
