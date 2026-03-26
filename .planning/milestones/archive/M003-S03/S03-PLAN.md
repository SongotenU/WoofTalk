# S03: Multi-language Support - PLAN

**Milestone:** M003 (Advanced Features)  
**Phase:** S03  
**Status:** IN PROGRESS  
**Dependencies:** S01 (AI Translation), S02 (Real-time Features)

## Goal
Support multiple animal languages beyond Dog, with extensible architecture that allows easy addition of new animal languages (Cat, Bird, etc.).

---

## Task Breakdown

### T01: Language Data Model Extensions
- [ ] **AnimalLanguage** enum with supported languages (Dog, Cat, Bird, etc.)
- [ ] **LanguagePack** struct containing vocabulary for each animal language
- [ ] **LanguageMetadata** with language info (name, region, confidence thresholds)
- [ ] Update TranslationDirection enum to support multi-language

### T02: Multi-Language Translation Adapter
- [ ] Create **MultiLanguageAdapter** wrapping AITranslationService
- [ ] Implement `translate(input:language:direction:)` method
- [ ] Support language-specific translation logic
- [ ] Add fallback chain: AI → Vocabulary → Simple

### T03: Language Detection & Routing
- [ ] **LanguageDetectionManager** for detecting animal language from audio
- [ ] **LanguageRoutingService** for routing translations to correct adapter
- [ ] Implement confidence-based language selection
- [ ] Manual override capability for users

### T04: UI for Language Selection
- [ ] **LanguageSelectionView** for picking animal language
- [ ] **LanguageListCell** custom cell for language items
- [ ] **LanguageSettingsViewController** for managing preferences
- [ ] Persist selected language with UserDefaults

### T05: Testing with Multiple Languages
- [ ] Unit tests for each animal language adapter
- [ ] Language detection accuracy tests
- [ ] Integration tests with RealTranslationController
- [ ] UI tests for language selection flow

---

## Technical Design

### Architecture

```
MultiLanguageTranslationService
├── LanguageDetectionManager      → Detects animal language from audio input
├── LanguageRoutingService       → Routes to correct adapter
├── MultiLanguageAdapter         → Wraps AITranslationService
│   ├── DogLanguageAdapter       → Dog-specific translation
│   ├── CatLanguageAdapter       → Cat-specific translation
│   └── BirdLanguageAdapter      → Bird-specific translation
└── LanguageStorageManager       → Persists language preferences
```

### Data Models

```swift
enum AnimalLanguage: String, CaseIterable {
    case dog = "dog"
    case cat = "cat"
    case bird = "bird"
    
    var displayName: String
    var vocabularyPack: LanguagePack
}

struct LanguagePack {
    let language: AnimalLanguage
    let humanToAnimal: [String: String]
    let animalToHuman: [String: String]
    let audioPatterns: [String]
}
```

### Integration Points

1. **AITranslationService** (S01) - Use as foundation, extend with language parameter
2. **RealTranslationController** (S02) - Integrate language detection into real-time pipeline
3. **TranslationViewController** - Add language selection UI

---

## File Structure

New files to create:
- `WoofTalk/AnimalLanguages.swift` - Language enum and models
- `WoofTalk/LanguagePack.swift` - LanguagePack data structures
- `WoofTalk/MultiLanguageAdapter.swift` - Main translation adapter
- `WoofTalk/LanguageDetectionManager.swift` - Language detection
- `WoofTalk/LanguageRoutingService.swift` - Routing service
- `WoofTalk/LanguageSelectionView.swift` - UI component
- `WoofTalk/LanguageSelectionViewController.swift` - Settings VC
- `WoofTalk/LanguageStorageManager.swift` - Persistence
- `WoofTalkTests/MultiLanguageTests.swift` - Unit tests

---

## Acceptance Criteria

1. ✅ System supports at least 3 animal languages (Dog, Cat, Bird)
2. ✅ Language can be selected via UI and persisted
3. ✅ Translation works with selected language
4. ✅ Language detection identifies animal sounds
5. ✅ Extensible architecture allows adding new languages without modifying core
6. ✅ All tests pass
7. ✅ Build succeeds

---

## Estimated Effort

- **T01:** 2 hours
- **T02:** 3 hours
- **T03:** 2 hours
- **T04:** 2 hours
- **T05:** 2 hours

**Total:** ~11 hours
