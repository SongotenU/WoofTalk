---
phase: 38-ar-foundation
plan: 02b
type: execute
wave: 2
depends_on:
  - "38-02a"
files_modified:
  - WoofTalkAR/Resources/DogBarkClassifier.mlmodel
  - WoofTalkAR/Services/BarkDetector.swift
  - Tests/BarkDetectorTests.swift
  - Tests/TestResources/bark_sample.wav
  - Tests/TestResources/silence.wav
requirements:
  - AR-02
  - AR-03
autonomous: true
must_haves:
  truths:
    - "Dog bark classifier integrated with Vision framework"
    - "Audio pipeline processes buffers and produces classifications"
    - "BarkDetector delegates classification events with confidence >70%"
    - "Unit tests validate detection accuracy on sample audio"
    - "Real-time detection triggers within 1 second of bark"
    - "Detection works while AR session is active"
  artifacts:
    - path: "WoofTalkAR/Resources/DogBarkClassifier.mlmodel"
      provides: "Core ML model for dog sound classification"
      min_size_kb: 1
      contains:
        - "model version"
        - "inputs: audioBuffer (MultiArray shape [1024])"
        - "outputs: classProbabilities (Dictionary)"
    - path: "WoofTalkAR/Services/BarkDetector.swift"
      provides: "Complete Vision framework integration with model inference"
      min_lines: 80
      contains:
        - "VNCoreMLModel"
        - "VNCoreMLRequest"
        - "confidenceThreshold: 0.7"
        - "debounceInterval: 1.0"
        - "multiArrayToPixelBuffer conversion"
    - path: "Tests/BarkDetectorTests.swift"
      provides: "Unit tests for classification accuracy"
      min_lines: 50
      contains:
        - "XCTestCase"
        - "testBarkClassification"
        - "testSilenceClassification"
  key_links:
    - from: "AudioRecorder.swift"
      to: "BarkDetector.swift"
      via: "audio buffer notifications"
      pattern: "audioBufferCaptured"
    - from: "BarkDetector.swift"
      to: "DogBarkClassifier.mlmodel"
      via: "VNCoreMLModel for: MLModel(contentsOf:)"
      pattern: "MLModel\\(contentsOf: modelURL\\)"
    - from: "BarkDetector.swift"
      to: "BarkClassification.swift"
      via: "returns BarkClassification in delegate"
      pattern: "BarkClassification"
    - from: "BarkDetectorTests.swift"
      to: "BarkDetector.swift"
      via: "calls processAudioBuffer"
      pattern: "processAudioBuffer"

---

<objective>
Integrate Core ML dog bark classifier with Vision framework and complete the BarkDetector implementation.

**Purpose:** Enable real-time dog bark detection from audio buffers. This connects the audio pipeline (38-02a) to the translation system.

**Output:** Fully functional classifier:
- DogBarkClassifier.mlmodel in app resources
- BarkDetector with Vision inference (confidence >70%, 1s debounce)
- Unit tests validating classification on known samples
- End-to-end audio → classification pipeline

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

# Model Integration Context

**From RESEARCH.md:**
- Model: CNN on mel-spectrograms
- Input: audio samples (1024 samples @ 48kHz) → preprocessed to mel-spectrogram
- Output: probability distribution over {bark, howl, whine, silence}
- Accuracy target: >85% (placeholder model will be lower - infrastructure only)
- Training datasets: AudioSet, ESC-50, or commercial dog sound libraries

**From STACK.md:**
- Input shape: [1024] (MultiArray)
- Output: Dictionary with class keys
- Use VNCoreMLModel for Vision framework integration
- Target: <100ms inference latency

**Important Note:**
Training a real model with >85% accuracy requires dataset and compute resources out of scope for automated planning. We will:
1. Create a placeholder .mlmodel file with correct input/output signature
2. Document that this is for testing infrastructure only
3. Provide training script reference for future model improvement

The placeholder model will have poor accuracy but demonstrates the integration pipeline.

</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create placeholder DogBarkClassifier.mlmodel</name>
  <files>WoofTalkAR/Resources/DogBarkClassifier.mlmodel, Training/train_bark_classifier.py
  </files>
  <read_first>
    - Reference: STACK.md for model specification (input shape, output classes)
  </read_first>
  <acceptance_criteria>
    - DogBarkClassifier.mlmodel file exists with size > 1KB (minimum valid model)
    - Model accepts input named "audioBuffer" of type MultiArray with shape [1024] (Float32)
    - Model outputs dictionary named "classProbabilities" with keys: "bark", "howl", "whine", "silence"
    - Model can be loaded with VNCoreMLModel(MLModel(contentsOf:)) without errors
    - Model compiles in Xcode build process (no Core ML errors)
    - Training script provided as reference for future real model
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Resources/DogBarkClassifier.mlmodel
      SIZE=$(stat -f%z "WoofTalkAR/Resources/DogBarkClassifier.mlmodel" 2>/dev/null || stat -c%s "WoofTalkAR/Resources/DogBarkClassifier.mlmodel" 2>/dev/null || echo "0")
      [ "$SIZE" -ge 1024 ]  # At least 1KB
      # Verify model can be loaded (requires Core ML framework availability, skip if not available)
      echo "Model file exists: size ${SIZE} bytes"
      # Note: Full model validation requires Core ML runtime, check in build phase
    </automated>
  </verify>
  <action>
    Since training a production model (>85% accuracy) requires datasets and compute out of scope, create a **valid placeholder Core ML model** using Python with coremltools:

    1. Create `Training/train_bark_classifier.py` (reference implementation):
       ```python
       import coremltools as ct
       import numpy as np
       
       # Define a minimal model: single dense layer (for placeholder only)
       # Real model would use CNN on mel-spectrograms
       input_dim = 1024
       num_classes = 4  # bark, howl, whine, silence
       
       # Create simple linear model as placeholder
       weights = np.random.randn(input_dim, num_classes).astype(np.float32) * 0.01
       bias = np.random.randn(num_classes).astype(np.float32)
       
       # Save as Core ML model
       mlmodel = ct.models.neural_network.NeuralNetworkClassifier(
           input_name="audioBuffer",
           output_name="classProbabilities",
           class_labels=["bark", "howl", "whine", "silence"]
       )
       
       # Add a single inner product layer
       mlmodel.add_inner_product(
           W=weights,
           b=bias,
           input_channels=input_dim,
           output_channels=num_classes,
           has_bias=True
       )
       
       # Specify input shape
       mlmodel.input_description = {"audioBuffer": "Audio buffer of 1024 samples"}
       mlmodel.output_description = {"classProbabilities": "Probabilities for 4 classes"}
       
       # Save
       mlmodel.save("DogBarkClassifier.mlmodel")
       print("Placeholder model created - accuracy will be random")
       ```
       
       Note: This creates a minimal valid .mlmodel with correct signature but random predictions.

    2. Run the script (or provide pre-built placeholder):
       ```bash
       mkdir -p Training
       python3 -m venv Training/.venv
       source Training/.venv/bin/activate
       pip install coremltools numpy
       python Training/train_bark_classifier.py
       ```
       
       If coremltools unavailable, create a minimal .mlmodel using alternative method or provide pre-generated stub.

    3. Place the resulting `DogBarkClassifier.mlmodel` into `WoofTalkAR/Resources/`

    4. Document clearly in code comments and README:
       - This is a **placeholder model** for testing infrastructure only
       - Accuracy is random (~25% for 4 classes)
       - Real model should be trained on dog sound datasets (AudioSet, ESC-50)
       - Expected accuracy target: >85% (AR-02 requirement)
       - Model replacement does not require API changes

    The model must compile in Xcode without errors when added to the app bundle.
  </action>
  <done>
    - DogBarkClassifier.mlmodel exists in Resources folder (size >1KB)
    - Model has correct input: MultiArray shape [1024] named "audioBuffer"
    - Model has correct output: Dictionary with keys bark, howl, whine, silence
    - Model loads via VNCoreMLModel without runtime errors
    - Model compiles in Xcode build process
    - Training script provided for future model development
    - Documentation notes placeholder nature and accuracy limitations
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Complete BarkDetector with Vision classification</name>
  <files>WoofTalkAR/Services/BarkDetector.swift
  </files>
  <read_first>
    - Read: DogBarkClassifier.mlmodel (to verify input/output)
    - Read: AudioRecorder.swift (for notification pattern)
    - Read: BarkClassification.swift (for result type)
  </read_first>
  <acceptance_criteria>
    - BarkDetector loads model from bundle in setupModel()
    - VNCoreMLRequest configured with model and confidence threshold (0.7)
    - audioBufferCaptured notification triggers classification
    - AVAudioPCMBuffer converted to MLMultiArray (shape [1, 1024])
    - MLMultiArray converted to CVPixelBuffer for VNImageRequestHandler
    - Classification results parsed to extract className and confidence
    - isDogSound computed as className != "silence" && confidence > 0.7
    - Debounce interval of 1.0 second prevents spam
    - Delegate callback on MainActor when dog sound detected
    - Errors logged gracefully (model loading failures, conversion errors)
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/BarkDetector.swift
      grep -q "VNCoreMLModel" WoofTalkAR/Services/BarkDetector.swift
      grep -q "VNCoreMLRequest" WoofTalkAR/Services/BarkDetector.swift
      grep -q "confidenceThreshold: Float = 0.7" WoofTalkAR/Services/BarkDetector.swift
      grep -q "debounceInterval: TimeInterval = 1.0" WoofTalkAR/Services/BarkDetector.swift
      grep -q "MLMultiArray" WoofTalkAR/Services/BarkDetector.swift
      grep -q "toMultiArray" WoofTalkAR/Services/BarkDetector.swift
      grep -q "handleClassification(request:)" WoofTalkAR/Services/BarkDetector.swift
      grep -q "isDogSound" WoofTalkAR/Services/BarkDetector.swift
      grep -q "@MainActor" WoofTalkAR/Services/BarkDetector.swift
    </automated>
  </verify>
  <action>
    Update `WoofTalkAR/Services/BarkDetector.swift` with complete Vision integration:

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
            setupModel()
            setupAudio()
        }
        
        private func setupModel() {
            guard let modelURL = Bundle.main.url(forResource: "DogBarkClassifier", withExtension: "mlmodel") else {
                print("ERROR: DogBarkClassifier.mlmodel not found in bundle")
                return
            }
            
            do {
                let model = try VNCoreMLModel(
                    for: MLModel(contentsOf: modelURL)
                )
                classificationRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
                    if let error = error {
                        print("Classification error: \(error)")
                        return
                    }
                    self?.handleClassification(request: request)
                }
                classificationRequest?.imageCropAndScaleOption = .scaleCropToFill
                print("Model loaded successfully from \(modelURL.lastPathComponent)")
            } catch {
                print("Failed to load model: \(error)")
            }
        }
        
        private func setupAudio() {
            audioRecorder = AudioRecorder.shared
            
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
            guard let buffer = notification.userInfo?["buffer"] as? AVAudioPCMBuffer,
                  let request = classificationRequest else { return }
            
            // Convert AVAudioPCMBuffer to MLMultiArray
            guard let multiArray = buffer.toMultiArray() else {
                print("Failed to convert buffer to MLMultiArray")
                return
            }
            
            // Convert MLMultiArray to CVPixelBuffer (Vision expects image-like input)
            guard let pixelBuffer = multiArray.toCVPixelBuffer() else {
                print("Failed to convert MLMultiArray to CVPixelBuffer")
                return
            }
            
            do {
                try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
            } catch {
                print("VN request failed: \(error)")
            }
        }
        
        private func handleClassification(request: VNRequest) {
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else { return }
            
            let className = mapClassLabel(top.identifier)
            let confidence = top.confidence
            
            let classification = BarkClassification(
                timestamp: Date(),
                className: className,
                confidence: confidence
            )
            
            // Debounce
            let now = Date()
            guard now.timeIntervalSince(lastClassificationDate) > debounceInterval else { return }
            lastClassificationDate = now
            
            if classification.isDogSound {
                Task { @MainActor in
                    delegate?.barkDetector(self, didDetect: classification)
                }
            }
        }
        
        private func mapClassLabel(_ identifier: String) -> String {
            let lowercased = identifier.lowercased()
            if lowercased.contains("bark") { return "bark" }
            if lowercased.contains("howl") { return "howl" }
            if lowercased.contains("whine") { return "whine" }
            return "silence"
        }
    }
    
    protocol BarkDetectorDelegate: AnyObject {
        func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification)
    }
    
    // MARK: - AVAudioPCMBuffer extensions for conversion
    
    extension AVAudioPCMBuffer {
        func toMultiArray() -> MLMultiArray? {
            guard let channelData = self.floatChannelData?.pointee else { return nil }
            let frameLength = Int(self.frameLength)
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            
            do {
                // Shape: [1, 1024] - batch dim 1, 1024 samples
                let multiArray = try MLMultiArray(
                    shape: [1, 1024] as [NSNumber],
                    dataType: .float32
                )
                for (i, value) in channelDataArray.enumerated() where i < 1024 {
                    multiArray[i] = value as NSNumber
                }
                return multiArray
            } catch {
                print("Failed to create MLMultiArray: \(error)")
                return nil
            }
        }
    }
    
    extension MLMultiArray {
        func toCVPixelBuffer() -> CVPixelBuffer? {
            // Convert 1D float array to 2D image-like pixel buffer for Vision
            // Shape: [1, 1024] -> [1, 1024] single-channel image
            let width = 1
            let height = 1024
            
            var pixelBuffer: CVPixelBuffer?
            let attrs = [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary
            
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32ARGB,
                attrs,
                &pixelBuffer
            )
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
                print("Failed to create CVPixelBuffer: status \(status)")
                return nil
            }
            
            // Copy data from MLMultiArray to pixel buffer (simplified - single channel)
            CVPixelBufferLockBaseAddress(buffer, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
                let bufferPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                for i in 0..<min(1024, Int(self.count)) {
                    let floatVal = self[i].floatValue
                    let byteVal = UInt8(max(0, min(255, floatVal * 127 + 128)))
                    // ARGB format: fill all channels with same value for grayscale
                    bufferPointer[i * 4] = byteVal     // A
                    bufferPointer[i * 4 + 1] = byteVal // R
                    bufferPointer[i * 4 + 2] = byteVal // G
                    bufferPointer[i * 4 + 3] = byteVal // B
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            
            return buffer
        }
    }
    ```
  </action>
  <done>
    - BarkDetector loads DogBarkClassifier.mlmodel from bundle
    - VNCoreMLRequest configured with confidenceThreshold = 0.7
    - Audio buffer → MLMultiArray → CVPixelBuffer conversion implemented
    - Classification results mapped to className (bark, howl, whine, silence)
    - Debounce (1s) and MainActor delegate callback implemented
    - Errors handled gracefully with console logging
    - Vision framework integration complete
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Write unit tests for BarkDetector accuracy</name>
  <files>Tests/BarkDetectorTests.swift, Tests/TestResources/bark_sample.wav, Tests/TestResources/silence.wav
  </files>
  <read_first>
    - Read: BarkDetector.swift (to understand testing API)
    - Read: BarkClassification.swift (to understand result type)
  </read_first>
  <acceptance_criteria>
    - Test target configured in Package.swift with name "BarkDetectorTests"
    - Tests import WoofTalkAR module with @testable
    - testBarkClassification: loads bark_sample.wav (48kHz mono), sends to detector, expects className == "bark" with confidence > 0.0 (placeholder model may have random predictions, but at least >0)
    - testSilenceClassification: loads silence.wav, expects className == "silence"
    - Tests use async/await with XCTestExpectation for async delegate callbacks
    - Tests pass (or at least compile and execute without crashes)
    - Test resources directory exists with WAV files
  </acceptance_criteria>
  <verify>
    <automated>
      test -f Tests/BarkDetectorTests.swift
      grep -q "import XCTest" Tests/BarkDetectorTests.swift
      grep -q "@testable import WoofTalkAR" Tests/BarkDetectorTests.swift
      grep -q "class BarkDetectorTests: XCTestCase" Tests/BarkDetectorTests.swift
      grep -q "testBarkClassification" Tests/BarkDetectorTests.swift
      grep -q "testSilenceClassification" Tests/BarkDetectorTests.swift
      grep -q "XCTestExpectation" Tests/BarkDetectorTests.swift
      test -d Tests/TestResources
      test -f Tests/TestResources/bark_sample.wav
      test -f Tests/TestResources/silence.wav
    </automated>
  </verify>
  <action>
    1. Create `Tests/BarkDetectorTests.swift`:
       ```swift
       import XCTest
       @testable import WoofTalkAR
       
       final class BarkDetectorTests: XCTestCase {
           var detector: BarkDetector!
           var expectation: XCTestExpectation!
           var detectedClassification: BarkClassification?
           
           override func setUp() async throws {
               try await super.setUp()
               detector = BarkDetector.shared
               detector.delegate = self
           }
           
           override func tearDown() async throws {
               detector.stop()
               detector.delegate = nil
               try await super.tearDown()
           }
           
           func testBarkClassification() async throws {
               expectation = XCTestExpectation(description: "Bark detected")
               expectation.expectedFulfillmentCount = 1
               expectation.assertForOverFulfill = false
               
               // Load test audio file
               let testAudioURL = Bundle.module.url(forResource: "bark_sample", withExtension: "wav")!
               let audioFile = try AVAudioFile(forReading: testAudioURL)
               let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 1024)!
               try audioFile.read(into: buffer)
               buffer.frameLength = buffer.frameCapacity
               
               // Start detector
               try await detector.start()
               
               // Send buffer directly to detector (byassing AudioRecorder for isolated test)
               await detector.processAudioBuffer(Notification(
                   name: .audioBufferCaptured,
                   object: nil,
                   userInfo: ["buffer": buffer]
               ))
               
               await fulfillment(of: [expectation], timeout: 5.0)
               
               XCTAssertNotNil(detectedClassification)
               XCTAssertEqual(detectedClassification?.className, "bark")
               // Placeholder model may have low confidence, just check >0.1 for now
               XCTAssertGreaterThan(detectedClassification?.confidence ?? 0, 0.1)
           }
           
           func testSilenceClassification() async throws {
               expectation = XCTestExpectation(description: "Silence detected")
               expectation.expectedFulfillmentCount = 1
               
               let testAudioURL = Bundle.module.url(forResource: "silence", withExtension: "wav")!
               let audioFile = try AVAudioFile(forReading: testAudioURL)
               let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 1024)!
               try audioFile.read(into: buffer)
               buffer.frameLength = buffer.frameCapacity
               
               await detector.processAudioBuffer(Notification(
                   name: .audioBufferCaptured,
                   object: nil,
                   userInfo: ["buffer": buffer]
               ))
               
               await fulfillment(of: [expectation], timeout: 5.0)
               
               XCTAssertNotNil(detectedClassification)
               XCTAssertEqual(detectedClassification?.className, "silence")
           }
       }
       
       extension BarkDetectorTests: BarkDetectorDelegate {
           nonisolated func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification) {
               detectedClassification = classification
               expectation.fulfill()
           }
       }
       ```

    2. Ensure test target in `Package.swift`:
       ```swift
       .testTarget(
           name: "BarkDetectorTests",
           dependencies: ["WoofTalkAR"]
       )
       ```

    3. Create `Tests/TestResources/` directory and place WAV files:
       - `bark_sample.wav`: 1 second of dog bark, 48kHz, mono, 16-bit PCM
       - `silence.wav`: 1 second of silence, 48kHz, mono, 16-bit PCM
       
       Note: User must provide actual audio samples or generate synthetic test files:
       ```bash
       # Generate bark_sample.wav (synthetic tone as placeholder)
       ffmpeg -f lavfi -i "sine=frequency=1000:duration=1" -ar 48000 -ac 1 Tests/TestResources/bark_sample.wav
       # Generate silence.wav
       ffmpeg -f lavfi -i "anullsrc=duration=1" -ar 48000 -ac 1 Tests/TestResources/silence.wav
       ```

    4. Run tests: `swift test` or `xcodebuild test`
  </action>
  <done>
    - BarkDetectorTests.swift with two test cases using XCTestExpectation
    - Test resources (WAV files) provided
    - Test target configured in Package.swift
    - Tests compile and run
    - At least one test passes (or both execute without crash, even if placeholder model fails assertion)
  </done>
</task>

</tasks>

<verification>
Wave 2b - Model Integration verification:

**1. Model file:**
   - `test -f WoofTalkAR/Resources/DogBarkClassifier.mlmodel`
   - File size > 1024 bytes
   - Model loads via `VNCoreMLModel(MLModel(contentsOf:))` without errors (checked in runtime)

**2. BarkDetector complete implementation:**
   - `grep -q "VNCoreMLModel" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "toMultiArray" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "toCVPixelBuffer" extension in BarkDetector.swift`
   - `grep -q "confidenceThreshold: 0.7" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "debounceInterval: 1.0" WoofTalkAR/Services/BarkDetector.swift`
   - `grep -q "mapClassLabel" WoofTalkAR/Services/BarkDetector.swift`

**3. Tests:**
   - `test -f Tests/BarkDetectorTests.swift`
   - `test -d Tests/TestResources`
   - `test -f Tests/TestResources/bark_sample.wav`
   - `test -f Tests/TestResources/silence.wav`
   - `grep -q "XCTestCase" Tests/BarkDetectorTests.swift`

**4. Build verification:**
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

**5. Unit test execution (optional but desirable):**
   - `xcodebuild test` or `swift test` runs without crashing
   - Tests at least compile and execute (placeholders may fail assertions)

**6. Runtime smoke (manual):**
   - App launches, BarkDetector.start() initializes model
   - Console shows "Model loaded successfully"
   - Audio buffer triggers classification (log may show "Received audio buffer" and classification results)

All checks must pass. Note: Placeholder model does NOT meet >85% accuracy requirement (AR-02), but infrastructure is complete. Real model can be dropped in as replacement without code changes.
</verification>

<success_criteria>
**AR-02 (Dog Bark Classifier) - Infrastructure Complete:**

✅ Core ML model integrated with Vision framework (placeholder model)
✅ DogBarkClassifier.mlmodel in app bundle, loads successfully
✅ BarkDetector complete: audio → MLMultiArray → VNCoreMLRequest → delegate
✅ Confidence threshold >70% implemented
✅ Debounce interval 1 second prevents spam
✅ Unit tests validate classification pipeline (even if accuracy low)

⚠️ Actual >85% accuracy requires trained model (not placeholder). Infrastructure ready for model swap.

**AR-03 (Real-time Camera Passthrough) - Full:**

✅ Audio pipeline from 38-02a working
✅ ARKit session active (from 38-01)
✅ Detection runs concurrently without frame drops
✅ Real-time processing (<100ms per buffer) achievable

**Phase 38-02 complete:** Dog bark detection pipeline fully wired, ready to trigger translations in Wave 3.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-02b-SUMMARY.md` summarizing:
- Model integration details (placeholder vs production)
- BarkDetector complete implementation
- Unit test structure and results
- Classification accuracy with placeholder model (expected ~random)
- Files created/modified
- Dependencies on 38-02a confirmed
- Next steps: replace placeholder with trained model for production accuracy
</output>
