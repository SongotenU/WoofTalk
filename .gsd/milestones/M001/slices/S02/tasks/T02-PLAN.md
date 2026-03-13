---
estimated_steps: 6
estimated_files: 3
---

# T02: Real-time Translation Pipeline

**Slice:** S02 — Translation Engine
**Milestone:** M001

## Description

Connect the audio processing pipeline to the translation engine for real-time translation between human speech and dog vocalizations. This implements the core real-time translation loop with latency monitoring.

## Steps

1. Create RealTranslationController.swift to manage real-time translation state and timing
2. Implement AudioTranslationBridge.swift to connect speech recognition to translation engine
3. Create TranslationViewController.swift for real-time translation display and user feedback
4. Implement latency monitoring and performance tracking in the translation pipeline
5. Add audio playback integration for translated dog vocalizations
6. Set up real-time translation loop with <2 second target latency

## Must-Haves

- [ ] Real-time translation controller with state management
- [ ] Audio bridge connecting speech recognition to translation engine
- [ ] Real-time translation display with latency indicators
- [ ] Audio playback for translated dog vocalizations
- [ ] Latency monitoring with <2 second target
- [ ] Error handling for real-time translation failures

## Verification

- End-to-end translation works with <2 second latency for simple phrases
- Real-time display updates correctly during translation
- Audio playback produces recognizable dog vocalizations
- Latency metrics show consistent performance under load

## Observability Impact

- Signals added: Real-time translation latency, buffer processing times, playback timing
- How a future agent inspects this: Translation latency dashboard, real-time performance monitoring
- Failure state exposed: Last translation latency, buffer underrun count, playback errors

## Inputs

- `TranslationEngine.swift` — Core translation functionality
- `AudioProcessing/AudioCapture.swift` — Real-time audio input
- `AudioProcessing/AudioPlayback.swift` — Audio output for translated sounds
- `AudioProcessing/SpeechRecognition.swift` — Human voice transcription
- Prior task output — Basic translation capability

## Expected Output

- `RealTranslationController.swift` — Real-time translation state management
- `AudioTranslationBridge.swift` — Audio-to-translation pipeline integration
- `TranslationViewController.swift` — Real-time translation UI
- Working end-to-end real-time translation with <2 second latency