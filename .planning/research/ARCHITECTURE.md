# Architecture Research

**Domain:** M007 AR/VR — Mixed Reality Translation Features
**Researched:** 2026-04-03
**Confidence:** HIGH

## Executive Summary

WoofTalk's existing architecture (Supabase backend + multi-platform clients) is extended with two new immersive platforms: AR (Apple Vision Pro/iOS) and VR (Meta Quest). The key architectural challenge: **mapping 2D translation concepts to 3D spatial interfaces** while reusing existing translation engine and backend. No new backend infrastructure needed; instead, add two new client applications that share Supabase for persistence and sync.

The AR app (Vision Pro) uses RealityKit for spatial UI - translation bubbles anchored to dog positions (or user gaze). The VR app (Quest) uses Unity for virtual environments - dog avatars with floating speech bubbles. Both consume the same Edge Function APIs (translate, phrases, history) and maintain user identity via Supabase Auth.

---

## 1. Platform Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                      Supabase Backend                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │
│  │ PostgreSQL  │ │ Edge Funcs  │ │    Auth (OAuth)     │ │
│  │ (data, RLS) │ │ (translate) │ │                     │ │
│  └─────────────┘ └─────────────┘ └─────────────────────┘ │
└────────────────────────────────────────────────────────────┘
                    ║              ║              ║
     ┌──────────────┼──────────────┼──────────────┼──────────────┐
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  iOS    │  │ Android │  │  Web    │  │  Watch  │  │   AR    │
│ (Swift) │  │ (Kotlin)│  │(React)  │  │(Wear OS)│  │(Vision  │
│         │  │         │  │         │  │         │  │ Pro)    │
└─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
                                                  │RealityKit
                                                  │ARKit
                                                  │Swift
     ┌──────────────┼──────────────────────────────┼──────────────┐
     │              │                              │              │
     ▼              ▼                              ▼              ▼
┌─────────┐  ┌─────────┐                  ┌─────────┐  ┌─────────┐
│  VR     │  │ Shared  │                  │  API    │  │ Future  │
│ (Quest) │  │  State  │                  │ Gateway│  │  AR/VR │
│(Unity)  │  │(Redis)  │                  │(Edge   │  │ Devices │
└─────────┘  └─────────┘                  │ Funcs) │  └─────────┘
                                          └─────────┘
```

---

## 2. AR Platform Architecture (Vision Pro)

### Component Diagram

```
WoofTalkAR (Vision Pro App)
├── App.swift (entry)
├── ContentView (SwiftUI)
│   └── ARContainerView
│       └── ARView (RealityKit)
│           ├── Camera (ARSession)
│           ├── Anchors
│           │   ├── UserGazeAnchor (fallback - at 2m in front)
│           │   └── DogProximityAnchor (when dog bark detected + direction)
│           ├── Entities
│           │   ├── TranslationBubble (Text + Background plane)
│           │   ├── DogAvatar (simple 3D model or point cloud)
│           │   └── SpatialAudioSource (3D sound)
│           └── GestureRecognizers (tap, pinch, voice)
│
├── TranslationService.swift
│   ├── BarkDetector (Vision framework + custom CoreML model)
│   ├── AudioRecorder (continuous listening with VAD)
│   ├── EdgeFunctionClient (calls /functions/v1/translate)
│   └── TranslationHistoryFetcher (Supabase query)
│
├── ARCoordinator.swift
│   ├── DogPositionTracker (proximity + direction estimation)
│   ├── BubblePlacementEngine (avoid occlusions, maintain readable distance)
│   └── SpatialAudioController (position audio in 3D)
│
└── Persistence
    └── Supabase client (auth + database + storage)
        ├── User identity
        ├── Translation history
        └── Settings + preferences
```

### Data Flow: Dog Bark → Translation Bubble

1. **Audio capture:** Continuous microphone input (Vision Pro has 6-mic array)
2. **Voice activity detection (VAD):** Detect when dog bark starts/ends
3. **Bark classifier (Core ML):** Is this a dog vocalization? If yes → extract 1-sec clip
4. **Edge Function call:** `POST /functions/v1/translate` with audio (or extracted features)
   - AR app uses same Edge Function as iOS/Android, just different client
5. **Response received:** Translation text + confidence + detected emotion
6. **Position estimation:**
   - Option A: User is looking at dog (gaze direction + distance from LiDAR)
   - Option B: Audio direction (sound source localization from multiple mics)
   - Option C: Manual placement (user says "Show translation here" while pointing)
7. **Create AR anchor:** Place `TranslationBubble` entity at estimated dog position, billboarded to face user
8. **Spatial audio:** Play translation audio from bubble location (directional sound)
9. **Persist to history:** Insert into Supabase `translation_history` with `position_3d` JSONB field (x, y, z in AR world coordinates)

### AR-Specific Technical Challenges

- **Dog position estimation without body tracking:** Requires heuristics (gaze + distance + audio direction). Accuracy "good enough" for MVP.
- **Placing UI in 3D:** Text must be readable → minimum font size, contrast, opacity, drop shadow. RealityKit's `Text` component limited - may need textured plane with pre-rendered text.
- **Performance budget:** 90 FPS on Vision Pro → limit number of active bubbles (max 5), fade out old ones.
- **Battery life:** Vision Pro battery ~2 hours under continuous use → AR translation should be opt-in mode, not always-on.

---

## 3. VR Platform Architecture (Meta Quest)

### Component Diagram

```
WoofTalkVR (Unity App for Quest)
├── Scenes
│   ├── MainMenu (2D overlay via OVR Overlay)
│   └── Experience
│       ├── Player (OVRCameraRig)
│       ├── Environment (park, living room, virtual space)
│       ├── DogAvatar (animated 3D model)
│       │   ├── Idle animation (wagging tail, panting)
│       │   ├── Bark animation (triggered when dog "speaks")
│       │   └── Position tracking (spatial anchor)
│       ├── TranslationBubble (World Space Canvas + TextMeshPro)
│       └── InteractionHand (hand tracking or controller)
│
├── Scripts (C#)
│   ├── BarkDetector.cs (Unity Microphone + TensorFlow Lite model)
│   ├── TranslationClient.cs (REST calls to Supabase Edge Functions)
│   ├── DogAvatarController.cs (animates avatar based on translation)
│   ├── BubbleManager.cs (spawns/positions/fades translation bubbles)
│   ├── SpatialAudio.cs (Oculus Spatializer plugin)
│   └── SessionRecorder.cs (logs 3D positions + translations for later review)
│
├── Services
│   ├── Supabase.NET (official Unity package)
│   │   ├── Authentication
│   │   ├── Database queries (history, user data)
│   │   └── Storage (avatar customization)
│   └── Meta XR SDK
│       ├── Hand tracking
│       └── Passthrough (optional - mixed reality mode on Quest Pro/3)
│
└── Prefabs
    ├── DogAvatar (FBX model + rig + animations)
    ├── TranslationBubble (prefab with TextMeshPro)
    └── Environment (modular park assets)
```

### Data Flow: Virtual Dog Translation

1. **Dog avatar behavior:**
   - Avatar is always present in user's personal space
   - Dog "barks" via pre-canned animation → triggers `BarkDetector` listening
   - OR: User manually triggers "Translate dog" via hand gesture/controller

2. **Audio capture:**
   - Dog barks are simulated → no real audio capture from virtual dog
   - OR: If doing mixed reality with real dog, microphone captures real bark (same as AR flow)

3. **Translation:**
   - Send bark audio (or text label "bark") to Edge Function
   - Receive translation + emotion
   - Attach translation to dog avatar's position

4. **Bubble display:**
   - `TranslationBubble` spawns 1m above dog's head (or in front of face)
   - Billboards toward user (always faces camera)
   - Fades out after 5 seconds

5. **Spatial audio:**
   - Play translation audio from dog's mouth position using Oculus Spatializer
   - Audio attenuates with distance → realistic

6. **Persistence:**
   - Save translation to history with VR-specific metadata (dog avatar ID, scene, position)

### VR-Specific Technical Challenges

- **Avatar animation quality:** Need believable dog animations (idle, bark, head turn). Budget for 3D artist or purchase asset pack.
- **VR performance:** Keep under 20ms frame time for 90 FPS. Use GPU instancing for bubbles, limit active audio sources.
- **Motion sickness:** Avoid moving the world relative to user. Dog should move through static environment, not vice versa. Snappy animations, no easing on bubble movement.

---

## 4. Shared Services & Backend

No new backend services required. Existing Supabase infrastructure supports both AR/VR:

- **Supabase Auth:** OAuth providers (Apple for AR, Meta for VR) → same user identity across platforms
- **PostgreSQL:** Existing tables (`translations`, `phrases`, `users`, `organizations`) unchanged
- **Edge Functions:** Already handle translation logic → AR/VR clients call `/translate` same as iOS/Android
- **Realtime:** Optional for AR multi-user (multiple Vision Pros seeing same dog) - future enhancement

**New data to capture:**
- `translation_history`: Add `platform` column (ar_vision, vr_quest, etc.)
- `translation_history`: Add `spatial_position` JSONB for AR/VR positions (x,y,z in device-specific coordinate system)
- `user_devices`: New table to track registered AR/VR devices (optional for push notifications)

**New Edge Function endpoints (if needed):**
- `GET /v1/dog-avatar/{breed}` - fetch 3D model URL for user's dog (optional customization)
- `POST /v1/translate/batch` - for VR scenario where dog barks repeatedly
- `GET /v1/environments` - list available VR scenes

All can be added as extensions to existing Edge Functions, no breaking changes.

---

## 5. Dog Tracking Strategy (AR without Body Pose)

Since ARKit doesn't track dogs, we need a fallback anchoring strategy:

### Multi-modal Position Estimation

1. **Gaze-based (primary):**
   - When user looks at dog, Vision Pro knows gaze hit-tested to plane at dog's distance
   - ARKit `raycast` from screen center returns world position
   - Place translation bubble at that position + offset (0.5m above dog)

2. **Audio direction (secondary):**
   - Vision Pro's 6-mic array can estimate sound direction (AOA - angle of arrival)
   - Combine with known user orientation → approximate dog location
   - Less accurate than gaze, but useful when user not looking

3. **Proximity beacon (manual):**
   - User places virtual beacon pointing at dog via hand gesture
   - Beacon persists for duration of translation session

4. **QR code collar (optional hack):**
   - User attaches small QR code to dog's collar
   - ARKit detects QR code → exact 3D position
   - Low-tech but effective; not needed for V1

**UX pattern:** 
- Initial bubble appears at gaze position
- Bubble "sticks" to approximate 3D position
- Bubble follows dog only if user gaze remains on dog (re-raycast every 0.5s)
- If dog moves out of view, bubble fades or stays at last known position

---

## 6. Platform Distribution Strategy

| Platform | Store | Bundle | Account | Pricing Model |
|----------|-------|--------|---------|---------------|
| Vision Pro (AR) | visionOS App Store | Separate binary (or iOS+iPadOS+visionOS universal) | Apple ID | Freemium (maybe premium add-on) |
| Meta Quest (VR) | Meta Quest Store | Separate Android APK | Meta account (OAuth) | Freemium (maybe premium add-on) |
| Existing clients (iOS/Android/Web/Watch) | Unchanged | Unchanged | Supabase Auth | Freemium (unchanged) |

**In-app purchase considerations:**
- AR/VR features could be "premium" (subscription add-on) to offset development cost
- Or keep free to drive brand innovation and PR

---

## 7. Development Phases (Proposed)

**Phase 38: AR Foundation & Dog Detection**
- Set up Vision Pro target in Xcode, RealityKit sandbox
- Build bark detector Core ML model (train on public datasets)
- Verify translation API calls from Vision Pro to Supabase
- Deliver: Simple AR overlay showing translation bubbles at fixed position

**Phase 39: AR Spatial UX & Dog Position Estimation**
- Implement gaze-based anchoring
- Build bubble placement engine (distance, occlusion, readability)
- Add spatial audio feedback
- Deliver: Usable AR translation MVP

**Phase 40: VR Foundation & Avatar System**
- Set up Unity + Meta XR SDK project
- Import/create simple dog avatar with animations
- Implement translation bubble system in VR
- Deliver: Seated VR experience with dog avatar

**Phase 41: VR Environment & Performance**
- Build multiple virtual environments (park, living room)
- Hand tracking integration for menu navigation
- Performance optimization for 90 FPS on Quest 2/3
- Motion sickness testing and comfort modes
- Deliver: Polished VR experience

**Phase 42: Cross-Platform Sync & Analytics**
- AR/VR history syncs to user's iOS/Android/Web clients
- Shared settings (bubble preferences, audio volume)
- Analytics: AR/VR usage metrics, session length, accuracy feedback
- Deployment and store submission (both platforms)
- Deliver: M007 complete, all platforms integrated

---

## What NOT to Build (Clear Scope Boundaries)

- No cross-platform Unity AR (too low-quality on Vision Pro)
- No custom operating system or embedded device
- No cloud-based dog sound processing (must be on-device for privacy and latency)
- No multi-user AR/VR until V2 (too complex: presence, avatar synchronization, networking)
- No dog physical tracking beyond what ARKit provides (Pitfall #1 acknowledged)
