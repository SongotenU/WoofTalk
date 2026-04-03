---
phase: 38-ar-foundation
plan: 03b
type: execute
wave: 3
depends_on:
  - "38-03a"
files_modified:
  - WoofTalkAR/Services/TranslationService.swift
  - WoofTalkAR/Services/SpatialAudioController.swift
  - WoofTalkAR/ContentView.swift
requirements:
  - AR-05
  - AR-06
autonomous: true
must_haves:
  truths:
    - "TranslationService calls Edge Function /v1/translate with Supabase auth"
    - "Translation bubble appears within 2 seconds of bark detection"
    - "Spatial audio plays from bubble position with HRTF effect"
    - "Handler maps translation response to human_text for bubble display"
    - "Error handling for auth failures (401) and rate limits (429)"
    - "Full pipeline: bark detection → translate → bubble + audio"
  artifacts:
    - path: "WoofTalkAR/Services/TranslationService.swift"
      provides: "Supabase Edge Function client with auth and error handling"
      min_lines: 60
      contains:
        - "SupabaseClient"
        - "functions.invoke"
        - "TranslationRequest"
        - "TranslationRecord"
        - "authenticationRequired"
        - "rateLimitExceeded"
    - path: "WoofTalkAR/Services/SpatialAudioController.swift"
      provides: "AVAudioEnvironmentNode spatial audio with position anchoring"
      min_lines: 80
      contains:
        - "AVAudioEngine"
        - "AVAudioEnvironmentNode"
        - "renderingAlgorithm = HRTF"
        - "playAudio(at:)"
        - "setListenerPosition"
        - "updateListenerFromCamera"
    - path: "WoofTalkAR/ContentView.swift"
      provides: "Final integration: detection → translate → bubble → audio"
      contains:
        - "TranslationService.shared.translate"
        - "ARCoordinator.shared.showBubble"
        - "SpatialAudioController.shared.playAudio"
  key_links:
    - from: "BarkDetector.swift"
      to: "TranslationService.swift"
      via: "detected bark → translate call"
      pattern: "TranslationService\\.shared\\.translate"
    - from: "TranslationService.swift"
      to: "ARCoordinator.swift"
      via: "on success → showBubble(record.human_text)"
      pattern: "ARCoordinator\\.shared\\.showBubble"
    - from: "ARCoordinator.swift"
      to: "SpatialAudioController.swift"
      via: "playAudio(at:bubblePosition)"
      pattern: "SpatialAudioController"
    - from: "ContentView.swift"
      to: "ARCoordinator.swift"
      via: "setARView"
      pattern: "coordinator\\.setARView"

---

<objective>
Complete the AR experience by integrating Edge Function translation API and spatial audio, wiring full end-to-end pipeline.

**Purpose:** Connect dog bark detection to translation service and spatial audio so that when a bark is detected:
1. Edge Function is called with Supabase auth
2. Translation result displayed in bubble at 2m position
3. Spatial audio plays from bubble location

**Output:** Fully functional AR translation loop:
- TranslationService (Supabase Edge Function client)
- SpatialAudioController (HRTF 3D audio)
- ContentView pipelines all components together
- End-to-end latency <2 seconds
- Manual validation completed

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

# Translation & Audio Integration Context

**From CONTEXT.md:**
- Edge Function `/v1/translate` expects: human_text, animal_text, source_language, target_language
- Auth: Supabase session token (auto-attached by client)
- Spatial audio: AVAudioEnvironmentNode anchored to bubble position
- Performance: 2 seconds from detection to bubble appearance
- Error handling: auth expired → login sheet, rate limit → retry button, etc.

**From RESEARCH.md:**
- TranslationService: Supabase Swift SDK, function invocation
- SpatialAudioController: 3D audio with listener following camera
- Bubble position used for audio source position

**From Edge Functions (existing):**
- POST /v1/translate
- Requires authenticated session
- Returns TranslationRecord with human_text (translation) and metadata
- Error codes: 400, 401, 429, 500

**Pipeline (from ARCHITECTURE.md):**
BarkDetector detection → TranslationService.translate() → ARCoordinator.showBubble() → SpatialAudioController.playAudio(at: bubblePosition)

</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Implement TranslationService with Supabase Edge Function</name>
  <files>WoofTalkAR/Services/TranslationService.swift
  </files>
  <read_first>
    - Read: supabase/functions/translate/index.ts (to match request/response)
    - Reference: Supabase Swift SDK documentation (v2)
  </read_first>
  <acceptance_criteria>
    - TranslationService singleton with translate() method
    - translate() accepts humanText, animalText, sourceLanguage, targetLanguage, confidence
    - Request body sends TranslationRequest (codable) with those fields
    - SupabaseClient configured with SUPABASE_URL and SUPABASE_ANON_KEY from environment
    - Invokes Edge Function using supabase.functions.invoke("translate", body:request, method:"POST")
    - Completion handler returns Result<TranslationRecord, TranslationError>
    - Error handling maps:
      - 401 → .authenticationRequired
      - 429 → .rateLimitExceeded
      - 400 → .invalidInput
      - others → .serverError
    - TranslationRecord decodes from JSON response (id, user_id, created_at, etc.)
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/TranslationService.swift
      grep -q "actor TranslationService" WoofTalkAR/Services/TranslationService.swift
      grep -q "static let shared = TranslationService" WoofTalkAR/Services/TranslationService.swift
      grep -q "func translate(" WoofTalkAR/Services/TranslationService.swift
      grep -q "SupabaseClient" WoofTalkAR/Services/TranslationService.swift
      grep -q "functions.invoke" WoofTalkAR/Services/TranslationService.swift
      grep -q "struct TranslationRequest" WoofTalkAR/Services/TranslationService.swift
      grep -q "struct TranslationRecord" WoofTalkAR/Services/TranslationService.swift
      grep -q "Result<TranslationRecord, TranslationError>" WoofTalkAR/Services/TranslationService.swift
      grep -q "authenticationRequired" WoofTalkAR/Services/TranslationService.swift
      grep -q "rateLimitExceeded" WoofTalkAR/Services/TranslationService.swift
    </automated>
  </verify>
  <action>
    Create `WoofTalkAR/Services/TranslationService.swift`:
    ```swift
    import Foundation
    import Supabase
    
    struct TranslationRequest: Codable {
        let human_text: String
        let animal_text: String
        let source_language: String
        let target_language: String
        let confidence: Float?
        let quality_score: Float?
        
        init(humanText: String, animalText: String, sourceLanguage: String = "human", targetLanguage: String = "dog", confidence: Float? = nil, qualityScore: Float? = nil) {
            self.human_text = humanText
            self.animal_text = animalText
            self.source_language = sourceLanguage
            self.target_language = targetLanguage
            self.confidence = confidence
            self.quality_score = qualityScore
        }
    }
    
    struct TranslationRecord: Codable, Identifiable {
        let id: String
        let user_id: String
        let human_text: String
        let animal_text: String
        let source_language: String
        let target_language: String
        let confidence: Float?
        let quality_score: Float?
        let created_at: String
        let updated_at: String?
    }
    
    enum TranslationError: LocalizedError {
        case authenticationRequired
        case rateLimitExceeded
        case invalidInput(String)
        case serverError(String)
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .authenticationRequired: return "Authentication required. Please log in."
            case .rateLimitExceeded: return "Rate limit exceeded. Please wait."
            case .invalidInput(let msg): return "Invalid input: \(msg)"
            case .serverError(let msg): return "Server error: \(msg)"
            case .unknown(let err): return err.localizedDescription
            }
        }
    }
    
    actor TranslationService {
        static let shared = TranslationService()
        private var supabase: SupabaseClient?
        
        private init() {
            setupSupabase()
        }
        
        private func setupSupabase() {
            guard let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""),
                  let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""),
                  !url.absoluteString.isEmpty && !key.isEmpty else {
                print("WARNING: Supabase credentials not set - translation will fail")
                return
            }
            
            supabase = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key
            )
        }
        
        func translate(
            humanText: String,
            animalText: String,
            sourceLanguage: String = "human",
            targetLanguage: String = "dog",
            confidence: Float? = nil,
            completion: @escaping @Sendable (Result<TranslationRecord, TranslationError>) -> Void
        ) {
            guard let supabase = supabase else {
                completion(.failure(.authenticationRequired))
                return
            }
            
            let request = TranslationRequest(
                humanText: humanText,
                animalText: animalText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                confidence: confidence,
                qualityScore: nil
            )
            
            Task {
                do {
                    let response = try await supabase.functions.invoke(
                        "translate",
                        body: request,
                        method: "POST"
                    )
                    
                    guard let data = response.data else {
                        throw TranslationError.serverError("Empty response")
                    }
                    
                    let record = try JSONDecoder().decode(TranslationRecord.self, from: data)
                    completion(.success(record))
                } catch let error as CustomNSError {
                    if error.code == 401 {
                        completion(.failure(.authenticationRequired))
                    } else if error.code == 429 {
                        completion(.failure(.rateLimitExceeded))
                    } else {
                        completion(.failure(.serverError(error.localizedDescription)))
                    }
                } catch {
                    completion(.failure(.unknown(error)))
                }
            }
        }
    }
    ```
  </action>
  <done>
    - TranslationService singleton with Supabase client initialization
    - translate() method sends POST to /v1/translate with proper request body
    - Auth token auto-attached by Supabase client (from session)
    - Error handling maps HTTP codes: 401, 429, others
    - TranslationRecord model decodes response
    - Completion handler called asynchronously
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Implement SpatialAudioController with HRTF</name>
  <files>WoofTalkAR/Services/SpatialAudioController.swift
  </files>
  <read_first>
    - Reference: AVAudioEnvironmentNode Apple documentation
    - Reference: Spatial audio positioning patterns (listener vs source)
  </read_first>
  <acceptance_criteria>
    - SpatialAudioController singleton actor with shared instance
    - AVAudioEngine with AVAudioEnvironmentNode (renderingAlgorithm = .HRTF)
    - start() initializes engine and environment node
    - playAudio(at:position:) attaches AVAudioPlayerNode to environment at specified SIMD3<Float> position
    - playAudio accepts optional soundFile name (uses placeholder tone if nil)
    - Listener position updates via setListenerPosition(_:) or updateListenerFromCamera(_:)
    - updateListenerFromCamera extracts camera position and orientation from transform
    - Player node auto-detached and removed after playback completes
    - Thread-safe actor isolation
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "actor SpatialAudioController" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "static let shared = SpatialAudioController" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "AVAudioEngine" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "AVAudioEnvironmentNode" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "renderingAlgorithm = .HRTF" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "func playAudio(at:" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "setListenerPosition" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "updateListenerFromCamera" WoofTalkAR/Services/SpatialAudioController.swift
      grep -q "environment.attach(playerNode)" WoofTalkAR/Services/SpatialAudioController.swift
    </automated>
  </verify>
  <action>
    Create `WoofTalkAR/Services/SpatialAudioController.swift`:
    ```swift
    import Foundation
    import AVFoundation
    import RealityKit
    
    actor SpatialAudioController {
        static let shared = SpatialAudioController()
        private var audioEngine: AVAudioEngine?
        private var environmentNode: AVAudioEnvironmentNode?
        private var activeNodes: [AVAudioNode] = []
        
        private init() {
            setupAudioEngine()
        }
        
        private func setupAudioEngine() {
            let engine = AVAudioEngine()
            let environment = AVAudioEnvironmentNode()
            
            environment.renderingAlgorithm = .HRTF
            environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
            
            engine.attach(environment)
            engine.connect(engine.mainMixerNode, to: environment, format: nil)
            engine.connect(environment, to: engine.outputNode, format: nil)
            
            self.audioEngine = engine
            self.environmentNode = environment
            
            do {
                try engine.start()
                print("SpatialAudioController: engine started")
            } catch {
                print("ERROR: Failed to start audio engine: \(error)")
            }
        }
        
        func playAudio(at position: SIMD3<Float>, soundFile: String? = nil, completion: (() -> Void)? = nil) {
            guard let engine = audioEngine,
                  let environment = environmentNode else {
                print("ERROR: Audio engine not ready")
                completion?()
                return
            }
            
            // Load audio file or generate placeholder tone
            let audioFile: AVAudioFile?
            if let soundFile = soundFile,
               let url = Bundle.main.url(forResource: soundFile, withExtension: "mp3") {
                audioFile = try? AVAudioFile(forReading: url)
            } else {
                audioFile = generatePlaceholderTone()
            }
            
            guard let file = audioFile else {
                print("ERROR: Could not load audio file")
                completion?()
                return
            }
            
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            
            // Convert SIMD3<Float> to AVAudio3DPoint
            let audioPosition = AVAudio3DPoint(
                x: Double(position.x),
                y: Double(position.y),
                z: Double(position.z)
            )
            
            environment.attach(playerNode)
            environment.setPosition(audioPosition, of: playerNode)
            
            // Schedule playback
            playerNode.scheduleFile(file, at: nil) {
                // Cleanup
                engine.detach(playerNode)
                environment.detach(playerNode)
                if let idx = self.activeNodes.firstIndex(where: { $0 === playerNode }) {
                    self.activeNodes.remove(at: idx)
                }
                completion?()
            }
            
            playerNode.play()
            activeNodes.append(playerNode)
        }
        
        func setListenerPosition(_ position: SIMD3<Float>) {
            environmentNode?.listenerPosition = AVAudio3DPoint(
                x: Double(position.x),
                y: Double(position.y),
                z: Double(position.z)
            )
        }
        
        func updateListenerFromCamera(_ cameraTransform: simd_float4x4) {
            // Camera position
            let pos = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            setListenerPosition(pos)
            
            // Camera orientation (forward and up vectors)
            let forward = SIMD3<Float>(
                cameraTransform.columns.2.x,
                cameraTransform.columns.2.y,
                cameraTransform.columns.2.z
            )
            let up = SIMD3<Float>(
                cameraTransform.columns.1.x,
                cameraTransform.columns.1.y,
                cameraTransform.columns.1.z
            )
            environmentNode?.listenerVectorOrientation = AVAudio3DRotation(
                forward: AVAudio3DPoint(x: Double(forward.x), y: Double(forward.y), z: Double(forward.z)),
                up: AVAudio3DPoint(x: Double(up.x), y: Double(up.y), z: Double(up.z))
            )
        }
        
        private func generatePlaceholderTone() -> AVAudioFile? {
            // Generate a simple 440Hz sine wave as placeholder for testing
            let sampleRate: Double = 48000
            let duration: Double = 1.0
            let frequency: Double = 440.0
            
            let frameCount = AVAudioFrameCount(sampleRate * duration)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            buffer.frameLength = frameCount
            
            let theta = 2.0 * Double.pi * frequency / sampleRate
            for frame in 0..<Int(frameCount) {
                let sample = sin(theta * Double(frame))
                buffer.floatChannelData?.pointee[frame] = Float(sample) * 0.5
            }
            
            // Write to temporary file and return
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("placeholder.wav")
            try? AVAudioFile(forWriting: tempURL, settings: format.settings).write(from: buffer)
            
            return try? AVAudioFile(forReading: tempURL)
        }
    }
    ```
  </action>
  <done>
    - SpatialAudioController singleton with actor isolation
    - AVAudioEngine + AVAudioEnvironmentNode configured with HRTF rendering
    - playAudio(at:position:) attaches player to specified world position
    - Listener position and orientation updateable from camera transform
    - Placeholder tone generation for testing without audio assets
    - Auto-cleanup of player nodes after playback
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Connect full pipeline and validate end-to-end</name>
  <files>WoofTalkAR/ContentView.swift
  </files>
  <read_first>
    - Read: BarkDetector.swift, TranslationService.swift, ARCoordinator.swift, SpatialAudioController.swift
    - Read: existing ContentView.swift from 38-03a (with ARCoordinator integration)
  </read_first>
  <acceptance_criteria>
    - DetectionStateManager.barkDetector(_:didDetect:) calls TranslationService.shared.translate()
    - translate() called with animalText = classification.className, confidence = classification.confidence
    - On translation success: ARCoordinator.shared.showBubble(text: record.human_text)
    - On bubble shown: SpatialAudioController.shared.playAudio(at: bubblePosition)
    - Full end-to-end flow: bark detected → translate → bubble appears → audio plays
    - End-to-end latency <2 seconds (bark → bubble appearance)
    - Project builds successfully on Vision Pro simulator
    - Manual validation confirms:
      - Microphone permission granted
      - Bark detection triggers (console: "Detected: bark")
      - TranslationService.translate called
      - Bubble appears within 2 seconds at 2m in front
      - Bubble readable, billboarded, dismissible via tap
      - Spatial audio plays from bubble direction
      - No crashes in 5-minute run
    - All verification commands pass
  </acceptance_criteria>
  <verify>
    <automated>
      # Build verification
      xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build 2>&1 | tee build.log
      grep -q "BUILD SUCCEEDED" build.log
      # Pipeline code checks
      test -f WoofTalkAR/ContentView.swift
      grep -q "TranslationService.shared.translate" WoofTalkAR/ContentView.swift
      grep -q "ARCoordinator.shared.showBubble" WoofTalkAR/ContentView.swift
      grep -q "SpatialAudioController.shared.playAudio" WoofTalkAR/ContentView.swift
      grep -q "barkDetector(_:didDetect:)" WoofTalkAR/ContentView.swift
      # Component files exist
      test -f WoofTalkAR/Services/TranslationService.swift
      test -f WoofTalkAR/Services/SpatialAudioController.swift
      # Manual test required - acceptance criteria include observable outcomes
      echo "Build and code verification passed. Manual test required for full validation."
    </automated>
  </verify>
  <action>
    Update `WoofTalkAR/ContentView.swift` to wire the full translation pipeline:

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
                
                // Debug HUD
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
        private var arView: ARView?
        
        func start() {
            NotificationCenter.default.addObserver(
                forName: .arViewReady,
                object: nil,
                queue: .main
            ) { notification in
                if let view = notification.object as? ARView {
                    self.arView = view
                    self.coordinator.setARView(view)
                    self.isARReady = true
                    print("ARCoordinator received ARView")
                }
            }
        }
        
        func stop() {
            coordinator.dismissAllBubbles()
            arView = nil
        }
    }
    
    struct ARContainerView: UIViewRepresentable {
        func makeUIView(context: Context) -> ARView {
            let arView = ARView(frame: .zero)
            arView.session.run(WorldTrackingConfiguration())
            NotificationCenter.default.post(name: .arViewReady, object: arView)
            return arView
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {}
    }
    
    // MARK: - DetectionStateManager with Translation Trigger
    
    class DetectionStateManager: ObservableObject {
        @Published var lastClassification: BarkClassification?
        private var detector: BarkDetector?
        private let translationService = TranslationService.shared
        private let coordinator = ARCoordinator.shared
        private let spatialAudio = SpatialAudioController.shared
        
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
        
        private func handleBarkDetection(_ classification: BarkClassification) {
            Task { @MainActor in
                self.lastClassification = classification
                print("Detected: \(classification.className) confidence: \(classification.confidence)")
                
                // Call translation Edge Function
                translationService.translate(
                    humanText: "[Translated from \(classification.className)]",
                    animalText: classification.className,
                    confidence: classification.confidence
                ) { result in
                    switch result {
                    case .success(let record):
                        print("Translation received: \(record.human_text)")
                        // Show bubble with translation
                        self.coordinator.showBubble(text: record.human_text)
                        
                        // Play spatial audio from bubble position (approximate 2m in front)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let arView = self.coordinator.arView,
                               let cameraTransform = arView.session.currentFrame?.camera.transform {
                                let forward = SIMD3<Float>(
                                    cameraTransform.columns.2.x,
                                    cameraTransform.columns.2.y,
                                    cameraTransform.columns.2.z
                                )
                                let cameraPos = SIMD3<Float>(
                                    cameraTransform.columns.3.x,
                                    cameraTransform.columns.3.y,
                                    cameraTransform.columns.3.z
                                )
                                let bubblePosition = cameraPos + forward * 2.0
                                self.spatialAudio.playAudio(at: bubblePosition, soundFile: nil)
                            }
                        }
                        
                    case .failure(let error):
                        print("Translation error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    extension DetectionStateManager: BarkDetectorDelegate {
        nonisolated func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification) {
            handleBarkDetection(classification)
        }
    }
    
    // MARK: - Notifications
    
    extension Notification.Name {
        static let arViewReady = Notification.Name("ARViewReady")
    }
    ```
  </action>
  <done>
    - Full pipeline connected: BarkDetector → TranslationService → ARCoordinator → SpatialAudioController
    - Translation triggered on each dog bark detection
    - Bubble appears within 2 seconds (Edge Function RTT + rendering)
    - Spatial audio plays from approximate bubble position (2m in front)
    - Error handling logs translation failures
    - All async calls properly dispatched
    - Build succeeds on Vision Pro simulator
    - Manual validation completed and documented
  </done>
</task>

</tasks>

<verification>
Wave 3b - Full Integration verification:

**1. TranslationService implementation:**
   - `test -f WoofTalkAR/Services/TranslationService.swift`
   - `grep -q "functions.invoke" WoofTalkAR/Services/TranslationService.swift`
   - `grep -q "TranslationRequest" WoofTalkAR/Services/TranslationService.swift`
   - `grep -q "TranslationRecord" WoofTalkAR/Services/TranslationService.swift`
   - `grep -q "authenticationRequired" WoofTalkAR/Services/TranslationService.swift`
   - `grep -q "rateLimitExceeded" WoofTalkAR/Services/TranslationService.swift`

**2. SpatialAudioController:**
   - `test -f WoofTalkAR/Services/SpatialAudioController.swift`
   - `grep -q "AVAudioEnvironmentNode" WoofTalkAR/Services/SpatialAudioController.swift`
   - `grep -q "renderingAlgorithm = .HRTF" WoofTalkAR/Services/SpatialAudioController.swift`
   - `grep -q "playAudio(at:" WoofTalkAR/Services/SpatialAudioController.swift`
   - `grep -q "updateListenerFromCamera" WoofTalkAR/Services/SpatialAudioController.swift`

**3. Full pipeline in ContentView:**
   - `grep -q "TranslationService.shared.translate" WoofTalkAR/ContentView.swift`
   - `grep -q "ARCoordinator.shared.showBubble" WoofTalkAR/ContentView.swift`
   - `grep -q "SpatialAudioController.shared.playAudio" WoofTalkAR/ContentView.swift`
   - `grep -q "barkDetector(_:didDetect:)" WoofTalkAR/ContentView.swift`

**4. Build verification:**
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

**5. Manual end-to-end smoke test (required):**
   - Launch app, grant microphone permission
   - Bark detection triggered (console shows "Detected: bark")
   - TranslationService.translate called
   - Edge Function returns successfully
   - Bubble appears within 2 seconds at 2m
   - Bubble readable, billboarded, dismissible via tap
   - Spatial audio plays from bubble direction
   - No crashes during extended run (5+ minutes)
   - AR session stable

**Note:** This is the final Wave 3 task completing Phase 38. All 6 requirements (AR-01 through AR-06) must be satisfied after this verification.

**Success Criteria by requirement:**
- AR-01: Project builds, entitlements configured, Supabase added (38-01a + 38-01b)
- AR-02: Dog bark classifier integrated (placeholder model, pipeline complete) (38-02b)
- AR-03: Real-time audio pipeline + ARKit session (38-02a + 38-02b)
- AR-04: Translation bubble (38-03a)
- AR-05: Edge Function integration (38-03b)
- AR-06: Spatial audio (38-03b)

</verification>

<success_criteria>
**Phase 38: AR Foundation - COMPLETE**

✅ AR-01: Vision Pro project setup with RealityKit, ARKit, entitlements, Supabase
✅ AR-02: Core ML dog bark classifier integrated (placeholder model, pipeline ready for real model)
✅ AR-03: Real-time camera passthrough with concurrent audio processing
✅ AR-04: Translation bubble at fixed 2m, billboarded, readable, dismissible
✅ AR-05: Edge Function API integration with auth and error handling
✅ AR-06: Spatial audio anchored to bubble position with HRTF

**Performance:**
- End-to-end latency: <2 seconds (typically)
- AR session stable (target 90 FPS)
- No memory leaks in extended run
- App runs without crashes

**Exit:** Phase 38 complete. Phase 39 (AR Spatial UX) can begin. All infrastructure in place for production improvements: trained model, gaze-based anchoring, performance tuning.

**Deliverables:**
- Complete Xcode visionOS project
- Dog bark detection pipeline
- Translation bubble UI
- Spatial audio system
- Edge Function integration
- Manual test results documented

</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-03b-SUMMARY.md` summarizing:
- TranslationService implementation (Supabase, Edge Function, error handling)
- SpatialAudioController (HRTF, listener tracking)
- ContentView pipeline wiring
- Manual test results (end-to-end flow, latency, issues)
- All 6 AR requirements status
- Files created/modified
- Dependencies on all prior Wave 1, 2, 3a tasks
- Known limitations (placeholder model, basic bubble design)
- Recommendations for Phase 39 enhancements
</output>
