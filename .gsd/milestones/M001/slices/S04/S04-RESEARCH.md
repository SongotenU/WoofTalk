# S04: Offline Mode

**Vision:** Enable core translation functionality without internet connection, supporting 80% of essential dog-human vocabulary phrases.

**Status:** Research

## Key Findings

### Codebase Structure
- **Audio Processing:** `audio_engine.ts` with `AudioEngine` class (from S01)
- **Translation Engine:** `translation_engine.ts` with `TranslationEngine` class (from S02)
- **UI Components:** `ui/main_view_controller.swift`, `ui/translation_view_controller.swift` (from S03)

### Requirements Analysis
- **R003: Offline Capability** - Active requirement for basic translation without internet
- **R002: Comprehensive Vocabulary** - Need 5000+ phrases, but offline should support core subset

### Technical Constraints
- **Storage:** SQLite for efficient caching (Decision D008)
- **Audio:** 44.1 kHz, 16-bit PCM format (Decision D013)
- **Latency:** Must maintain <2 seconds real-time translation (Decision D011)

## Research Questions

### 1. Data Model for Offline Storage
- What translation data needs to be cached? (phrases, models, metadata)
- How to structure SQLite schema for efficient lookup?
- How to handle model updates and versioning?

### 2. Performance Requirements
- What's the size of 5000 phrases in SQLite? (~500KB-1MB)
- How fast can we query SQLite for translation lookups?
- Can we pre-cache commonly used phrases?

### 3. Fallback Logic
- How to detect offline vs online state?
- What's the fallback behavior when offline?
- How to handle missing phrases in offline mode?

### 4. iOS Integration
- How to integrate SQLite with Swift/Objective-C code?
- What's the best way to manage offline storage lifecycle?
- How to handle storage limits and cleanup?

## Technology Research

### SQLite on iOS
- **Framework:** SQLite3 C library with Swift/Objective-C bindings
- **Alternatives:** Core Data (heavier), Realm (third-party)
- **Recommendation:** SQLite3 for simplicity and control

### Offline Detection
- **Reachability:** Network framework for connectivity status
- **Caching Strategy:** Time-based cache invalidation (e.g., 24-hour freshness)
- **Storage Limits:** iOS app sandbox limits (100MB-1GB typical)

## Architecture Sketch

```
OfflineManager
├── detectOfflineStatus() → Bool
├── loadCachedTranslations() → [Phrase]
├── cacheTranslations(phrases: [Phrase]) → Void
├── getTranslation(key: String) → String?
└── handleMissingPhrase(key: String) → String

SQLite Schema
├── phrases(id, key, human_text, dog_text, category, last_updated)
├── models(id, name, version, data_blob, last_updated)
└── metadata(key, value)
```

## Risks & Unknowns

### High Priority
- **Storage Size:** 5000 phrases + models might exceed reasonable limits
- **Cache Invalidation:** How to keep offline data fresh without internet?
- **Fallback Quality:** Offline translations might be significantly worse

### Medium Priority
- **Performance:** SQLite queries might add latency to real-time translation
- **Storage Management:** Need cleanup strategy for old/unused phrases
- **User Experience:** How to communicate offline limitations to users?

## Next Steps

1. **Schema Design:** Define SQLite tables and relationships
2. **Data Migration:** Extract translation data from existing sources
3. **Offline Manager:** Implement core offline functionality
4. **Integration:** Hook into existing translation flow
5. **Testing:** Verify offline mode works correctly

## Key Decisions Needed

- **Cache Strategy:** Full phrases vs. model-based generation
- **Storage Limits:** What's the maximum offline data size?
- **Fallback Behavior:** Graceful degradation vs. hard limits
- **Update Mechanism:** How to refresh offline data when back online

## Success Criteria

- Core 80% of phrases work offline
- Offline detection is reliable
- Fallback behavior is intuitive
- Storage usage stays within limits
- No regression in online performance

## Dependencies

- S03: UI components for offline mode interface
- S02: Translation engine for data extraction
- S01: Audio processing for offline audio handling

## Files to Create/Modify

```
offline_storage/
├── sqlite_manager.ts
├── phrase_cache.ts
└── offline_database.ts

offline_manager/
├── offline_manager.ts
└── connectivity_manager.ts

ui/
├── offline_mode_view_controller.swift
└── connectivity_indicator.swift
```

## Forward Intelligence

### What's Fragile
- **Storage Budget:** Must carefully monitor SQLite database size
- **Cache Coherence:** Offline data might become stale without updates
- **Performance Impact:** SQLite queries could affect real-time latency

### What Changed Since Planning
- No major changes detected in requirements or dependencies
- Audio processing foundation is solid (S01 completed)
- Translation engine is functional (S02 completed)

### What to Watch For
- Storage size monitoring during development
- Performance regression in translation latency
- Edge cases when switching between online/offline modes

## Research Complete

Slice S04 researched.