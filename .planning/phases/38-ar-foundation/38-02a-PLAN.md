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

---

<objective>
Implement audio pipeline for dog bark detection (without model yet).

**Purpose:** Create the audio capture and classification infrastructure that will later integrate with Core ML.

**Output:** Audio recording system with:
- AVAudioEngine capturing 48kHz mono audio
- 20ms buffers (1024 samples) broadcast via NotificationCenter
- BarkDetector actor observing buffers
- BarkClassification result model

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

**Audio Pipeline Specs:**
- Sample rate: 48 kHz
- Buffer size: 1024 samples (20ms windows)
- Format: Float32, mono
- Broadcast: NotificationCenter with `.audioBufferCaptured`
- Actor isolation for thread safety

**From 38-02b:** Will add Core ML model and Vision framework integration.

</context>

<tasks>

<task type="auto">
  <name>Task 1: Create AudioRecorder actor</name>
  <files>WoofTalkAR/Services/AudioRecorder.swift
  </files>
  <read_first>
    - Reference: ios/ audio processing patterns for AVAudioEngine setup
  </read_first>
  <acceptance_criteria>
    - AudioRecorder is an actor with singleton pattern
    - AVAudioEngine configured for 48kHz, mono, Float32
    - Buffer size exactly 1024 samples
    - installTap captures continuous buffers
    - Buffers broadcast via NotificationCenter (.audioBufferCaptured)
    - Thread-safe actor isolation
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/AudioRecorder.swift
      grep -q "actor AudioRecorder" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "static let shared" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "bufferSize: AVAudioFrameCount = 1024" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "sampleRate: Double = 48000" WoofTalkAR/Services/AudioRecorder.swift
      grep -q "installTap" WoofTalkAR/Services/AudioRecorder.swift
      grep -q ".audioBufferCaptured" WoofTalkAR/Services/AudioRecorder.swift
    </automated>
  </verify>
  <action>
    1. Create AudioRecorder.swift with actor pattern
    2. Configure AVAudioEngine input node
    3. Set buffer size to 1024, sample rate 48kHz
    4. Install tap to capture buffers
    5. Post NotificationCenter events with audio buffer
    6. Provide start()/stop() methods
  </action>
  <done>
    - AudioRecorder actor implemented
    - Audio capture works with correct specs
    - Buffers broadcast for BarkDetector
  </done>
</task>

<task type="auto">
  <name>Task 2: Create BarkClassification model</name>
  <files>WoofTalkAR/Models/BarkClassification.swift
  </files>
  <read_first>
    - N/A (simple model)
  </read_first>
  <acceptance_criteria>
    - Struct with Identifiable, Codable
    - Properties: timestamp, className (bark/howl/whine/silence), confidence
    - Computed isDogSound uses threshold >0.7
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Models/BarkClassification.swift
      grep -q "BarkClassification" WoofTalkAR/Models/BarkClassification.swift
      grep -q "className: String" WoofTalkAR/Models/BarkClassification.swift
      grep -q "confidence: Float" WoofTalkAR/Models/BarkClassification.swift
      grep -q "isDogSound: Bool" WoofTalkAR/Models/BarkClassification.swift
    </automated>
  </verify>
  <action>
    1. Create BarkClassification.swift struct
    2. Add Identifiable, Codable conformance
    3. Implement isDogSound computed property (className != "silence" && confidence > 0.7)
  </action>
  <done>
    - Classification model ready
  </done>
</task>

<task type="auto">
  <name>Task 3: Create BarkDetector skeleton</name>
  <files>WoofTalkAR/Services/BarkDetector.swift
  </files>
  <read_first>
    - Will be extended in 38-02b with Core ML
  </read_first>
  <acceptance_criteria>
    - BarkDetector is an actor with singleton pattern
    - Observes .audioBufferCaptured notifications
    - Has placeholder for VNCoreMLRequest
    - start()/stop() methods control lifecycle
    - Delegate protocol for classification results
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Services/BarkDetector.swift
      grep -q "actor BarkDetector" WoofTalkAR/Services/BarkDetector.swift
      grep -q "static let shared" WoofTalkAR/Services/BarkDetector.swift
      grep -q "VNCoreMLRequest" WoofTalkAR/Services/BarkDetector.swift
      grep -q "start()" WoofTalkAR/Services/BarkDetector.swift
      grep -q "stop()" WoofTalkAR/Services/BarkDetector.swift
    </automated>
  </verify>
  <action>
    1. Create BarkDetector actor with singleton
    2. Set up NotificationCenter observer for .audioBufferCaptured
    3. Add VNCoreMLRequest property (will be configured in 38-02b)
    4. Implement start/stop to control AudioRecorder
    5. Define BarkDetectorDelegate protocol (class, @MainActor)
  </action>
  <done>
    - BarkDetector skeleton ready for model integration
  </done>
</task>

</tasks>

<verification>
Audio pipeline verification:

1. AudioRecorder.swift contains:
   - `actor AudioRecorder`
   - `static let shared`
   - `bufferSize: AVAudioFrameCount = 1024`
   - `sampleRate: Double = 48000`
   - `installTap`
   - `.audioBufferCaptured`

2. BarkClassification.swift contains:
   - `BarkClassification` struct
   - `className: String`
   - `confidence: Float`
   - `isDogSound: Bool` with >0.7 threshold

3. BarkDetector.swift contains:
   - `actor` pattern
   - Notification observer for audio buffers
   - `VNCoreMLRequest` placeholder
   - `start()`/`stop()` methods

All files must exist and pass grep checks.
</verification>

<success_criteria>
**AR-03 (partial) is complete when:**
- ✅ Audio pipeline fully functional
- ✅ Buffers captured and broadcast
- ✅ BarkDetector ready for model integration
- ✅ Actor isolation ensures thread safety

**Exit criteria:** 38-02b can now add Core ML model and complete detection logic.
</success_criteria>

<output>
Create `.planning/phases/38-ar-foundation/38-02a-SUMMARY.md` after completion.
</output>
