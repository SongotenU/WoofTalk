# S02: Translation Engine

**Goal:** Build a real-time translation engine that can translate between human speech and dog vocalizations with comprehensive vocabulary and offline capability.
**Demo:** App can capture human speech, translate it to dog vocalizations, and play back the translation in real-time with <2 second latency.

## Must-Haves
- Real-time translation between human speech and dog vocalizations
- 5000+ phrase vocabulary with contextual accuracy
- Offline capability for core phrases
- <2 second average translation latency

## Proof Level

- This slice proves: **integration**
- Real runtime required: **yes**
- Human/UAT required: **yes**

## Verification

- `swift test --filter "TranslationEngineTests"` - Test translation accuracy and latency
- `bash scripts/verify-translation.sh` - Verify real-time translation works end-to-end

## Observability / Diagnostics

- Runtime signals: Translation latency metrics, vocabulary coverage statistics, offline status indicators
- Inspection surfaces: TranslationEngine status endpoint, performance monitoring dashboard
- Failure visibility: Last translation error, retry count, phase timestamps, vocabulary lookup failures
- Redaction constraints: Never log raw audio buffers or sensitive user data

## Integration Closure

- Upstream surfaces consumed: AudioProcessing capture and playback APIs, speech recognition results
- New wiring introduced in this slice: TranslationEngine composition with audio pipeline, real-time translation loop
- What remains before the milestone is truly usable end-to-end: App Store compliance review, battery optimization, background processing

## Tasks

- [x] **T01: Translation Engine Core Architecture** `est:2h`
  - Why: Establish the core translation engine foundation with interfaces and basic implementations
  - Files: `TranslationEngine.swift`, `TranslationEngineTests.swift`, `TranslationModels.swift`
  - Do: Create translation engine class with basic translation methods, implement simple phrase mapping, set up Core ML model integration
  - Verify: TranslationEngine can be instantiated, basic translations work for test phrases
  - Done when: Translation engine passes unit tests and can translate simple predefined phrases
- [x] **T02: Real-time Translation Pipeline** `est:3h`
  - Why: Connect audio processing to translation engine for real-time translation
  - Files: `RealTranslationController.swift`, `TranslationViewController.swift`, `AudioTranslationBridge.swift`
  - Do: Implement real-time translation loop, connect speech recognition output to translation input, add audio playback for translated output
  - Verify: End-to-end translation works with <2 second latency for simple phrases
  - Done when: Real-time translation demo works with measurable latency under 2 seconds
- [x] **T03: Offline Vocabulary and Storage** `est:2h`
  - Why: Implement offline capability with comprehensive vocabulary storage
  - Files: `VocabularyDatabase.swift`, `OfflineTranslationManager.swift`, `TranslationModels.swift`
  - Do: Create SQLite vocabulary database, implement offline translation fallback, add caching for common phrases
  - Verify: Core vocabulary works offline, translation accuracy >70% for common phrases
  - Done when: App can translate without internet connection using cached vocabulary
- [x] **T04: Dog Vocalization Synthesis** `est:2h`
  - Why: Implement realistic dog vocalization output for translated phrases
  - Files: `DogVocalizationSynthesizer.swift`, `AudioEffectsProcessor.swift`, `SynthesisModels.swift`
  - Do: Create dog vocalization synthesis models, implement audio effects for natural dog sounds, add pitch and formant modification
  - Verify: Synthesized dog vocalizations sound natural and are recognizable as dog sounds
  - Done when: Translated output produces realistic dog vocalizations that users can understand
- [x] **T05: Translation Accuracy and Testing** `est:2h`
  - Why: Validate translation quality and performance with comprehensive testing
  - Files: `TranslationAccuracyTests.swift`, `PerformanceTests.swift`, `IntegrationTests.swift`
  - Do: Implement accuracy benchmarks, performance profiling, user acceptance tests with real dog vocalizations
  - Verify: Translation accuracy >70%, latency <2 seconds, battery usage <5% per hour
  - Done when: Translation engine meets all quality metrics and passes comprehensive testing

## Files Likely Touched
- `TranslationEngine.swift`
- `TranslationEngineTests.swift`
- `RealTranslationController.swift`
- `TranslationViewController.swift`
- `AudioTranslationBridge.swift`
- `VocabularyDatabase.swift`
- `OfflineTranslationManager.swift`
- `TranslationCache.swift`
- `DogVocalizationSynthesizer.swift`
- `AudioEffectsProcessor.swift`
- `SynthesisModels.swift`
- `TranslationAccuracyTests.swift`
- `PerformanceTests.swift`
- `IntegrationTests.swift`