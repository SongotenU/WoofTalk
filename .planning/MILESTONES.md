# Milestones

## v0.1.0 M007 AR/VR Mixed Reality (Shipped: 2026-04-04)

**Phases completed:** 5 phases, 21 plans, 9 tasks

**Key accomplishments:**

- Vision Pro AR app with ARKit/RealityKit, Core ML dog bark classifier, real-time camera passthrough, translation bubble rendering, and spatial audio
- AR spatial UX with gaze-based dog position estimation (raycast + hit-testing), bubble placement engine with distance clamping and billboarding, 90 FPS readability optimization
- Bubble pinning, manual placement gestures, environmental awareness with wall/furniture occlusion avoidance
- Meta Quest VR project with Unity 2022 LTS, Meta XR SDK v63, DogAvatar prefab with idle/bark/head-turn animations and Animator controller
- VR hand tracking via OVRHand with pinch detection, translation bubble system using TextMeshPro world-space UI with 5-bubble object pool, VR menu system
- VR bark detection with TFLite model integration (mock fallback), Oculus Spatializer for 3D audio attenuation and direction
- 3 virtual environments, dog avatar customization with Supabase Storage, Quest 2/3 performance presets (72/90 FPS), motion sickness mitigation, settings UI
- Cross-platform translation history sync, shared user settings, platform-specific analytics across iOS/Android/Web/Watch/AR/VR
- Database migrations: platform column, spatial_position JSONB, dog_avatars table, user_devices table, platform backfill, RLS policies
- App Store submission guides for Vision Pro and Meta Quest, deployment checklist, user documentation, fallback strategies for non-Vision Pro iOS devices

---
