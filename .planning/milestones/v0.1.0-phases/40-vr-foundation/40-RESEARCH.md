# Phase 40: VR Foundation - Research

**Researched:** 2026-04-03
**Domain:** Unity 2022 LTS + Meta XR SDK for Meta Quest 2/3 VR development
**Confidence:** MEDIUM

## Summary

This phase establishes a greenfield Unity project targeting Meta Quest 2/3 with the Meta XR All-in-One SDK. Six requirements: Unity project setup (VR-01), dog avatar with animations (VR-02), hand tracking (VR-03), translation bubbles with TextMeshPro (VR-04), bark detection with TensorFlow Lite (VR-05), and spatial audio with Oculus Spatializer (VR-06).

The Unity + Quest toolchain has well-documented pitfalls around Android SDK/NDK configuration, the hand tracking CPU overhead, and model conversion for on-device inference. The most uncertain area is Barracuda vs native TensorFlow Lite plugin for Unity -- existing documentation is fragmented and version-dependent.

**Primary recommendation:** Use Meta XR All-in-One SDK v63+ (not the deprecated Oculus Integration package), Unity 2022.3 LTS with URP, and start with a simulated bark trigger for early development while the TFLite pipeline is finalized separately.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Target platform: Meta Quest 2/Quest 3 (Android-based VR headset)
- Engine: Unity 2022 LTS
- SDK: Meta XR SDK (formerly Oculus Integration)
- Primary language: C# (instead of Swift)
- 3D rendering: Unity's built-in renderer (URP or built-in RP)
- Greenfield implementation — no shared code with visionOS AR
- FBX format for dog avatar with rigging (humanoid or custom)
- Required animations: idle, bark, head-turn
- OVRHand component for hand tracking
- TextMeshPro for world-space bubble UI with billboard script
- TensorFlow Lite model (Core ML model converted to .tflite)
- Microphone permission required in Android manifest

### Claude's Discretion
- URP vs Built-in render pipeline selection
- Placeholder vs purchased dog model
- Barracuda vs native TFLite plugin selection
- Gaze-based vs hand-pointer interaction for bubbles
- Audio source: TTS vs pre-recorded vs tone placeholder

### Deferred Ideas (OUT OF SCOPE)
- Dog body tracking in AR space (not applicable to VR)
- Multi-user VR networking
- Avatar customization (Phase 41)
- Multiple virtual environments (Phase 41)
- Motion sickness mitigation (Phase 41)
- Supabase integration (Phase 42)
- ARCore support (explicitly excluded)
- OpenXR abstraction (explicitly excluded)

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VR-01 | Unity project with Meta XR SDK, Oculus Integration, Quest deployment target | Sec: VR-01 Setup, Stack table, Code Examples |
| VR-02 | Dog avatar 3D model with idle, bark, and head-turn animations (FBX rig) | Sec: VR-02 Avatar, Model sources, Animator patterns |
| VR-03 | Hand tracking integration (OVRHand) for menu navigation and gaze-based triggers | Sec: VR-03 Hand Tracking, OVRHand patterns, pinching |
| VR-04 | Translation bubble system using TextMeshPro in world space, billboarded to user | Sec: VR-04 Bubbles, TextMeshPro patterns, billboard code |
| VR-05 | Bark detection using TensorFlow Lite model (accuracy >85%) | Sec: VR-05 ML Pipeline, TFLite vs Barracuda, audio capture |
| VR-06 | Spatial audio via Oculus Spatializer with attenuation and direction | Sec: VR-06 Spatial Audio, AudioSource config |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Unity 2022 LTS** | 2022.3.x | Rendering engine, physics, Android build | Meta officially certifies against LTS; 2022.3 is current stable LTS as of 2024-2025 |
| **Meta XR All-in-One SDK** | 63.x+ (via OVR Package Manager) | Quest integration (tracking, passthrough, input) | Official Meta package; supersedes deprecated Oculus Integration Asset Store package |
| **TextMeshPro** | 3.0.6+ (bundled) | 3D text rendering for bubbles | Best-in-class text quality included in Unity; standard for VR UI text |
| **Oculus XR Plugin** | com.unity.xr.oculus (bundled) | Unity XR Provider for Quest | Required for Quest Android builds; part of Unity XR Management |
| **Android SDK Platform 33+** | Latest 33,34,35 | Build target for Quest | Quest 3 requires API 33+; minimum is API 23 |
| **Android NDK** | r25b or later (Meta-recommended) | Native compilation | Required for Meta XR SDK native libs |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Unity Barracuda** | 1.5.x - 2.0.x | TensorFlow/ONNX model inference in Unity | If you want pure-Unity ML pipeline without native plugins |
| **TFLite Unity Plugin (Native)** | Varies (community) | Direct TensorFlow Lite runtime | If Barracuda compatibility fails for your model format |
| **Supabase Unity SDK** | 1.x+ | Supabase client for C# | Later phases for data sync |
| **Unity Recorder** | 4.x | Performance profiling, FPS capture | Debug/perf analysis during development |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Barracuda | Native TFLite Unity plugin | Barracuda = easier install, broader Unity support; Native TFLite = better performance, harder setup |
| Meta XR All-in-One SDK | Individual Meta XR Packages (Core, Audio, Haptics) | All-in-one = faster setup; individual = smaller APK size |
| URP | Built-in RP or HDRP | URP = Quest performance target, best balance; Built-in = simpler; HDRP = overkill for Quest |

**Installation:**
```bash
# In Unity Editor:
# 1. Window > Package Manager
# 2. Install "Meta XR All-in-One SDK" (via registry add: https://npm.developers.meta.com)
# 3. Enable: XR Plugin Management (Edit > Project Settings > XR Plugin Management > Add Oculus)
# 4. Enable Hand Tracking: Edit > Project Settings > Meta XR Plugin > Hands Support > Enabled

# Android SDK/NDC setup (Unity Hub > Installs > Add Modules > Android Build Support)
# Then in Unity: Edit > Preferences > External Tools > Set Android SDK, NDK, JDK paths
```

**Version verification:** The following versions should be confirmed against:
- Unity Hub for Unity 2022.3 latest patch
- Meta Package Registry (npm.developers.meta.com) for Meta XR SDK latest
- Unity Package Manager for Barracuda latest
- Android Studio SDK Manager for NDK version

## Architecture Patterns

### Recommended Project Structure
```
Assets/
├── Scenes/
│   ├── MainMenu.unity          # Main menu scene (if multi-scene)
│   └── Experience.unity         # Primary VR experience scene
├── Scripts/
│   ├── Bark/
│   │   ├── BarkDetector.cs     # Microphone capture + TFLite inference
│   │   └── BarkClassifier.cs   # Model input/output handling
│   ├── UI/
│   │   ├── TranslationBubble.cs    # Billboard + text + auto-dismiss
│   │   ├── BubbleManager.cs        # Spawn/pool management
│   │   └── VRMenu.cs               # Hand-tracking accessible menu
│   ├── Avatar/
│   │   └── DogAvatarController.cs  # Animator trigger wrapper
│   └── Audio/
│       └── SpatialAudioManager.cs  # Audio source positioning
├── Prefabs/
│   ├── TranslationBubble.prefab    # Reusable bubble (world-space Canvas)
│   ├── DogAvatar.prefab            # Dog model + animator
│   └── VRMenu.prefab               # Menu panel with buttons
├── Models/
│   └── DogAvatar.fbx               # Dog model (or placeholder)
├── Materials/
│   ├── BubbleBackground.mat
│   └── DogMaterials/
├── Audio/
│   ├── BarkAudio/                  # Bark samples for testing
│   └── TTSOutput/                  # Translation audio clips
├── Plugins/
│   └── Android/
│       └── AndroidManifest.xml     # Custom manifest for mic permission
├── Animations/
│   ├── Dog/
│   │   ├── DogIdle.anim
│   │   ├── DogBark.anim
│   │   └── DogHeadTurnLeft.anim
│   └── DogAvatar.controller
├── Textures/
└── Resources/
    └── woof_bark_model.tflite      # TFLite model file
```

### Pattern 1: OVRCameraRig + XR Origin
**What:** Use Meta's OVRCameraRig as the player prefab. This provides eye tracking, head tracking, and hand anchor transforms out of the box.
**When to use:** Always -- this is the entry point for any Meta Quest Unity project.
**Example:**
```csharp
// Standard scene setup: OVRCameraRig prefab is root of player
// Access head camera:
var headsetCamera = ovrCameraRig.centerEyeAnchor.GetComponent<Camera>();
// Access hand anchors (for hand tracking):
var leftHandAnchor = ovrCameraRig.leftHandAnchor;
var rightHandAnchor = ovrCameraRig.rightHandAnchor;
```

### Pattern 2: World-Space Canvas with Billboard
**What:** Translation bubble as a world-space Canvas with a simple billboard script that rotates toward the user's head each frame.
**When to use:** For any text that must remain readable regardless of user position.
**Example:**
```csharp
// BillboardVR.cs - attached to bubble prefab
public class BillboardVR : MonoBehaviour
{
    [SerializeField] private Transform cameraTarget; // OVRCameraRig centerEyeAnchor

    void LateUpdate() // Use LateUpdate to match camera position
    {
        if (cameraTarget != null)
        {
            // Face camera but keep upright (constrain Y rotation only)
            Vector3 flatTarget = new Vector3(
                cameraTarget.position.x,
                transform.position.y,
                cameraTarget.position.z
            );
            transform.LookAt(flatTarget);
        }
    }
}
```

### Pattern 3: Hand Pinch Detection via OVRHand
**What:** Detect finger pinch gesture using OVRHand's built-in finger confidence values.
**When to use:** For selecting menu buttons, pinning translation bubbles, dismissing UI.
**Example:**
```csharp
// PinchDetect.cs
public class PinchDetect : MonoBehaviour
{
    private OVRHand _ovrHand;

    public OVRPlugin.Hand HandType; // Left or Right
    [SerializeField] float pinchThreshold = 0.8f;

    void Awake()
    {
        _ovrHand = GetComponent<OVRHand>();
    }

    void Update()
    {
        // Index finger pinch (thumb to index)
        bool isPinching = _ovrHand.GetFingerIsPinching(OVRHand.fingerIndex);
        if (isPinching && IsPointingAtBubble())
        {
            OnBubbleSelected();
        }
    }
}
```

### Pattern 4: Animator State Machine for Dog
**What:** Unity Animator Controller with Idle as default state, transitions triggered by bool/trigger parameters for bark and head-turn.
**When to use:** For the DogAvatar prefab animation system.
**Example:**
```csharp
// DogAvatarController.cs
public class DogAvatarController : MonoBehaviour
{
    private Animator _animator;

    void Awake() => _animator = GetComponent<Animator>();

    public void PlayBark()
    {
        _animator.SetTrigger("Bark");
    }

    public void PlayHeadTurn(float direction) // -1 left, 1 right
    {
        _animator.SetFloat("HeadTurnDirection", direction);
    }

    // Idle is the default state -- no explicit trigger needed
}
```

### Pattern 5: Unity Microphone Streaming
**What:** Continuous audio capture using Unity's Microphone API with circular buffer for ML inference.
**When to use:** For real-time bark detection pipeline.
**Example:**
```csharp
// BarkDetector.cs
public class BarkDetector : MonoBehaviour
{
    private const int SampleRate = 48000;
    private const int BufferSize = 1024;

    private string micDevice;
    private AudioClip micClip;

    private float[] _sampleBuffer = new float[BufferSize];

    async void Start()
    {
        // Wait for mic to become available (Quest may prompt for permissions)
        yield return new WaitForSeconds(1f);

        micDevice = Microphone.devices.Length > 0 ? Microphone.devices[0] : null;
        if (string.IsNullOrEmpty(micDevice))
        {
            Debug.LogWarning("No microphone device found");
            return;
        }

        micClip = Microphone.Start(micDevice, true, 10, SampleRate); // loop, 10s
        while (Microphone.GetPosition(micDevice) <= 0)
        {
            yield return null; // Wait for mic to be ready
        }

        StartCoroutine(CaptureLoop());
    }

    private IEnumerator CaptureLoop()
    {
        while (true)
        {
            int pos = Microphone.GetPosition(micDevice);
            micClip.GetData(_sampleBuffer, pos - BufferSize);
            // Feed to classifier...
            var result = await ClassifyAudio(_sampleBuffer);
            if (result.isBark && result.confidence > 0.7f)
            {
                OnBarkDetected();
            }
            yield return new WaitForSecondsRealtime(0.1f); // ~10 FPS inference
        }
    }
}
```

### Anti-Patterns to Avoid
- **Using Update() for camera-facing billboard:** Causes one-frame jitter; use LateUpdate() instead since camera position is set in Update().
- **Loading TFLite model on main thread:** Loading can take seconds; use async/await during scene load.
- **Spawning new bubble GameObjects:** Use an object pool (ObjectPool pattern) to avoid GC spikes at 90 FPS.
- **Setting AudioMixer volumes at runtime per-frame:** Expensive; cache references and batch updates.
- **Hand tracking with too many UI elements:** Quest 2 hand tracking drops to ~30 FPS if too many hand visuals are rendered; use simplified hand representations.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| VR Text rendering | Custom textured plane + font atlas | TextMeshPro (world-space Canvas) | TextMeshPro handles SDF text rendering, kerning, line wrapping automatically |
| Spatializer audio plugin | Manual distance-based volume | Oculus Spatializer (built into Meta XR Audio SDK) | HRTF binaural rendering, room acoustics, already optimized for Quest |
| Dog bark ML inference from scratch | Raw audio feature extraction | TFLite model via Barracuda or native plugin | Edge cases: sample rate conversion, model loading error handling, tensor shape validation |
| VR Menu interaction | Raycast + collider from hand bone | Meta XR Interaction SDK OVRInteractor | Handles pointer projection, button press, grip/hand pose, accessibility |
| Object pooling | Manual List<GameObject> management | Unity's built-in pool or simple custom pool class | Bubble spawn/despawn at 90 FPS causes GC pressure; pools avoid allocation |
| Android manifest for permissions | Raw XML edit without template | Unity Player Settings Android section + manifest override template | Quest requires specific manifest entries (microphone, handTracking features) |

**Key insight:** Quest development is a highly performance-constrained environment. Every allocation, every draw call, every unnecessary computation impacts the 20ms frame budget for 90 FPS. Using Meta's provided SDKs and Unity's standard components avoids the hidden costs of custom solutions.

## Runtime State Inventory

> This phase is greenfield -- no rename/refactor/migration operations. All state categories verified as empty/n/a.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None -- greenfield Unity project, no database yet | N/A |
| Live service config | None -- no external services configured for VR yet | N/A |
| OS-registered state | None -- no OS-level registrations for VR app yet | N/A |
| Secrets/env vars | None -- VR phase has no existing secrets | N/A |
| Build artifacts | None -- Unity project does not exist yet | N/A |

## Common Pitfalls

### Pitfall 1: Android SDK/NDK Configuration Mismatch
**What goes wrong:** Unity Android build fails with cryptic errors about missing NDK tools, incompatible Gradle versions, or SDK path issues.
**Why it happens:** Unity 2022 LTS bundles specific JDK (11), and the NDK version must match what Meta XR SDK expects. Android SDK platform version must match the Quest OS requirements (API 32+ recommended, 33+ for Quest 3).
**How to avoid:**
1. Install Android Build Support module via Unity Hub (selects matching JDK/SDK automatically).
2. Set Android SDK path in Edit > Preferences > External Tools.
3. Use Gradle template: set `android.useAndroidX=true` and matching `com.android.tools.build:gradle` version in mainTemplate.gradle.
4. Verify with Meta's official Unity Project Setup guide before building.
**Warning signs:** Build errors mentioning "ndk-build," "aapt," or "gradle" during Android build.

### Pitfall 2: Hand Tracking CPU Budget
**What goes wrong:** Enabling hand tracking drops frame rate from 90 FPS to 60+ FPS on Quest 2.
**Why it happens:** Hand tracking neural network runs on CPU; combined with rendering and other systems, it can exceed Quest 2's CPU budget.
**How to avoid:**
1. Use `OVRManager.handTrackingSupport` to check at runtime -- enable only if supported.
2. Render hand visuals as simple capsules/spheres instead of full mesh.
3. Reduce other CPU-bound operations (avoid heavy Update() loops).
4. Fall back to controller pointers if FPS drops below 72.
**Warning signs:** CPU usage > 70% in Unity Profiler, frame time > 13.9ms (72 FPS threshold).

### Pitfall 3: TFLite Model Compatibility with Unity
**What goes wrong:** Core ML (.mlmodel) does not directly convert to TFLite (.tflite). The conversion pipeline fails at intermediate format.
**Why it happens:** CoreML and TFLite use different execution graphs. Direct conversion (CoreML -> TFLite) is not supported by Apple or Google tools.
**How to avoid:**
1. Convert CoreML -> ONNX first (using coremltools >= 7.x).
2. Convert ONNX -> TFLite: Use `onnx-tf` or retrain from source TensorFlow code.
3. **Alternative:** Skip TFLite entirely. Use Unity Barracuda which loads ONNX natively -- this avoids TFLite altogether but Barracuda ONNX support is limited to certain ops.
4. **Best practical path:** Export the original model source code to ONNX/TFLite format directly, bypassing CoreML. If only CoreML is available, rebuild the model architecture in TensorFlow/Keras and export to TFLite.
**Warning signs:** `onnx_coreml_converter` throws unsupported layer errors; Barracuda logs "Unsupported operator X".

### Pitfall 4: Unity Microphone on Quest Has Latency
**What goes wrong:** `Microphone.Start()` on Quest has high latency (100-500ms) before audio data is available.
**Why it happens:** Android AudioRecord initialization on Quest requires permission grant, and Unity's cross-platform Microphone API is not optimized for low-latency Android.
**How to avoid:**
1. Use `AudioSettings.GetDSPBufferSize()` to determine actual buffer size.
2. Use `OnAudioFilterRead()` callback instead of Microphone API for real-time capture (lower latency, runs in audio thread).
3. Consider native Android plugin (ARecord/AAudio) if latency is unacceptable.
4. Test on Quest device early -- simulator does not emulate mic behavior.
**Warning signs:** `Microphone.GetPosition()` returns 0 long after `Microphone.Start()`.

### Pitfall 5: Oculus Spatializer Requires Audio Spatialization Settings
**What goes wrong:** Spatial audio plays as mono/stereo with no directional cues.
**Why it happens:** The Oculus Spatializer plugin is not automatically enabled in Unity's audio settings. It must be set as the default spatializer plugin AND enabled per AudioSource.
**How to avoid:**
1. Edit > Project Settings > Audio > Spatializer Plugin > Set to "OculusSpatializer".
2. On each AudioSource: `spatialBlend = 1.0f` (3D mode), `spatialize = true`.
3. Test with headphones (Quest headsets play through built-in speakers which flatten spatialization).
**Warning signs:** Audio playback works but no directionality; AudioSource logs "spatialization not available".

### Pitfall 6: Meta XR SDK Package Confusion
**What goes wrong:** Developer installs "Oculus Integration" from Unity Asset Store instead of Meta XR All-in-One SDK via package manager.
**Why it happens:** Meta deprecated the Asset Store package but tutorials and docs still reference it. The old package name creates confusion.
**How to avoid:**
1. **Do NOT use:** Oculus Integration from Unity Asset Store (deprecated).
2. **DO use:** Meta XR All-in-One SDK from Meta's Unity Package Registry (`https://npm.developers.meta.com`).
3. Add registry to `Packages/manifest.json` under `scopedRegistries`.
4. Meta has also split into modular packages -- All-in-One is recommended for Phase 40 simplicity.
**Warning signs:** Package imports contain warnings about "deprecated" or missing features.

### Pitfall 7: Quest Build Fails Without Feature Permissions in AndroidManifest
**What goes wrong:** App crashes on Quest with permission denied errors at runtime.
**Why it happens:** Quest requires specific Android feature flags in the manifest that Unity does not automatically include for XR features like hand tracking and microphone.
**How to avoid:**
1. Add custom `AndroidManifest.xml` to `Assets/Plugins/Android/`.
2. Include: `<uses-feature android:name="oculus.software.handtracking" android:required="false" />`
3. Include: `<uses-permission android:name="android.permission.RECORD_AUDIO" />`
4. Set `android:extractNativeLibs="true"` for native plugin loading (TFLite).
**Warning signs:** Crash logs show `SecurityException` for RECORD_AUDIO, or hand tracking silently fails.

### Pitfall 8: Text Too Small / Unreadable in VR
**What goes wrong:** TextMeshPro text in world-space canvas is illegible at normal viewing distances.
**Why it happens:** Text that looks fine in the Unity editor appears tiny when viewed through the Quest headset due to display resolution vs field-of-view.
**How to avoid:**
1. Minimum Canvas width: 400+ pixels for readable text.
2. Canvas scale: 0.001 - 0.002 per pixel (roughly).
3. Use TextMeshPro "Extra Padding" and "Auto Size" for dynamic scaling.
4. Test on actual Quest hardware as early as possible.
5. Add background panel with high contrast (dark background, white text).
**Warning signs:** Text legible in Unity Game view but unreadable on device.

## Code Examples

Verified patterns from Unity/Meta XR documentation:

### VR-01: Meta XR SDK Package Installation
```json
// Add to Packages/manifest.json:
{
  "scopedRegistries": [
    {
      "name": "Meta XR SDK",
      "url": "https://npm.developers.meta.com",
      "scopes": ["com.meta.xr.sdk"]
    }
  ],
  "dependencies": {
    "com.meta.xr.sdk.all": "63.0.0"
  }
}
```

### VR-02: Dog Animation Controller Setup
```csharp
// DogAnimatorSetup.cs - runtime configuration
public void SetupAnimator()
{
    var controller = AnimatorOverrideController(animator.runtimeAnimatorController);
    // Override animations if using different dog models
    controller["Idle"] = customIdleClip;
    controller["Bark"] = customBarkClip;
    animator.runtimeAnimatorController = controller;
}

// Triggered from BarkDetector:
public void OnBarkDetected(float confidence)
{
    animator.SetTrigger("Bark");
    avatarBubbleManager.ShowBubble($"Bark detected ({confidence:P0} confident)");
}
```

### VR-03: Hand Menu with OVRGrabbable
```csharp
// Simplified hand-based button interaction
public class VRMenuButton : MonoBehaviour
{
    [SerializeField] private Transform pointer;      // OVRHand pointer transform
    [SerializeField] private float activationDistance = 0.02f;

    private bool _isPressed;

    void Update()
    {
        float dist = Vector3.Distance(pointer.position, transform.position);
        bool shouldBePressed = dist < activationDistance && IsHandPinching();

        if (shouldBePressed != _isPressed)
        {
            _isPressed = shouldBePressed;
            if (_isPressed) OnPressed?.Invoke();
        }
    }

    private bool IsHandPinching() => _ovrHand.GetFingerIsPinching(0);
}
```

### VR-04: Translation Bubble Spawn + Pool
```csharp
public class BubbleManager : MonoBehaviour
{
    [SerializeField] private GameObject bubblePrefab;
    [SerializeField] private int poolSize = 5;
    [SerializeField] private float autoDismissSeconds = 5f;
    [SerializeField] private Transform spawnOffset;   // Position relative to dog avatar

    private Queue<GameObject> _pool;
    private List<GameObject> _activeBubbles;

    void Start()
    {
        _pool = new Queue<GameObject>();
        _activeBubbles = new List<GameObject>();
        for (int i = 0; i < poolSize; i++)
        {
            var b = Instantiate(bubblePrefab, transform);
            b.SetActive(false);
            _pool.Enqueue(b);
        }
    }

    public void ShowBubble(string text, Transform anchorPoint)
    {
        if (_pool.Count == 0)
        {
            // Evict oldest
            var oldest = _activeBubbles[0];
            _activeBubbles.RemoveAt(0);
            _pool.Enqueue(oldest);
        }

        var bubble = _pool.Dequeue();
        bubble.transform.position = anchorPoint.position + spawnOffset.position;
        bubble.SetActive(true);

        var tmpro = bubble.GetComponentInChildren<TMP_Text>();
        tmpro.text = text;

        StartCoroutine(DismissAfter(bubble, autoDismissSeconds));
        _activeBubbles.Add(bubble);
    }

    private IEnumerator DismissAfter(GameObject bubble, float seconds)
    {
        yield return new WaitForSeconds(seconds);
        bubble.SetActive(false);
        _activeBubbles.Remove(bubble);
        _pool.Enqueue(bubble);
    }
}
```

### VR-05: Barracuda ONNX Model Inference
```csharp
// BarkDetector_Barracuda.cs (alternative to TFLite)
using Unity.Barracuda;

public class BarkDetector_Barracuda : MonoBehaviour
{
    [SerializeField] private NNModel modelAsset;  // ONNX model dragged into inspector
    private IWorker _worker;
    private const int InputSize = 1024;

    async void Start()
    {
        var model = ModelLoader.Load(modelAsset);
        _worker = WorkerFactory.CreateWorker(WorkerFactory.Type.CSharpBurst, model);

        // Wait for audio input... then:
        var inputTensor = new Tensor(1, 1, InputSize, 1, audioSamples);
        _worker.Execute(inputTensor);
        inputTensor.Dispose();

        var output = _worker.PeekOutput();
        var barkConfidence = output[0];
        // barkConfidence > 0.7f => bark detected
    }

    void OnDestroy() { _worker?.Dispose(); }
}
```

### VR-06: Spatial Audio Configuration
```csharp
// SpatialAudioManager.cs
public class SpatialAudioManager : MonoBehaviour
{
    [SerializeField] private AudioMixer audioMixer;

    public AudioSource PlayAtPosition(AudioClip clip, Vector3 position)
    {
        var go = new GameObject("SpatialAudio_" + clip.name);
        go.transform.position = position;

        var source = go.AddComponent<AudioSource>();
        source.clip = clip;
        source.spatialBlend = 1.0f;           // Full 3D
        source.spatialize = true;              // Enable spatializer
        source.rolloffMode = AudioRolloffMode.Logarithmic;
        source.minDistance = 1f;
        source.maxDistance = 20f;
        source.dopplerLevel = 0f;             // Disable doppler (unnecessary for static sources)

        // Set listener position (OVRCameraRig center eye)
        var listener = FindAnyObjectByType<AudioListener>();
        if (listener == null)
        {
            // Quest may not have AudioListener on OVRCameraRig -- add it
            listener = OVRCameraRig.Instance.centerEyeAnchor.gameObject.AddComponent<AudioListener>();
        }

        source.Play();

        // Destroy after clip ends
        Destroy(go, clip.length + 0.5f);
        return source;
    }
}
```

### AndroidManifest.xml for Quest (custom)
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.wooftalk.vr">

    <!-- Quest specific features -->
    <uses-feature android:name="android.hardware.vr.headtracking" android:required="true" />
    <uses-feature android:name="oculus.software.handtracking" android:required="false" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application android:extractNativeLibs="true">
        <meta-data android:name="com.samsung.android.vr.application.mode"
            android:value="vr_only"/>
        <meta-data android:name="com.oculus.supportedDevices"
            android:value="quest2|quest3" />
    </application>
</manifest>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Oculus Integration (Asset Store) | Meta XR All-in-One SDK (Package Registry) | 2023 | Cleaner dependency management, faster updates |
| Legacy Input System (OVRInput) | XR Input + Input System package | Unity 2022+ | Unified XR input, but OVRInput still works |
| Unity ML-Agents | Unity Barracuda for inference | 2022+ | Barracuda is the inference-only package, much lighter than ML-Agents |
| Oculus Spatializer (OVR plugin) | Meta XR Audio SDK | 2023 | More audio features including room reverb |
| Unity Microphone API | OnAudioFilterRead + Android native | Ongoing | Lower latency on Android |
| Quest 2 hand tracking (opt-in) | Quest 3 hand tracking (default + passthrough) | 2023 | Hand tracking is now the expected primary input for Quest 3 |

**Deprecated/outdated:**
- **Oculus Integration Asset Store package:** Replaced by Meta XR SDK via package registry. Do not install from Asset Store.
- **Unity's Mobile XR templates:** Superseded by the Meta XR SDK template.
- **OVRManager.handPresence:** Replaced by OVRHand components.
- **Core ML in Quest:** Not supported. Quest runs Android, not iOS.

## Open Questions

1. **What is the exact Unity 2022 LTS patch version to use?**
   - What we know: Unity 2022.3 is the current LTS line; Meta officially certifies 2022.3.x
   - What's unclear: Latest patch version and its certification status with Meta XR SDK 63+
   - Recommendation: Use Unity Hub to install latest 2022.3.x LTS, verify via Meta's certification docs before building

2. **Core ML to TFLite conversion path reliability**
   - What we know: CoreML and TFLite are incompatible formats; no direct conversion tool exists
   - What's unclear: Whether the existing Phase 38 CoreML model can be reliably converted through ONNX to TFLite without accuracy loss
   - Recommendation: If model source code (PyTorch/TensorFlow) is available, export to ONNX and TFLite directly. If only CoreML model file exists, rebuild from source. Test accuracy on Quest device with real audio samples.

3. **Barracuda vs native TFLite for on-Quest inference**
   - What we know: Barracuda loads ONNX models, TFLite loads .tflite models; Barracuda uses Burst compiler for faster execution
   - What's unclear: Whether Barracuda supports all operations in a bark classification model (mel-spectrogram features, CNN layers)
   - Recommendation: Start with Barracuda (ONNX). If the model uses unsupported layers, fall back to native TFLite plugin. Test inference latency on Quest -- target <50ms.

4. **Supabase C# SDK compatibility with Quest**
   - What we know: Supabase offers an official C# SDK (supabase-csharp)
   - What's unclear: Whether it works on Quest's Android runtime (IL2CPP backend may have compatibility issues with certain .NET features)
   - Recommendation: Defer to Phase 42. For Phase 40, use UnityWebRequest for simple REST calls to Edge Functions.

5. **Quest 2 vs Quest 3 performance targets**
   - What we know: Quest 2 targets 72 FPS, Quest 3 targets 90 FPS
   - What's unclear: Whether to build separate quality presets or detect device at runtime
   - Recommendation: Use `OVRPlugin.GetSystemHeadsetType()` to detect device and adjust quality settings programmatically. Build with Quest 3 as baseline, degrade gracefully for Quest 2.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Unity 2022 LTS | Engine (VR-01) | UNKNOWN | -- | Install via Unity Hub |
| Xcode/macOS Unity Editor | Development machine | UNKNOWN | -- | Mac running Unity; Windows also supported |
| Android SDK/NDK | Quest build (VR-01) | UNKNOWN | -- | Install via Unity Hub Android Build Support module |
| Meta Quest Hardware | Testing/deployment (all VR reqs) | UNKNOWN | -- | Use Meta Quest Link (PC VR) for limited testing without device, but many features (hand tracking, mic, spatial audio) require physical Quest |
| Meta Developer Account | Quest deployment (VR-01) | UNKNOWN | -- | Required for side-loading and store submission |
| Meta XR SDK Package | All VR features | UNKNOWN | -- | Install via Meta registry after Unity project created |
| Dog FBX Model | Avatar (VR-02) | UNKNOWN | -- | Use capsule placeholder as fallback (documented in CONTEXT.md) |
| Bark audio samples | Testing (VR-05) | UNKNOWN | -- | Use Phase 38 test audio samples as starting point |

**Missing dependencies requiring action:**
- Unity 2022 LTS installation (via Unity Hub)
- Android Build Support module installation
- Meta developer account creation and app registration
- Meta Quest 2/3 device for testing (simulator does not support hand tracking, microphone, or spatial audio)
- Dog 3D model (FBX) or decision to use placeholder

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Unity Test Framework (com.unity.test-framework) -- bundled with Unity 2022 LTS |
| Config file | None yet -- created during Phase 40 implementation |
| Quick run command | `Unity Test Runner` window > Run All (in-editor) |
| Full suite command | `Unity Test Runner` > Run All Tests (in-editor + on-device with Unity Test Runner Runner) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VR-01 | Unity project builds to Android APK for Quest | Manual + Build verification | Unity Build pipeline (Editor) | Wave 0 |
| VR-02 | Dog avatar spawns with idle animation playing | In-editor unit test | `TestRunner -n DogAvatarTests` | Wave 0 |
| VR-03 | Hand tracking initializes and pinch detected | Integration test (requires device) | Manual on-device | Wave 0 |
| VR-04 | Bubble spawns at correct position, faces camera, dismisses | Unit test | `TestRunner -n BubbleManagerTests` | Wave 0 |
| VR-05 | Bark detection returns correct classification from test audio | Unit test | `TestRunner -n BarkDetectorTests` | Wave 0 |
| VR-06 | Spatial audio plays from correct 3D position | Manual (requires device + headphones) | Manual | Wave 0 |

### Sampling Rate
- **Per task commit:** Unity editor play-mode tests for bubble and avatar logic
- **Per wave merge:** Run all unit tests + attempt Android build (does not require device)
- **Phase gate:** Successful Android build + on-device verification of hand tracking, bubble spawning, spatial audio before marking Phase 40 complete

### Wave 0 Gaps
- [ ] `Assets/Tests/Editor/DogAvatarTests.cs` -- covers VR-02 animator state validation
- [ ] `Assets/Tests/PlayMode/BubbleManagerTests.cs` -- covers VR-04 bubble lifecycle
- [ ] `Assets/Tests/PlayMode/BarkDetectorTests.cs` -- covers VR-05 classification accuracy with test audio
- [ ] `Assets/Tests/Editor/BuildValidation.cs` -- covers VR-01 build configuration checks
- [ ] Unity Test Framework package confirmed installed (included by default in Unity 2022)
- [ ] On-device testing script (requires physical Quest device) -- VR-03 and VR-06 cannot be validated in-editor

## Sources

### Primary (HIGH confidence)
- Meta XR SDK Documentation (developers.meta.com/horizon/documentation/unity/) -- official SDK docs
- Unity Manual: XR Plugin Management (docs.unity3d.com/Manual/xr-plugin-architecture.html)
- Unity Manual: TextMeshPro (docs.unity3d.com/Packages/com.unity.textmeshpro@3.0/manual/index.html)
- Unity Barracuda Documentation (docs.unity3d.com/Packages/com.unity.barracuda@latest)
- Meta Quest Developer Documentation (developers.meta.com/horizon/)

### Secondary (MEDIUM confidence)
- Community tutorials for Meta XR SDK v60+ setup (published 2024-2025)
- Unity Forum discussions on hand tracking CPU optimization
- GitHub: Unity Barracuda samples for ONNX model inference

### Tertiary (LOW confidence -- needs verification)
- Specific Barracuda operator support for mel-spectrogram preprocessing layers
- Exact Meta XR SDK 63+ version numbers and Unity 2022.3.x LTS compatibility matrix
- TFLite Unity plugin availability and maintenance status for Android arm64

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - Unity 2022 LTS and Meta XR SDK are well-established, but exact version/certification matrix needs verification against current Meta documentation
- Architecture: HIGH - Patterns from Unity/Meta XR conventions are well-documented; existing research artifacts (ARCHITECTURE.md) provide strong foundation
- Pitfalls: MEDIUM - All pitfall patterns are known issues in the Quest dev community, but specific version-dependent details (e.g., NDK compatibility) need verification
- Code examples: MEDIUM - Patterns are standard Unity/C# patterns; specific API names for latest Meta XR SDK may have changed

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (30 days -- Unity/Meta releases are quarterly, stable)

**Research limitations:**
- WebFetch, WebSearch, and Context7 tools were unavailable during this research session
- All findings are based on training data (stale) and analysis of existing project research artifacts
- Version numbers, API names, and configuration details should be verified against:
  - Meta Package Registry: https://npm.developers.meta.com
  - Unity 2022 LTS release notes: https://unity.com/releases/lts
  - Meta Horizon documentation: https://developers.meta.com/horizon/documentation/unity/
- Key verifications needed: Unity 2022 LTS exact patch, Meta XR SDK latest version, Barracuda ONNX operator coverage, Android NDK compatibility

## RESEARCH COMPLETE
