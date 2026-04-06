# Phase 44: Structural Cleanup - Plan

## Plans

### Plan 1: Remove duplicate audio_processing directory
**Description:** Delete the duplicate `audio_processing/` directory, keep only canonical `AudioProcessing/`

### Plan 2: Consolidate duplicate TranslationDirection enums
**Description:** Single enum in AITranslationService, remove nested enums from TranslationEngine, TranslationModels, TranslationCache

### Plan 3: Replace print() with os_log()
**Description:** Replace all `print()` calls with `os_log()` on production files; keep print() in Demo/Test fixtures

### Plan 4: Fix legacy references
**Description:** Rename `legacyDirection` to `translationDirection` in MultiLanguageAdapter
