# Phase 45: Performance Hot Paths - Plan

## Plans

### Plan 1: Connect TranslationCache to TranslationEngine
**Type:** Feature addition
**Description:** Add cache lookup before translation and cache storage after translation in TranslationEngine

### Plan 2: Fix LanguageDetectionManager O(n²) nested loop
**Type:** Performance fix
**Description:** Pre-compute frequency bin ranges per language so AudioAnalyzer doesn't iterate all languages per sample

### Plan 3: Optimize translateSimplePhrase
**Type:** Performance fix
**Description:** Replace linear dictionary scan with static let constant

### Plan 4: Fix TranslationCache statistics semantics
**Type:** Bug fix
**Description:** totalTranslations should count unique entries, not increment on every access

## Execution Order

1. Plan 1 (cache connection) - highest impact
2. Plan 2 (O(n²) fix) - critical hot path
3. Plan 3 (phrase map optimization) - quick win
4. Plan 4 (stats fix) - correctness

## Success Criteria (for VERIFICATION.md)

1. TranslationCache is called from TranslationEngine (evidence: `TranslationCache` referenced in TranslationEngine.swift)
2. LanguageDetectionManager no longer has nested language iteration in analyzeFrequencies (evidence: pre-computed at init time)
3. translateSimplePhrase uses static dictionary (evidence: `static let` in file)
4. Cache statistics semantics are correct (evidence: totalTranslations counts unique, not total calls)
