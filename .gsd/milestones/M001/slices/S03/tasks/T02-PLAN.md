---
estimated_steps: 8
estimated_files: 6
---

# T02: Implement Real-time Translation Interface

**Slice:** S03: Core UI & UX
**Milestone:** M001: Core Translation Engine

## Description

Build the core user interface for real-time translation between human and dog. This includes the main translation view with smooth animations, latency indicators, translation history, and audio controls. The interface must maintain the <2-second latency requirement from S02.

## Steps

1. Create TranslationViewController.swift with real-time translation UI
2. Design translation interface with human input and dog output areas
3. Implement latency indicators and performance metrics display
4. Add translation history view with scrollable list
5. Integrate audio controls (record, stop, playback)
6. Add smooth animations and transitions between states
7. Connect TranslationEngine and AudioTranslationBridge for real-time processing
8. Add error handling and user feedback for translation failures

## Must-Haves

- [ ] TranslationViewController.swift implements complete translation interface
- [ ] Real-time translation works with <2-second latency
- [ ] Latency indicators show current translation status
- [ ] Translation history displays recent translations
- [ ] Audio controls functional (record, stop, playback)
- [ ] Smooth animations and transitions between states
- [ ] Error handling for translation failures
- [ ] Integration with TranslationEngine and AudioTranslationBridge

## Verification

- Test real-time translation with actual speech input
- Verify latency indicators show accurate status
- Check translation history updates correctly
- Test audio controls functionality
- Measure latency to ensure <2 seconds
- Verify smooth animations during state transitions

## Observability Impact

- Signals added: translation state changes, latency metrics, audio processing status
- How a future agent inspects this: check TranslationViewController for proper state management, verify latency indicators
- Failure state exposed: translation errors, audio processing failures, latency issues

## Inputs

- TranslationEngine from S02 (translateHumanToDog(), translateDogToHuman())
- AudioTranslationBridge from S01 (real-time audio processing)
- Core ML models and vocabulary from S02
- Existing TranslationViewController.swift (partial implementation)

## Expected Output

- `TranslationViewController.swift` - Complete real-time translation interface
- UI assets and layout files for translation interface
- Integration with translation engine and audio processing
- Smooth, responsive translation experience with performance metrics