---
estimated_steps: 5
estimated_files: 3
---

# T01: Translation Engine Core Architecture

**Slice:** S02 — Translation Engine
**Milestone:** M001

## Description

Create the core translation engine foundation with interfaces, basic translation methods, and Core ML model integration. This establishes the architecture for real-time translation between human speech and dog vocalizations.

## Steps

1. Create TranslationEngine.swift with core translation interfaces and basic implementation
2. Implement TranslationEngineTests.swift with unit tests for basic translation functionality
3. Create TranslationModels.swift with Core ML model definitions and vocabulary structures
4. Set up basic phrase mapping dictionary for initial translation capability
5. Implement error handling and logging for translation operations

## Must-Haves

- [ ] TranslationEngine class with translateHumanToDog() and translateDogToHuman() methods
- [ ] Basic phrase mapping for 100+ common phrases
- [ ] Core ML model integration ready for future ML models
- [ ] Comprehensive error handling for translation failures
- [ ] Unit tests covering basic translation functionality

## Verification

- `swift test --filter "TranslationEngineTests"` - All basic translation tests pass
- TranslationEngine can translate simple predefined phrases correctly
- Error handling works for invalid inputs and model failures

## Observability Impact

- Signals added: Translation request counts, success/failure rates, vocabulary lookup statistics
- How a future agent inspects this: TranslationEngine status reports, performance metrics
- Failure state exposed: Last translation error, retry count, vocabulary cache hit/miss ratios

## Inputs

- `AudioProcessing/AudioEngine.swift` — Provides audio buffer format for integration
- `AudioProcessing/SpeechRecognition.swift` — Speech recognition results for human voice translation
- Prior task research — Translation model architecture and vocabulary requirements

## Expected Output

- `TranslationEngine.swift` — Core translation engine with basic functionality
- `TranslationEngineTests.swift` — Unit tests for translation accuracy and error handling
- `TranslationModels.swift` — Core ML model definitions and vocabulary structures
- Basic translation capability for 100+ common phrases with >80% accuracy