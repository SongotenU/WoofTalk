# Phase 44: Structural Cleanup - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped, infrastructure phase)

<domain>
## Phase Boundary

Remove duplicate and dead code, consolidate enums, replace print() with os_log across iOS codebase.

Requirements:
- STRUCT-01: Remove duplicate `audio_processing/` directory
- STRUCT-02: Consolidate duplicate `TranslationDirection` enum
- STRUCT-03: Remove legacy direction reference
- STRUCT-04: Replace print() with os_log across 19+ iOS files

</domain>

<decisions>
## Implementation Decisions

### STRUCT-01: Delete snake_case audio_processing/
- Remove `WoofTalk/audio_processing/` entirely (10 files, ~1,166 lines)
- Keep canonical `WoofTalk/AudioProcessing/` (8 files, ~1,756 lines, PascalCase)
- Verify no imports reference snake_case versions before deletion

### STRUCT-02: Consolidate TranslationDirection
- `TranslationDirection` exists in both `TranslationEngine.swift` and `AITranslationService.swift`
- Create shared `TranslationModels.swift` with canonical enum
- Both files import from shared models

### STRUCT-03: Remove legacyDirection
- Remove `legacyDirection` variable from `MultiLanguageAdapter.swift`

### STRUCT-04: os_log replacement
- Replace `print("...")` calls with `os_log` using subsystem `com.wooftalk.app`
- Use appropriate log types: `.info`, `.default`, `.error`
</decisions>

<code_context>
## Existing Code Insights

### Files to verify before deletion
- Need to check if anything imports from `audio_processing/` (snake_case)
- Need to check both TranslationDirection definitions for which is canonical

### Xcode project
- `WoofTalk.xcodeproj` must be updated after file deletion
- File references in project.pbxproj need removal
</code_context>

<specifics>
No specific requirements beyond the 4 STRUCT requirements.
</specifics>

<deferred>
None.
</deferred>
