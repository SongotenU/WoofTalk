# Phase 27: Watch Core - Context

**Gathered:** 2026-03-31
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase creates a Wear OS companion app for WoofTalk. The watch app provides quick translation via voice input, glanceable result display, translation history access, and sync with the phone app via Supabase. It is NOT a standalone app — requires phone for full features. Uses Kotlin + Compose for Wearables.

</domain>

<decisions>
## Implementation Decisions

### Architecture
- Wear OS app using Kotlin + Jetpack Compose for Wearables
- Shares translation engine logic with Android phone app (reuse Kotlin code)
- Supabase Kotlin SDK for cloud sync
- SpeechRecognizer for voice input (optimized for watch mic)

### UI Pattern
- Single-screen translation flow: tap → speak → see result
- Glanceable result display with large text
- Horizontal swipe navigation between: translate, history, settings
- Watch face complication for quick launch

### Sync Strategy
- Supabase for cloud sync (same backend as phone/web)
- Watch reads user's translation history from cloud
- Watch translations upload to cloud for cross-platform visibility

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `android/WoofTalk/app/src/main/java/com/wooftalk/domain/` — Translation engine, language adapters
- `android/WoofTalk/app/src/main/java/com/wooftalk/data/` — Data layer patterns (Room, Supabase)
- Supabase backend already configured (Phase 19)
- Android app uses Hilt for DI, can follow same pattern

### Established Patterns
- Kotlin + Jetpack Compose for UI
- Repository pattern for data access
- Supabase client for backend operations
- Hilt dependency injection

### Integration Points
- New Wear OS module within existing Android project
- Shares domain layer (translation engine) with phone app
- Same Supabase project for backend
- Watch face complication via TileService/ComplicationService

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond ROADMAP success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — stayed within phase scope.

</deferred>
