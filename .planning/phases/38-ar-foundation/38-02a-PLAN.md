---
phase: 38-ar-foundation
plan: 02a
type: execute
wave: 2
depends_on:
  - "38-01a"
  - "38-01b"
files_modified:
  - WoofTalkAR/Services/AudioRecorder.swift
  - WoofTalkAR/Services/BarkDetector.swift
  - WoofTalkAR/Models/BarkClassification.swift
requirements:
  - AR-03
autonomous: true
must_haves:
  truths:
    - "Audio capture pipeline processes continuous buffers"
    - "BarkDetector receives audio buffers via NotificationCenter"
    - "AudioRecorder runs on background thread with actor isolation"
    - "20ms buffer size (1024 samples @ 48kHz) configured"
    - "Detection system ready to receive Core ML model"
  artifacts:
    - path: "WoofTalkAR/Services/AudioRecorder.swift"
      provides: "Continuous audio capture with AVAudioEngine"
      min_lines: 60
      contains:
        - "AVAudioEngine"
        - "installTap"
        - "bufferSize: AVAudioFrameCount = 1024"
        - "sampleRate: Double = 48000"
        - "actor AudioRecorder"
    - path: "WoofTalkAR/Services/BarkDetector.swift"
      provides: "Vision framework integration skeleton (model loading TBD)"
      min_lines: 30
      contains:
        - "VNCoreMLRequest"
        - "BarkDetector"
        - "AudioRecorder.shared"
    - path: "WoofTalkAR/Models/BarkClassification.swift"
      provides: "Result type for classification with confidence threshold"
      contains:
        - "BarkClassification"
        - "isDogSound: Bool"
        - "className: String"
        - "confidence: Float"
  key_links:
    - from: "AudioRecorder.swift"
      to: "BarkDetector.swift"
      via: "NotificationCenter audio buffer broadcast"
      pattern: "NotificationCenter.*audioBufferCaptured"
    - from: "BarkDetector.swift"
      to: "AudioRecorder.swift"
      via: "uses AudioRecorder.shared"
      pattern: "AudioRecorder\\.shared"
    - from: "BarkClassification.swift"
      to: "BarkDetector.swift"
      via: "return type of classification"
      pattern: "BarkClassification"

---

<objective>
Implement the audio capture pipeline and BarkDetector skeleton to prepare for Core ML integration.

**Purpose:** Establish continuous audio processing infrastructure that feeds dog bark detection. This phase sets up the audio pipeline and detector structure; Core ML model integration comes in 38-02b.

**Output:** Working audio capture system:
- AudioRecorder with AVAudioEngine (20ms buffers, 48kHz, mono)
- BarkDetector ready to receive audio buffers
- BarkClassification model for results
- NotificationCenter bridge between audio and detection

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

# Audio Pipeline Context

**From RESEARCH.md:**
- Buffer size: 20ms (1024 samples @ 48kHz = ~21ms, acceptable)
- Audio format: 48kHz, mono, Float32
- Use AVAudioEngine with input node tap
- Process on background queue (actor isolation)
- Continuous capture with overlapping buffers

**From STACK.md:**
- Vision framework with Core ML for classification
- Model will be integrated in next task (38-02b)
- Real-time processing constraint: <100ms inference latency

**Architecture:**
- AudioRecorder: captures buffers → NotificationCenter
- BarkDetector: listens → processes → calls delegate
- BarkClassification: result type with isDogSound property

**Note:** This plan focuses on audio infrastructure; model integration is separate 38-02b.

</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Implement AudioRecorder with 20ms buffer capture</name>
  <files>WoofTalkAR/Services/AudioRecorder.swift
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for AVAudioEngine configuration details
  </read_first>
  <acceptance_criteria>
    - AudioRecorder is an actor with shared singleton
    - AVAudioEngine configured for 48kHz, mono, Float32
    - Buffer size exactly 1024 samples (AvaudioFrameCount)
    - start() method initializes engine and installs tap
    - stop() method removes tap and stops engine
    - Audio buffers sent via NotificationCenter with name .audioBufferCaptured
    - UserInfo contains "buffer" key with AVAudioPCMBuffer
    - Actor isolation ensures thread safety
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/AudioRecorder.swift
      grep -q "actor AudioRecorder" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "static let shared = AudioRecorder" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "AVAudioEngine" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "installTap" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "bufferSize: AVAudioFrameCount = 1024" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "sampleRate: Double = 48000" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "NotificationCenter.*audioBufferCaptured" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "func start() throws" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "func stop()" WoofTalkAR/Services/AudioRecorder.swift
    </automated>
  </verify>
  <action>
    Create `WoofTalkAR/Services/AudioRecorder.swift`:
    ```swift
    import Foundation
    import AVFoundation
    
    protocol AudioRecorderDelegate: AnyObject {
        func audioRecorder(_ recorder: AudioRecorder, didCapture buffer: AVAudioPCMBuffer)
    }

    extension Notification.Name {
        static let audioBufferCaptured = Notification.Name("AudioBufferCaptured")
    }

    actor AudioRecorder {
        static let shared = AudioRecorder()
        private var audioEngine: AVAudioEngine?
        private var inputNode: AVAudioInputNode?
        private let sampleRate: Double = 48000
        private let bufferSize: AVAudioFrameCount = 1024
        private var isRunning = false
        
        weak var delegate: AudioRecorderDelegate?
        
        private init() {}
        
        func start() throws {
            guard !isRunning else { return }
            
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            )!
            
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { 
                [weak self] buffer, time in
                Task { await self?.processBuffer(buffer) }
            }
            
            try audioEngine.start()
            self.audioEngine = audioEngine
            self.inputNode = inputNode
            self.isRunning = true
            
            print("AudioRecorder started with bufferSize=\(bufferSize) @ \(sampleRate)Hz")
        }
        
        func stop() {
            inputNode?.removeTap(onBus: 0)
            audioEngine?.stop()
            audioEngine = nil
            inputNode = nil
            isRunning = false
        }
        
        nonisolated private func processBuffer(_ buffer: AVAudioPCMBuffer) {
            // Broadcast buffer via NotificationCenter for loose coupling
            NotificationCenter.default.post(
                name: .audioBufferCaptured,
                object: self,
                userInfo: ["buffer": buffer]
            )
        }
    }
    ```
  </action>
  <done>
    - AudioRecorder actor with singleton pattern
    - AVAudioEngine configured: 48kHz, mono, Float32, 1024 sample buffer
    - start() and stop() methods functional
    - Audio buffers broadcast via NotificationCenter
    - Thread-safe actor isolation
    - Console logging for debugging
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Create BarkDetector skeleton and BarkClassification model</name>
  <files>WoofTalkAR/Services/BarkDetector.swift, WoofTalkAR/Models/BarkClassification.swift
  </files>
  <read_first>
    - Reference: AudioRecorder.swift (to understand notification pattern)
  </read_first>
  <acceptance_criteria>
    - BarkDetector is an actor with shared singleton
    - Observes .audioBufferCaptured notifications
    - Has placeholder VNCoreMLRequest property (nil until model loaded)
    - start() method triggers AudioRecorder.start()
    - stop() method stops recording
    - BarkClassification struct has: className, confidence, timestamp, isDogSound computed property
    - Delegate protocol BarkDetectorDelegate defined with barkDetector(_:didDetect:)
    - Current implementation logs receipt of buffers but does not classify yet
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/BarkDetector.swift
      test -f WoofTalkAR/Models/BarkClassification.swift
      grep -q "actor BarkDetector" WoofTalkAR/Services/BarkDetector.swift
      grep -q "static let shared = BarkDetector" WoofTalkAR/Services/BarkDetector.swift
      grep -q "NotificationCenter.*audioBufferCaptured" WoofTalkAR/Services/BarkDetector.swift
      grep -q "BarkClassification" WoofTalkAR/Models/BarkClassification.swift
      grep -q "isDogSound: Bool" WoofTalkAR/Models/BarkClassification.swift
      grep -q "className: String" WoofTalkAR/Models/BarkClassification.swift
      grep -q "confidence: Float" WoofTalkAR/Models/BarkClassification.swift
      grep -q "func start() throws" WoofTalkAR/Services/BarkDetector.swift
      grep -q "func stop()" WoofTalkAR/Services/BarkDetector.swift
    </automated>
  </verify>
  <action>
    1. Create `WoofTalkAR/Models/BarkClassification.swift`:
       ```swift
       import Foundation
       
       struct BarkClassification: Identifiable, Codable {
           let id = UUID()
           let timestamp: Date
           let className: String  // "bark", "howl", "whine", "silence"
           let confidence: Float
           
           var isDogSound: Bool {
               className != "silence" && confidence > 0.7
           }
       }
       ```
    
    2. Create `WoofTalkAR/Services/BarkDetector.swift` (skeleton with audio pipeline but no model yet):
       ```swift
       import Foundation
       import Vision
       import CoreML
       import AVFoundation
       
       actor BarkDetector {
           static let shared = BarkDetector()
           private var audioRecorder: AudioRecorder?
           private var classificationRequest: VNCoreMLRequest?
           private let confidenceThreshold: Float = 0.7
           private let debounceInterval: TimeInterval = 1.0
           private var lastClassificationDate = Date.distantPast
           
           weak var delegate: BarkDetectorDelegate?
           
           private init() {
               setupAudio()
           }
           
           private func setupAudio() {
               audioRecorder = AudioRecorder.shared
               audioRecorder?.delegate = nil
               
               NotificationCenter.default.addObserver(
                   forName: .audioBufferCaptured,
                   object: audioRecorder,
                   queue: .global(qos: .userInitiated)
               ) { [weak self] notification in
                   self?.processAudioBuffer(notification)
               }
           }
           
           func start() throws {
               try audioRecorder?.start()
               print("BarkDetector started")
           }
           
           func stop() {
               audioRecorder?.stop()
           }
           
           private nonisolated func processAudioBuffer(_ notification: Notification) {
               guard let buffer = notification.userInfo?["buffer"] as? AVAudioPCMBuffer else { return }
               // TODO: In 38-02b, convert buffer to MLMultiArray and run classification
               // For now, just log that we received audio
               print("Received audio buffer with \(buffer.frameLength) frames")
           }
           
           // Model loading will be added in 38-02b
           private func setupModel() {
               // Placeholder: load DogBarkClassifier.mlmodel
               // guard let modelURL = Bundle.main.url(forResource: "DogBarkClassifier", withExtension: "mlmodel") else { return }
               // try? VNCoreMLModel(for: MLModel(contentsOf: modelURL))
           }
       }
       
       protocol BarkDetectorDelegate: AnyObject {
           func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification)
       }
       ```
    
    3. Ensure no compile errors: swift build or xcodebuild to validate
  </action>
  <done>
    - BarkDetector actor with singleton pattern
    - Listens to .audioBufferCaptured notifications from AudioRecorder
    - start() triggers audio capture
    - barkDetector(_:didDetect:) delegate protocol defined
    - BarkClassification struct with confidence threshold logic
    - Skeleton ready for model loading in 38-02b
    - Placeholder logs for audio buffer receipt
  </done>
</task>

</tasks>

<verification>
Wave 2a - Audio Pipeline verification:

**1. File existence and structure:**
   - `test -f WoofTalkAR/Services/AudioRecorder.swift`
   - `test -f WoofTalkAR/Services/BarkDetector.swift`
   - `test -f WoofTalkAR/Models/BarkClassification.swift`

**2. AudioRecorder implementation:**
   - `grep -q "actor AudioRecorder" WoofTalkAR/Services/AudioRecorder.swift`
   - `grep -q "bufferSize: AVAudioFrameCount = 1024" WoofTalkAR/Services/AudioRecorder.swift`
   - `grep -q "sampleRate: Double = 48000" WoofTalkAR/Services/AudioRecorder.swift`
   - `grep -q "installTap" WoofTalkAR/Services/AudioRecorder.swift`
   - `grep -q "NotificationCenter.*audioBufferCaptured" WoofTalkAR/Services/AudioRecorder.swift`

**3. BarkDetector skeleton:**
   - `grep -q "actor BarkDetector" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "NotificationCenter.*audioBufferCaptured" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "func start() throws" WoofTalkAR/Services/BarkDetector.swift`

**4. BarkClassification model:**
   - `grep -q "BarkClassification" WoofTalkAR/Models/BarkClassification.swift`
   - `grep -q "isDogSound: Bool" WoofTalkAR/Models/BarkClassification.swift`
   - `grep -q "confidence: Float" WoofTalkAR/Models/BarkClassification.swift`

**5. Build verification:**
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

**6. Minimal runtime verification (manual but quick):**
   - Run app, grant microphone permission
   - Check console: "AudioRecorder started" appears when BarkDetector.start() called
   - No crashes during audio initialization

All checks must pass before 38-02b (model integration) can proceed.
</verification>

<success_criteria>
**AR-03 (partial):** Real-time camera passthrough with concurrent audio pipeline:

✅ Project builds (from Wave 1)
✅ AudioRecorder captures continuous 20ms buffers
✅ BarkDetector receives buffers via NotificationCenter
✅ Actor isolation ensures thread safety
✅ ARKit session runs concurrently (from ContentView)
✅ Pipeline ready for Core ML model integration in 38-02b

**Exit criteria:** Audio infrastructure validated. Ready to add dog bark classifier in next task.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-02a-SUMMARY.md` summarizing:
- AudioRecorder implementation details (buffer size, format, tap configuration)
- BarkDetector skeleton structure and notification handling
- Build results and any integration issues
- Files created/modified
- Dependencies on Wave 1 confirmed (Supabase ready but not used yet)
</output>
