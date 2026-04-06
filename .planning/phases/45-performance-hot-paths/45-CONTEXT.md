# Phase 45: Performance Hot Paths - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure/optimization phase)

<domain>
## Phase Boundary

Connect TranslationCache to TranslationEngine, fix LanguageDetectionManager O(n^2) nested loops, optimize string operations in translation pipeline, implement async cache with proper queueing.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — performance optimization phase. Success criteria derived from ROADMAP: cache connected, O(n^2) resolved, string ops optimized.

### Key Decisions
- TranslationEngine should use TranslationCache.shared for read-through caching
- LanguageDetectionManager frequency analysis should pre-compute language bin ranges instead of iterating languages per bin
- Cache should be async but translation API should remain synchronous with cache hits, async cache misses
- No API surface changes — all optimization is internal

</decisions>

<code_context>
## Existing Code Insights

### TranslationEngine.swift
- No reference to TranslationCache anywhere
- translateHumanToDog/dogToHuman try ML model → vocabulary → simple phrase → throw
- No caching layer between any of these steps

### TranslationCache.swift
- Fully implemented singleton with `shared` instance
- Has `cacheTranslation()` and `getCachedTranslation()` methods
- Thread-safe via DispatchQueue
- Has persistence (saveToDisk/loadFromDisk)
- Never called from TranslationEngine

### LanguageDetectionManager.swift
- `analyzeFrequencies()` iterates bins 0..<100, then for EACH bin iterates AnimalLanguage.allCases — nested loop
- `AudioAnalyzer.analyze()` does same pattern — for EACH sample iterates all languages
- `performLanguageDetection()` iterates frequencies dict again, then languages again

### Other Performance Issues
- `translateSimplePhrase()` has 24-entry hardcoded dictionary — lookup O(n) per call
- `cacheKey` generation does 3 string ops (lowercased, trimming, interpolation)
- Statistics updating does totalTranslations++ on every call even for cache hits (wrong semantics)

</code_context>

<specifics>
## Specific Ideas

1. Add cache layer to TranslationEngine: check cache → translate → store in cache
2. Pre-compute language→frequency bin mapping once at init time instead of per-call
3. Use Set or Dictionary for simple phrase lookup instead of array iteration

</specifics>

<deferred>
## Deferred Ideas

None — focused on concrete performance fixes from ROADMAP.

</deferred>
