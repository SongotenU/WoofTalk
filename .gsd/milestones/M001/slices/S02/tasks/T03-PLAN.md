---
estimated_steps: 5
estimated_files: 3
---

# T03: Offline Vocabulary and Storage

**Slice:** S02 — Translation Engine
**Milestone:** M001

## Description

Implement offline capability with comprehensive vocabulary storage using SQLite database. This enables core translation functionality without internet connection and provides fallbacks for common phrases.

## Steps

1. Create VocabularyDatabase.swift with SQLite schema for translation data
2. Implement OfflineTranslationManager.swift for offline translation logic
3. Create TranslationCache.swift for caching common phrases and results
4. Set up vocabulary database with 5000+ phrases and contextual variations
5. Implement offline fallback logic with graceful degradation

## Must-Haves

- [ ] SQLite vocabulary database with comprehensive phrase storage
- [ ] Offline translation manager with fallback logic
- [ ] Translation caching for common phrases
- [ ] 5000+ phrase vocabulary with contextual accuracy
- [ ] Offline capability for 80% of core phrases

## Verification

- Core vocabulary works offline without internet connection
- Translation accuracy >70% for common offline phrases
- Vocabulary database loads and queries efficiently
- Offline fallback works gracefully when online features fail

## Observability Impact

- Signals added: Offline status, vocabulary coverage, cache hit/miss ratios
- How a future agent inspects this: Offline mode diagnostics, vocabulary usage statistics
- Failure state exposed: Offline translation errors, vocabulary lookup failures, cache corruption

## Inputs

- `TranslationEngine.swift` — Core translation functionality
- `TranslationModels.swift` — Vocabulary and model structures
- Prior task research — Offline storage requirements and vocabulary needs

## Expected Output

- `VocabularyDatabase.swift` — SQLite database for translation data
- `OfflineTranslationManager.swift` — Offline translation logic and fallbacks
- `TranslationCache.swift` — Caching system for common phrases
- Working offline translation capability for core vocabulary