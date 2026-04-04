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
      via: "NotificationCenter audio buffer"
    - from: "BarkDetector.swift"
      to: "DogBarkClassifier.mlmodel"
      via: "VNCoreMLRequest model loading"

---

<objective>
Integrate Core ML dog bark classifier with the audio pipeline.

**Purpose:** Complete the dog bark detection system by adding model inference with Vision framework.

**Output:** Functional bark detector that:
- Loads DogBarkClassifier.mlmodel
- Processes audio buffers into MLMultiArray
- Classifies with >70% confidence threshold
- Debounces 1 second to prevent spam
- Emits classification events via delegate
- Includes unit tests

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
@.planning/research/SUMMARY.md
@.planning/research/STACK.md

**Model Requirements:**
- Input: audioBuffer (MultiArray shape [1024], Float32)
- Output: classProbabilities (Dictionary: bark, howl, whine, silence)
- Target accuracy: >85% (production), placeholder acceptable for Phase 38
- Confidence threshold: 0.7

**From RESEARCH:**
- Use Vision framework with VNCoreMLRequest
- Audio buffer → MLMultiArray → CVPixelBuffer conversion needed
- Debouncing essential to avoid false positives

</context>

<tasks>

<task type="auto">
  <name>Task 1: Create placeholder Core ML model</name>
  <files>WoofTalkAR/Resources/DogBarkClassifier.mlmodel
  </files>
  <read_first>
    - Reference: Training/train_bark_classifier.py (to be created)
  </read_first>
  <acceptance_criteria>
    - .mlmodel file exists and is valid
    - Model has correct input signature (audioBuffer: MultiArray[1024])
    - Model has correct output (classProbabilities: Dictionary)
    - File size > 0 KB
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Resources/DogBarkClassifier.mlmodel
      test -s WoofTalkAR/Resources/DogBarkClassifier.mlmodel
      # Validate model structure (requires coremltools, skip if unavailable)
    </automated>
  </verify>
  <action>
    1. Generate placeholder model using Python script (or create minimal valid .mlmodel)
    2. Place in WoofTalkAR/Resources/
    3. Ensure it's a valid Core ML model (can be loaded by Vision)
  </action>
  <done>
    - DogBarkClassifier.mlmodel exists
    - Model has correct input/output signatures
  </done>
</task>

<task type="auto">
  <name>Task 2: Complete BarkDetector with Vision integration</name>
  <files>WoofTalkAR/Services/BarkDetector.swift
  </files>
  <read_first>
    - Existing skeleton from 38-02a
  </read_first>
  <acceptance_criteria>
    - VNCoreMLModel configured with DogBarkClassifier
    - VNCoreMLRequest with confidenceThreshold = 0.7
    - processAudioBuffer converts AVAudioPCMBuffer → MLMultiArray → CVPixelBuffer
    - handleClassification maps results to BarkClassification
    - Debounce interval 1.0 second
    - Delegate callback on @MainActor when isDogSound == true
  </acceptance_criteria>
  <verify>
    <automated>
      grep -q "VNCoreMLModel" WoofTalkAR/Services/BarkDetector.swift
      grep -q "VNCoreMLRequest" WoofTalkAR/Services/BarkDetector.swift
      grep -q "confidenceThreshold: Float = 0.7" WoofTalkAR/Services/BarkDetector.swift
      grep -q "debounceInterval: TimeInterval = 1.0" WoofTalkAR/Services/BarkDetector.swift
      grep -q "MLMultiArray" WoofTalkAR/Services/BarkDetector.swift
      grep -q "toCVPixelBuffer" WoofTalkAR/Services/BarkDetector.swift
      grep -q "@MainActor" WoofTalkAR/Services/BarkDetector.swift
    </automated>
  </verify>
  <action>
    1. In BarkDetector, add setupModel() to load VNCoreMLModel from DogBarkClassifier.mlmodel
    2. Implement processAudioBuffer(Notification) to extract audio buffer and convert to MLMultiArray
    3. Create VNImageRequestHandler with CVPixelBuffer from multiarray
    4. Perform VNCoreMLRequest and handle results
    5. Map VNClassificationObservation to BarkClassification (className, confidence)
    6. Apply debounce: only emit if lastClassificationDate > 1 second ago
    7. Call delegate on @MainActor if isDogSound
  </action>
  <done>
    - BarkDetector fully integrated with Vision
    - Classification pipeline complete
    - Debouncing prevents spam
  </done>
</task>

<task type="auto">
  <name>Task 3: Add unit tests</name>
  <files>Tests/BarkDetectorTests.swift, Tests/TestResources/bark_sample.wav, Tests/TestResources/silence.wav
  </files>
  <read_first>
    - N/A
  </read_first>
  <acceptance_criteria>
    - BarkDetectorTests.swift tests classification accuracy
    - Uses XCTestExpectation for async delegate callbacks
    - Loads test audio from Bundle.module
    - Asserts className and confidence threshold
    - Test fixtures exist (bark_sample.wav, silence.wav)
  </acceptance_criteria>
  <verify>
    <automated>
      test -f Tests/BarkDetectorTests.swift
      grep -q "XCTestCase" Tests/BarkDetectorTests.swift
      grep -q "testBarkClassification" Tests/BarkDetectorTests.swift
      grep -q "XCTestExpectation" Tests/BarkDetectorTests.swift
      test -f Tests/TestResources/bark_sample.wav
      test -f Tests/TestResources/silence.wav
    </automated>
  </verify>
  <action>
    1. Create BarkDetectorTests.swift with two test methods
    2. Set up BarkDetector delegate to receive callback
    3. Load test WAV files from bundle
    4. Send audio buffer to detector.processAudioBuffer()
    5. Wait for expectation, assert classification results
    6. Generate placeholder WAV files (1 second, 48kHz mono) if needed
  </action>
  <done>
    - Unit tests written and ready
    - Test fixtures created (placeholders ok)
  </done>
</task>

<task type="auto">
  <name>Task 4: Update Package.swift with test target</name>
  <files>Package.swift
  </files>
  <read_first>
    - Existing Package.swift from 38-01b
  </read_first>
  <acceptance_criteria>
    - TestTarget "BarkDetectorTests" added
    - Depends on ["WoofTalkAR"]
    - Package.swift syntax valid
  </acceptance_criteria>
  <verify>
    <automated>
      grep -q ".testTarget(name: \"BarkDetectorTests\"" Package.swift
      grep -q "dependencies: \[\"WoofTalkAR\"\]" Package.swift
    </automated>
  </verify>
  <action>
    Add to Package.swift targets array:
      .testTarget(name: "BarkDetectorTests", dependencies: ["WoofTalkAR"])
  </action>
  <done>
    - Test target configured
  </done>
</task>

</tasks>

<verification>
Complete 38-02b verification:

1. Model file exists and has size
2. BarkDetector.swift contains complete Vision integration (VNCoreMLModel, request, conversion, debounce)
3. BarkDetectorTests.swift exists with XCTestCase and expectations
4. Test WAV fixtures exist
5. Package.swift includes test target

All automated checks must pass.
</verification>

<success_criteria>
**AR-02 & AR-03 complete when:**
- ✅ Core ML model integrated (placeholder acceptable)
- ✅ Vision framework used with confidence threshold 70%
- ✅ Audio pipeline processes buffers → classification
- ✅ Debouncing prevents spam (1s interval)
- ✅ Unit tests validate classification logic
- ✅ Real-time detection <1 second latency
- ✅ Runs concurrently with AR session

**Exit criteria:** Bark detection fully functional. Ready for AR overlay (Phase 38-03).
</success_criteria>

<output>
Create `.planning/phases/38-ar-foundation/38-02b-SUMMARY.md` with:
- Implementation details
- File list with sizes
- Verification results
- Manual steps (train model, replace fixtures)
- Known limitations

</output>
