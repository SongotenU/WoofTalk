# S04: Offline Mode

**Goal:** Enable core translation functionality without internet connection, supporting 80% of essential dog-human vocabulary phrases.
**Demo:** App works in airplane mode with core translation features available.

## Must-Haves

- Core 80% of translation phrases work offline
- Reliable offline/online detection
- Intuitive fallback behavior when offline
- Storage usage stays within reasonable limits
- No regression in online translation performance

## Proof Level

- This slice proves: operational
- Real runtime required: yes
- Human/UAT required: yes

## Verification

- `npm test -- --grep "offline mode"` (or equivalent iOS test suite)
- `bash scripts/verify-offline.sh` — verifies offline functionality works
- Manual testing: toggle airplane mode and verify core translation still works

## Observability / Diagnostics

- Runtime signals: SQLite query performance, cache hit/miss ratios
- Inspection surfaces: `sqlite3` CLI for database inspection, debug logs for offline state
- Failure visibility: Offline detection status, missing phrase logging, storage usage metrics
- Redaction constraints: No PII in logs, sanitize sensitive data

## Integration Closure

- Upstream surfaces consumed: translation_engine.ts, audio_engine.ts, UI components
- New wiring introduced: OfflineManager integration into translation flow, connectivity indicators
- What remains before milestone is usable: App Store metadata and compliance (S05)

## Tasks

- [x] **T01: SQLite Database Setup** `est:1h`
  - Why: Establish offline storage foundation for caching translations
  - Files: `offline_storage/sqlite_manager.ts`, `offline_storage/offline_database.ts`
  - Do: Implement SQLite3 connection, create phrases table schema, basic CRUD operations
  - Verify: Database creation succeeds, schema is correct, basic queries work
  - Done when: SQLite database is operational and can store/retrieve phrases
- [x] **T02: Offline Manager Core** `est:2h`
  - Why: Implement core offline detection and fallback logic
  - Files: `offline_manager/offline_manager.ts`, `offline_manager/connectivity_manager.ts`
  - Do: Implement offline detection, translation caching, fallback behavior, storage limits
  - Verify: Offline detection works, cached translations are returned when offline
  - Done when: Offline manager correctly handles online/offline state and provides fallbacks
- [x] **T03: Integration with Translation Engine** `est:1.5h`
  - Why: Wire offline functionality into existing translation flow
  - Files: `translation_engine.ts`, `offline_manager.ts`, `ui/main_view_controller.swift`
  - Do: Modify translation engine to use offline manager, add connectivity indicators
  - Verify: Translation works both online and offline seamlessly
  - Done when: Users can translate without internet for core phrases
- [x] **T04: UI Offline Mode Interface** `est:1h`
  - Why: Provide visual feedback for offline state and limitations
  - Files: `ui/offline_mode_view_controller.swift`, `ui/connectivity_indicator.swift`
  - Do: Implement offline mode UI, connectivity status indicators, offline limitations display
  - Verify: UI correctly shows offline state and available features
  - Done when: Users understand when they're offline and what's available

## Files Likely Touched

- `offline_storage/sqlite_manager.ts`
- `offline_storage/offline_database.ts`
- `offline_manager/offline_manager.ts`
- `offline_manager/connectivity_manager.ts`
- `translation_engine.ts`
- `ui/main_view_controller.swift`
- `ui/offline_mode_view_controller.swift`
- `ui/connectivity_indicator.swift`