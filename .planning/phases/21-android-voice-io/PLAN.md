# Phase 21: Android Voice I/O — Execution Plan

**Milestone:** v3.0 Platform Expansion
**Duration:** 3-4 weeks
**Prerequisites:** Phase 20 complete (Android Core Translation)

---

## Goal

Add voice input/output to the Android app — SpeechRecognizer for voice input, TextToSpeech for voice output, background voice processing as a foreground service, audio format handling matching iOS, and voice pipeline integration with the translation engine.

---

## Requirements

| ID | Requirement |
|----|-------------|
| VOICE-01 | Speech recognition input using android.speech.SpeechRecognizer with RECORD_AUDIO permission |
| VOICE-02 | Text-to-speech output using android.speech.tts.TextToSpeech with configurable speed/pitch |
| VOICE-03 | Background voice processing as foreground service with notification |
| VOICE-04 | Audio format handling matching iOS (sample rate, encoding, buffer size) |
| VOICE-05 | Voice pipeline integration: speak → recognize → translate → speak output in <3 seconds |

---

## Task Breakdown

### Wave 1: Core Voice I/O (Days 1-5)

**T1. Permission Handling**
- Create `AudioPermissionHandler` for runtime RECORD_AUDIO permission
- Handle Android 13+ POST_NOTIFICATIONS permission for foreground service
- Create permission rationale UI
- **Effort:** 2 hours
- **Deliverable:** Permission handler with user-friendly rationale

**T2. Speech Recognition Engine**
- Create `SpeechRecognitionEngine` wrapping SpeechRecognizer
- Implement continuous recognition mode
- Handle partial results streaming
- Implement confidence scoring
- Handle recognition errors gracefully
- **Effort:** 6 hours
- **Deliverable:** Working speech-to-text engine

**T3. Text-to-Speech Engine**
- Create `TextToSpeechEngine` wrapping TextToSpeech
- Implement configurable voice, speed, pitch
- Handle language selection per animal language
- Implement queue management for long text
- **Effort:** 4 hours
- **Deliverable:** Working text-to-speech engine

### Wave 2: Background Service (Days 6-10)

**T4. Foreground Voice Service**
- Create `VoiceTranslationService` extending Service
- Implement foreground notification with microphone indicator
- Handle service lifecycle (start, stop, restart)
- Implement binder for activity communication
- Handle Android Doze mode and battery optimization
- **Effort:** 8 hours
- **Deliverable:** Background voice service with notification

**T5. Audio Format Processor**
- Create `AudioFormatProcessor` matching iOS audio specs
- Handle sample rate conversion (44100 Hz default)
- Handle PCM 16-bit encoding
- Implement buffer management (matching iOS buffer size)
- **Effort:** 4 hours
- **Deliverable:** Audio format processor for consistent quality

### Wave 3: Pipeline Integration (Days 11-14)

**T6. Voice Translation Pipeline**
- Create `VoiceTranslationPipeline` connecting:
  SpeechRecognizer → TranslationEngine → TextToSpeech
- Implement <3 second end-to-end latency target
- Handle errors at each stage with graceful degradation
- Implement cancellation support
- **Effort:** 6 hours
- **Deliverable:** Complete voice translation pipeline

**T7. Voice UI Integration**
- Update TranslationScreen with voice input button
- Add voice output toggle (auto-play translation)
- Add recording animation during speech recognition
- Add visual feedback for TTS playback
- **Effort:** 4 hours
- **Deliverable:** Voice-enabled UI

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Speech recognition captures voice with >90% accuracy for common phrases | Test 50 common phrases, measure accuracy |
| 2 | TTS output plays with configurable speed/pitch | Verify speed (0.5x-2.0x) and pitch (0.5x-2.0x) ranges |
| 3 | Foreground service continues when app backgrounded | Background app → speak → verify translation received |
| 4 | Audio format matches iOS (44100 Hz, PCM 16-bit) | Verify AudioRecord configuration |
| 5 | End-to-end voice pipeline <3 seconds | Measure time from speech end to TTS start |
