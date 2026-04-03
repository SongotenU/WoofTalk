---
phase: 38-ar-foundation
plan: 03a
type: execute
wave: 3
depends_on:
  - "38-01a"
  - "38-01b"
  - "38-02a"
  - "38-02b"
files_modified:
  - WoofTalkAR/Views/TranslationBubble.swift
  - WoofTalkAR/ARCoordinator.swift
  - WoofTalkAR/ContentView.swift (updates)
requirements:
  - AR-04
autonomous: true
must_haves:
  truths:
    - "Translation bubble appears at fixed 2m position in front of user"
    - "Bubble renders readable text (minimum 24pt equivalent)"
    - "Bubble billboards to face camera"
    - "Bubble dismissible via tap gesture"
    - "Auto-dismiss after 10 seconds"
    - "Max 3 concurrent bubbles supported with FIFO eviction"
  artifacts:
    - path: "WoofTalkAR/Views/TranslationBubble.swift"
      provides: "RealityKit entity with text rendering and billboard"
      min_lines: 60
      contains:
        - "Entity"
        - "AnchorEntity"
        - "ModelComponent"
        - "BillboardComponent"
        - "installGestures"
    - path: "WoofTalkAR/ARCoordinator.swift"
      provides: "Bubble placement and lifecycle management"
      min_lines: 80
      contains:
        - "actor ARCoordinator"
        - "showBubble(text:duration:)"
        - "setARView(_:)"
        "maxActiveBubbles = 3"
        - "2m positioning using camera transform forward column"
        - "autoDismissTime: TimeInterval = 10"
    - path: "WoofTalkAR/ContentView.swift"
      provides: "Integration with ARCoordinator for bubble display"
      contains:
        - "ARCoordinator.shared.setARView"
        - "ARCoordinator.shared.dismissAllBubbles"
  key_links:
    - from: "ARCoordinator.swift"
      to: "TranslationBubble.swift"
      via: "creates TranslationBubble entity"
      pattern: "TranslationBubble"
    - from: "ARCoordinator.swift"
      to: "ARView"
      via: "scene.addAnchor"
      pattern: "arView\\.scene\\.addAnchor"
    - from: "ContentView.swift"
      to: "ARCoordinator.swift"
      via: "setARView notification"
      pattern: "arViewReady"

---

<objective>
Create the translation bubble UI and lifecycle management system.

**Purpose:** Display dog translations as floating 3D text bubbles anchored 2m in front of user, with billboard effect, tap-to-dismiss, and lifecycle management.

**Output:** Complete bubble system:
- TranslationBubble RealityKit entity (rounded rectangle, white text, semi-transparent background)
- ARCoordinator managing bubble placement, max 3 concurrent, auto-dismiss 10s
- Integration with ContentView to receive ARView reference
- Fixed 2m positioning using camera transform

</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/38-ar-foundation/38-CONTEXT.md
@.planning/phases/38-ar-foundation/38-RESEARCH.md

# Translation Bubble Context

**From CONTEXT.md:**
- Fixed position at 2m in front of user (world anchor at camera transform + forward * 2)
- Simple rounded rectangle with slight shadow
- Background: semi-transparent dark (alpha 0.8)
- Text: white, dynamic type scaling but minimum 24pt
- Dismiss: tap anywhere on bubble
- Auto-dismiss: 10 seconds if no interaction

**From RESEARCH.md:**
- RealityKit Entity with ModelComponent (plane geometry)
- BillboardComponent to always face camera
- Anchor to ARWorldAnchor at fixed position
- TextMaterial or textured plane for crisp text

**From ARCHITECTURE.md:**
- ARCoordinator manages bubble lifecycle (spawn, fade out, remove)
- Max 3 concurrent bubbles (FIFO eviction)
- Position: camera.transform + forward * 2

</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create TranslationBubble RealityKit entity</name>
  <files>WoofTalkAR/Views/TranslationBubble.swift
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for RealityKit entity patterns
    - Reference: Apple RealityKit documentation for ModelComponent, BillboardComponent
  </read_first>
  <acceptance_criteria>
    - TranslationBubble struct creates Entity with AnchorEntity(.world)
    - Bubble background: plane geometry (0.4m wide × 0.2m tall) with semi-transparent dark UnlitMaterial (alpha 0.85)
    - Text entity: MeshResource.generateText with white UnlitMaterial, font size ~0.05 (24pt at 2m)
    - BillboardComponent on Y axis (mode = .y) to face camera horizontally
    - Tap gesture: installGestures([.tap]) on bubble entity
    - Dismiss callback executed when tap detected
    - Entity can be added to/removed from ARView.scene
    - Text wrapped with lineBreakMode .byWordWrapping
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Views/TranslationBubble.swift
      grep -q "struct TranslationBubble" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "AnchorEntity" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "ModelComponent" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "BillboardComponent" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "installGestures" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "generateText" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "dismissHandler" WoofTalkAR/Views/TranslationBubble.swift
      grep -q "UnlitMaterial" WoofTalkAR/Views/TranslationBubble.swift
    </automated>
  </verify>
  <action>
    Create `WoofTalkAR/Views/TranslationBubble.swift`:
    ```swift
    import RealityKit
    import SwiftUI
    import ARKit
    
    struct TranslationBubble {
        let entity: Entity
        let text: String
        let dismissHandler: (() -> Void)?
        
        init(text: String, dismissHandler: (() -> Void)? = nil) {
            self.text = text
            self.dismissHandler = dismissHandler
            
            // Create world anchor (will be positioned by ARCoordinator)
            let anchor = AnchorEntity(.world)
            
            // Create bubble background (rounded rectangle plane)
            let bubbleWidth: Float = 0.4  // 40cm wide at 2m
            let bubbleHeight: Float = 0.2 // 20cm tall
            let bubbleMesh = MeshResource.generatePlane(width: bubbleWidth, height: bubbleHeight)
            
            // Semi-transparent dark background
            var bubbleMaterial = UnlitMaterial()
            bubbleMaterial.color = .init(tint: UIColor(white: 0.1, alpha: 0.85))
            
            let bubbleEntity = ModelEntity(mesh: bubbleMesh, materials: [bubbleMaterial])
            
            // Create text overlay
            let textMesh = MeshResource.generateText(
                text,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.05), // ~24pt at 2m distance
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            
            var textMaterial = UnlitMaterial()
            textMaterial.color = .init(tint: .white)
            
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textEntity.position = [0, 0, 0.001] // Slightly in front of bubble
            bubbleEntity.addChild(textEntity)
            
            // Billboard: always face camera horizontally (Y axis rotation)
            var billboard = BillboardComponent()
            billboard.mode = .y
            bubbleEntity.components.set(billboard)
            
            // Enable tap gesture
            bubbleEntity.generateCollisionShapes(recursive: true)
            anchor.addChild(bubbleEntity)
            
            self.entity = anchor
            
            // Store reference for debugging
            bubbleEntity.name = "TranslationBubble_\(text.prefix(10))"
        }
        
        func add(to arView: ARView) {
            arView.scene.addAnchor(entity)
            arView.installGestures([.tap], for: entity)
        }
        
        func remove(from arView: ARView) {
            arView.scene.removeAnchor(entity)
        }
    }
    
    // Convenience extension for ARView
    extension ARView {
        func addTranslationBubble(_ bubble: TranslationBubble) {
            bubble.add(to: self)
        }
        
        func removeTranslationBubble(_ bubble: TranslationBubble) {
            bubble.remove(from: self)
        }
    }
    ```
  </action>
  <done>
    - TranslationBubble struct creates RealityKit entity hierarchy
    - Background: plane with semi-transparent dark material (alpha 0.85)
    - Text: MeshResource.generateText with white color, font size 0.05 (24pt at 2m)
    - BillboardComponent on Y axis (faces camera horizontally)
    - Tap gesture enabled via installGestures
    - Dismiss callback provided by caller
    - ARView extension methods for convenience
    - Entity anchored to world, position set externally
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Implement ARCoordinator for bubble lifecycle management</name>
  <files>WoofTalkAR/ARCoordinator.swift
  </files>
  <read_first>
    - Read: TranslationBubble.swift (entity creation API)
    - Reference: AR session camera transform extraction patterns
  </read_first>
  <acceptance_criteria>
    - ARCoordinator is an actor with shared singleton
    - setARView(_:) stores ARView reference
    - showBubble(text:duration:) creates bubble, positions it 2m in front of camera
    - Positioning: camera.transform.columns.3 (position) + forwardColumn (columns.2) * 2.0
    - Max 3 active bubbles (activeBubbles array, FIFO eviction)
    - Auto-dismiss after 10 seconds (configurable duration parameter)
    - dismissBubble(_:) removes bubble from ARView and array
    - dismissAllBubbles() clears all active bubbles
    - All UI updates on MainActor
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/ARCoordinator.swift
      grep -q "actor ARCoordinator" WoofTalkAR/ARCoordinator.swift
      grep -q "static let shared = ARCoordinator" WoofTalkAR/ARCoordinator.swift
      grep -q "func setARView" WoofTalkAR/ARCoordinator.swift
      grep -q "func showBubble" WoofTalkAR/ARCoordinator.swift
      grep -q "maxActiveBubbles = 3" WoofTalkAR/ARCoordinator.swift
      grep -q "autoDismissTime: TimeInterval = 10" WoofTalkAR/ARCoordinator.swift
      grep -q "cameraTransform.columns.2" WoofTalkAR/ARCoordinator.swift
      grep -q "columns.3" WoofTalkAR/ARCoordinator.swift
      grep -q "2.0" WoofTalkAR/ARCoordinator.swift
      grep -q "removeAnchor" WoofTalkAR/ARCoordinator.swift
    </automated>
  </verify>
  <action>
    Create `WoofTalkAR/ARCoordinator.swift`:
    ```swift
    import Foundation
    import RealityKit
    import ARKit
    
    actor ARCoordinator {
        static let shared = ARCoordinator()
        private var arView: ARView?
        private var activeBubbles: [TranslationBubble] = []
        private let maxActiveBubbles = 3
        private let autoDismissTime: TimeInterval = 10.0
        
        private init() {}
        
        func setARView(_ view: ARView) {
            self.arView = view
        }
        
        func showBubble(text: String, duration: TimeInterval? = nil) {
            guard let arView = arView else {
                print("ERROR: ARView not set in ARCoordinator")
                return
            }
            
            // Evict oldest bubble if at capacity (FIFO)
            if activeBubbles.count >= maxActiveBubbles {
                let oldest = activeBubbles.removeFirst()
                arView.removeTranslationBubble(oldest)
            }
            
            // Create bubble with dismiss callback
            let bubble = TranslationBubble(text: text) { [weak self] in
                self?.dismissBubble(bubble)
            }
            
            // Position 2m in front of camera
            if let cameraTransform = arView.session.currentFrame?.camera.transform {
                let forward = SIMD3<Float>(
                    cameraTransform.columns.2.x,
                    cameraTransform.columns.2.y,
                    cameraTransform.columns.2.z
                )
                let position = SIMD3<Float>(
                    cameraTransform.columns.3.x,
                    cameraTransform.columns.3.y,
                    cameraTransform.columns.3.z
                ) + forward * 2.0
                bubble.entity.position = position
            } else {
                // Fallback: position at world origin 2m in front if no camera
                bubble.entity.position = [0, 0, -2]
            }
            
            // Add to scene
            arView.addTranslationBubble(bubble)
            activeBubbles.append(bubble)
            
            // Auto-dismiss timer
            let dismissTime = duration ?? autoDismissTime
            Task {
                try await Task.sleep(nanoseconds: UInt64(dismissTime * 1_000_000_000))
                await dismissBubble(bubble)
            }
        }
        
        nonisolated func dismissBubble(_ bubble: TranslationBubble) {
            Task { @MainActor in
                guard let arView = arView,
                      let index = activeBubbles.firstIndex(where: { $0.entity === bubble.entity }) else { return }
                arView.removeTranslationBubble(bubble)
                activeBubbles.remove(at: index)
            }
        }
        
        func dismissAllBubbles() {
            Task { @MainActor in
                guard let arView = arView else { return }
                for bubble in activeBubbles {
                    arView.removeTranslationBubble(bubble)
                }
                activeBubbles.removeAll()
            }
        }
    }
    ```
  </action>
  <done>
    - ARCoordinator singleton with actor isolation
    - setARView(_:) stores ARView reference for later use
    - showBubble(text:duration:) creates bubble, positions 2m in front of camera
    - FIFO eviction when max 3 bubbles reached
    - Auto-dismiss after 10 seconds (configurable)
    - Tap dismiss callback wired through TranslationBubble init
    - dismissBubble and dismissAllBubbles cleanup methods
    - All scene updates on MainActor
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Integrate ARCoordinator into ContentView</name>
  <files>WoofTalkAR/ContentView.swift
  </files>
  <read_first>
    - Read: Existing ContentView.swift from 38-01
    - Read: ARCoordinator.swift (API)
    - Read: DetectionStateManager (if exists - may need to update from 38-02 tasks)
  </read_first>
  <acceptance_criteria>
    - ContentView publishes ARViewModel with ARView notification capture
    - ARContainerView posts .arViewReady notification with ARView reference on makeUIView
    - ARViewModel receives notification and calls ARCoordinator.shared.setARView(arView)
    - onAppear: starts AR session and detection (if applicable)
    - onDisappear: calls ARCoordinator.shared.dismissAllBubbles() and stops detection
    - ARCoordinator ready to receive showBubble calls
    - No compile errors, all imports correct
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/ContentView.swift
      grep -q "ARCoordinator.shared.setARView" WoofTalkAR/ContentView.swift
      grep -q "ARCoordinator.shared.dismissAllBubbles" WoofTalkAR/ContentView.swift
      grep -q "arViewReady" WoofTalkAR/ContentView.swift
      grep -q "NotificationCenter.*arViewReady" WoofTalkAR/ContentView.swift
      grep -q "ARContainerView" WoofTalkAR/ContentView.swift
    </automated>
  </verify>
  <action>
    Update `WoofTalkAR/ContentView.swift` with ARCoordinator integration:

    ```swift
    import SwiftUI
    import RealityKit
    import ARKit
    
    struct ContentView: View {
        @StateObject private var arViewModel = ARViewModel()
        @StateObject private var detectionManager = DetectionStateManager()
        
        var body: some View {
            ZStack {
                ARContainerView()
                    .edgesIgnoringSafeArea(.all)
                
                // Debug HUD (optional, keep from earlier)
                VStack {
                    Text("Detection: \(detectionManager.lastClassification?.className ?? "none")")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    if let confidence = detectionManager.lastClassification?.confidence {
                        ProgressView(value: confidence, total: 1.0)
                            .frame(width: 200)
                    }
                    Spacer()
                }
                .padding(.top, 50)
            }
            .onAppear {
                arViewModel.start()
                detectionManager.start()
            }
            .onDisappear {
                detectionManager.stop()
                arViewModel.stop()
            }
        }
    }
    
    class ARViewModel: ObservableObject {
        @Published var isARReady = false
        private let coordinator = ARCoordinator.shared
        
        func start() {
            // Listen for ARView ready notification from ARContainerView
            NotificationCenter.default.addObserver(
                forName: .arViewReady,
                object: nil,
                queue: .main
            ) { notification in
                if let arView = notification.object as? ARView {
                    self.coordinator.setARView(arView)
                    self.isARReady = true
                    print("ARCoordinator received ARView")
                }
            }
        }
        
        func stop() {
            coordinator.dismissAllBubbles()
        }
    }
    
    struct ARContainerView: UIViewRepresentable {
        func makeUIView(context: Context) -> ARView {
            let arView = ARView(frame: .zero)
            arView.session.run(WorldTrackingConfiguration())
            
            // Notify that ARView is ready for ARCoordinator
            NotificationCenter.default.post(name: .arViewReady, object: arView)
            
            return arView
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {}
    }
    
    extension Notification.Name {
        static let arViewReady = Notification.Name("ARViewReady")
    }
    
    // DetectionStateManager from 38-02a/02b - scaffold (will be connected to translation in 38-03b)
    class DetectionStateManager: ObservableObject {
        @Published var lastClassification: BarkClassification?
        private var detector: BarkDetector?
        
        init() {
            self.detector = BarkDetector.shared
            self.detector?.delegate = self
        }
        
        func start() {
            Task {
                do {
                    try await detector?.start()
                } catch {
                    print("Failed to start detector: \(error)")
                }
            }
        }
        
        func stop() {
            detector?.stop()
        }
    }
    
    extension DetectionStateManager: BarkDetectorDelegate {
        nonisolated func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification) {
            Task { @MainActor in
                self.lastClassification = classification
                // Translation will be triggered in 38-03b
            }
        }
    }
    ```
  </action>
  <done>
    - ContentView with ARViewModel capturing ARView and passing to ARCoordinator
    - ARContainerView posts .arViewReady notification on creation
    - ARViewModel.onAppear starts coordinator
    - onDisappear dismisses all bubbles
    - DetectionStateManager scaffold in place (unconnected for now)
    - All imports and compile issues resolved
  </done>
</task>

</tasks>

<verification>
Wave 3a - Translation Bubble verification:

**1. TranslationBubble.swift:**
   - `test -f WoofTalkAR/Views/TranslationBubble.swift`
   - `grep -q "AnchorEntity" WoofTalkAR/Views/TranslationBubble.swift`
   - `grep -q "generateText" WoofTalkAR/Views/TranslationBubble.swift`
   - `grep -q "BillboardComponent" WoofTalkAR/Views/TranslationBubble.swift`
   - `grep -q "UnlitMaterial" WoofTalkAR/Views/TranslationBubble.swift`
   - `grep -q "installGestures" WoofTalkAR/Views/TranslationBubble.swift`

**2. ARCoordinator.swift:**
   - `test -f WoofTalkAR/ARCoordinator.swift`
   - `grep -q "actor ARCoordinator" WoofTalkAR/ARCoordinator.swift`
   - `grep -q "maxActiveBubbles = 3" WoofTalkAR/ARCoordinator.swift`
   - `grep -q "autoDismissTime: TimeInterval = 10" WoofTalkAR/ARCoordinator.swift`
   - `grep -q "cameraTransform.columns.2" WoofTalkAR/ARCoordinator.swift`
   - `grep -q "forward.*2.0" WoofTalkAR/ARCoordinator.swift`

**3. ContentView.swift integration:**
   - `test -f WoofTalkAR/ContentView.swift`
   - `grep -q "ARCoordinator.shared.setARView" WoofTalkAR/ContentView.swift`
   - `grep -q "dismissAllBubbles" WoofTalkAR/ContentView.swift`
   - `grep -q "arViewReady" WoofTalkAR/ContentView.swift`

**4. Build verification:**
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

All checks must pass before Wave 3b (API + spatial audio integration).

**Note:** Bubble rendering may not be visible in simulator, but code must be correct.
</verification>

<success_criteria>
**AR-04 (Translation Bubble) complete:**

✅ TranslationBubble entity with 2m world anchor
✅ Billboard effect (faces camera horizontally)
✅ Readable text (font size 0.05 = ~24pt at 2m)
✅ Semi-transparent dark background (alpha 0.85)
✅ Tap-to-dismiss gesture installed
✅ Auto-dismiss 10 seconds
✅ Max 3 concurrent bubbles with FIFO eviction
✅ ARCoordinator manages lifecycle

**Exit criteria:** Bubble visible and functional in AR scene. Ready for API integration (AR-05) and spatial audio (AR-06) in 38-03b.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-03a-SUMMARY.md` summarizing:
- TranslationBubble design (geometry, materials, billboard, gestures)
- ARCoordinator positioning logic (2m forward from camera)
- Bubble lifecycle (max 3, 10s auto-dismiss, tap dismiss)
- ContentView integration (ARView notification pattern)
- Files created/modified
- Dependencies on Wave 1 & 2 confirmed
- Manual testing notes (if any)
</output>
