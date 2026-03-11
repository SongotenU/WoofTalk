# S01: Audio Processing Foundation — Plan

**Slice:** S01  
**Milestone:** M001  
**Date:** 2026-03-11  
**Status:** Planning  

## Vision
Build a robust audio processing foundation that enables real-time speech-to-speech translation between humans and dogs with low latency and high reliability.

## Success Criteria
- Audio capture and playback with < 100ms latency
- Basic speech recognition for human voice
- Error handling for audio permissions and failures
- Integration interfaces for translation engine

## Proof Level
**Contract Proof** - This slice establishes the audio processing interfaces and basic functionality that will be consumed by S02. We prove the contracts work but not full translation capability.

## Integration Closure
**Partially closed** - Audio processing interfaces are defined and basic functionality is implemented, but integration with translation engine is deferred to S02. The wiring between audio capture and speech recognition is complete, but the full pipeline to translation output is not yet built.

## Must-Haves
- Audio capture with low latency
- Audio playback with proper routing
- Speech recognition for human voice
- Permission management and error handling
- Basic audio processing pipeline
- Integration interfaces for translation engine

## Verification Strategy

### Technical Verification
- Latency testing: < 100ms from capture to processing
- Audio quality: 44.1 kHz, 16-bit PCM format
- Permission handling: Graceful degradation on denial
- Memory usage: < 50MB peak
- Battery impact: < 5% per hour of usage

### Integration Verification
- AudioEngine can be instantiated and started
- Audio capture produces valid audio buffers
- Speech recognition returns text for human speech
- Audio playback can synthesize simple tones

### Test Files (to be created)
- `audio_processing/audio_engine_tests.swift` - Core audio engine tests
- `audio_processing/speech_recognition_tests.swift` - Speech recognition tests
- `audio_processing/audio_playback_tests.swift` - Audio playback tests
- `audio_processing/integration_tests.swift` - End-to-end audio pipeline tests

## Observability / Diagnostics

### Audio Session State
- Current audio category and category options
- Preferred sample rate and actual sample rate
- Input/output latency measurements
- Active audio routes (speaker, headphones, bluetooth)

### Performance Metrics
- Buffer processing time per frame
- Total pipeline latency (capture to processing)
- Recognition success rate
- Memory allocation for audio buffers

### Error Tracking
- Permission denial counts
- Recognition failure types and rates
- Audio session initialization failures
- Buffer overflow/underflow events

### Debug Surfaces
- Audio waveform visualization for debugging
- Real-time latency meter
- Permission status indicator
- Audio route change notifications

## Technology Choices
- **Audio Framework:** AVFoundation (native iOS performance)
- **Speech Recognition:** Speech Framework (human voice optimized)
- **Audio Format:** 44.1 kHz, 16-bit PCM, mono for capture, stereo for playback
- **Latency Target:** 5ms buffer size for low-latency processing
- **Error Handling:** Graceful degradation with user feedback

## Risk Mitigation
- **Audio Latency:** Use AVAudioEngine with minimal buffer sizes
- **Speech Recognition:** Implement fallback to basic audio analysis for dog vocalizations
- **Permission Issues:** Clear user communication and offline mode fallback
- **Memory Management:** Implement proper buffer recycling and cleanup

## Dependencies
- **Internal:** None (leaf node)
- **External:** iOS Speech Framework, AVFoundation, Core Audio

## Forward Intelligence

### Fragile Dependencies
- Audio session configuration is critical for latency
- Buffer sizes directly impact real-time performance
- Permission status can change during app usage
- Speech recognition accuracy varies by environment

### Assumptions That May Change
- Speech recognition may need custom models for dog vocalizations
- Latency requirements might be relaxed based on user feedback
- Audio quality may need adjustment for different use cases

### Areas for Future Enhancement
- Custom ML models for dog vocalization recognition
- Advanced noise cancellation for noisy environments
- Multi-language support for international users
- Background processing for continuous monitoring

## Tasks

### T01: Audio Engine Foundation
**Why:** Establish the core audio processing infrastructure with proper session configuration
**Files:** `audio_processing/audio_engine.swift`, `audio_processing/audio_session_manager.swift`, `audio_processing/audio_formats.swift`
**Do:**
- Create audio engine class with AVAudioEngine
- Implement audio session manager with low-latency configuration
- Define audio format constants and utilities
- Add error handling for audio session failures
**Verify:**
- Audio engine can be instantiated without errors
- Audio session can be configured with preferred settings
- Audio format utilities return correct values
- Error handling works for invalid configurations
**Done when:** Audio engine can be created and audio session can be configured successfully

### T02: Audio Capture Module
**Why:** Implement real-time audio capture from microphone with proper buffer management
**Files:** `audio_processing/audio_capture.swift`, `audio_processing/audio_buffer_manager.swift`
**Do:**
- Create audio capture class with microphone input
- Implement audio buffer manager for real-time processing
- Add audio permission request and handling
- Implement buffer callback with timing measurements
**Verify:**
- Audio capture can be started and stopped
- Microphone permission requests work correctly
- Audio buffers are produced at expected intervals
- Buffer processing time is measured and logged
**Done when:** Audio capture produces valid audio buffers with < 100ms latency

### T03: Speech Recognition Interface
**Why:** Integrate iOS speech recognition for human voice with proper error handling
**Files:** `audio_processing/speech_recognition.swift`, `audio_processing/recognition_result_formatter.swift`
**Do:**
- Create speech recognition class using SFSpeechRecognizer
- Implement audio buffer to recognition request conversion
- Add result formatting and error handling
- Implement retry logic for recognition failures
**Verify:**
- Speech recognition can be initialized and configured
- Audio buffers can be processed for recognition
- Recognition results are properly formatted
- Error handling works for various failure scenarios
**Done when:** Speech recognition returns text for human speech with > 80% accuracy

### T04: Audio Playback Module
**Why:** Implement audio playback for translation output with proper routing and latency
**Files:** `audio_processing/audio_playback.swift`, `audio_processing/audio_synthesis.swift`
**Do:**
- Create audio playback class with AVAudioPlayer
- Implement audio synthesis for simple tones and speech
- Add volume and routing control
- Implement playback latency optimization
**Verify:**
- Audio playback can be started and stopped
- Simple tones can be synthesized and played
- Volume and routing controls work correctly
- Playback latency is measured and optimized
**Done when:** Audio playback can synthesize and play audio with < 50ms latency

### T05: Integration Tests
**Why:** Verify the complete audio processing pipeline works end-to-end
**Files:** `audio_processing/integration_tests.swift`, `audio_processing/audio_tests.swift`
**Do:**
- Create integration test suite for audio pipeline
- Implement latency measurement tests
- Add audio quality validation tests
- Create test utilities for audio processing
**Verify:**
- Integration tests pass for basic audio pipeline
- Latency tests show < 100ms capture to processing
- Audio quality tests validate format and sample rate
- Test coverage is > 80% for audio processing code
**Done when:** All integration tests pass and audio pipeline meets performance requirements

### T06: Test Infrastructure Setup
**Why:** Establish testing framework and utilities for audio processing
**Files:** `audio_processing/test_utils.swift`, `audio_processing/mocks/` (directory)
**Do:**
- Create test utilities for audio processing
- Implement audio mocks for unit testing
- Add test fixtures for audio data
- Create test configuration utilities
**Verify:**
- Test utilities can be imported and used
- Audio mocks simulate realistic audio behavior
- Test fixtures provide valid audio data
- Test configuration works for different scenarios
**Done when:** Test infrastructure supports comprehensive audio processing testing

## Observability Impact
- Adds audio session state monitoring
- Implements performance metrics collection
- Creates error tracking surfaces
- Provides debug visualization capabilities

## Inputs
- iOS Speech Framework
- AVFoundation framework
- Core Audio capabilities
- Audio processing research from S01

## Expected Output
- Working audio processing foundation
- Test suite with > 80% coverage
- Performance metrics and error tracking
- Integration interfaces for translation engine
- Documentation for audio processing APIs

## Decision Log
- **Audio Framework:** AVFoundation chosen for native performance
- **Speech Recognition:** Speech Framework selected for human voice optimization
- **Latency Target:** 5ms buffer size for low-latency processing
- **Error Handling:** Graceful degradation with user feedback

---

**Slice S01 planned.**