# Phase 26: Web Voice & Community - Context

**Gathered:** 2026-03-31
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase adds voice I/O, community features, social interactions, and cross-platform sync to the existing Next.js web app built in Phase 25. It extends the translate page with voice capabilities, adds new routes for community browsing and social features, and ensures real-time sync across iOS, Android, and Web platforms.

</domain>

<decisions>
## Implementation Decisions

### Voice I/O Implementation
- Speech recognition uses Web Speech API (SpeechRecognition) — native, no dependencies
- Voice output uses Web Speech API (SpeechSynthesis) with configurable speed/pitch via SpeechSynthesisUtterance
- Voice UI as mic button on translate page with visual waveform feedback and auto-stop on silence
- Graceful degradation: hide voice features when Speech API unavailable, show text-only mode

### Community & Social UI Structure
- Separate route pages: `/community`, `/community/contribute`, `/social`, `/leaderboard` — matches existing app routing
- shadcn/ui component library — per PROJECT.md, consistent with Tailwind setup
- Supabase client-side subscriptions — use existing `fetchCommunityPhrases` from supabase.ts, add realtime channels
- Phrase browser: card grid with search/filter bar — responsive for web, matches Android pattern

### Spam Detection & Validation
- Port Android SpamDetectionService to TypeScript — battle-tested, >80% accuracy target
- Validation: client-side + Supabase Edge Function — fast client validation, server-side safety net
- Phrase submission: modal form from community page — quick submit without leaving context

### Cross-Platform Sync Strategy
- Real-time sync via Supabase Realtime channels — already configured in backend
- Offline handling: localStorage queue + sync on reconnect — matches PWA offline strategy
- Auth state: shared Supabase auth session — same credentials, unified profile across platforms

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `web/src/lib/supabase.ts` — Supabase client, auth functions, `fetchCommunityPhrases` already exists
- `web/src/lib/translation/` — Translation engine, cache, language adapters (dog/cat/bird)
- `web/src/app/translate/page.tsx` — Existing translate page to extend with voice button
- `web/src/app/layout.tsx` — Root layout with Inter font, PWA manifest configured
- `web/tailwind.config.ts` — Tailwind config with primary/secondary theme tokens

### Established Patterns
- Client components with "use client" directive for interactive pages
- Tailwind CSS with semantic tokens (bg-background, text-primary, etc.)
- Supabase client-side auth and data operations
- State management via React useState hooks
- Navigation via Next.js Link components

### Integration Points
- `/translate` page — add mic button for voice input, TTS button for voice output
- `web/src/lib/supabase.ts` — extend with community phrase CRUD, social operations
- Supabase backend (from Phase 19) — 8 tables, 30+ RLS policies, realtime channels ready
- Android SpamDetectionService (`android/WoofTalk/app/src/main/java/com/wooftalk/domain/usecase/SpamDetectionService.kt`) — port to TypeScript

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond ROADMAP success criteria — open to standard approaches following established codebase patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
