# Phase 53: Feature Gating & Soft Paywall - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Free tier limits enforced on all platforms with non-blocking upgrade paths. Server-side RLS already enforces 3 translations/day (Phase 51, SUB-08). This phase adds client-side enforcement UX, history limits, premium feature gates (AI translation, community contribution, export/share), upgrade prompts after hitting limits, lock icons on premium features, and Watch app entitlement inheritance. Does NOT include paywall UI (Phase 52) or cross-platform sync (Phase 54).

</domain>

<decisions>
## Implementation Decisions

### EntitlementManager Integration
- **D-01:** EntitlementManager already provides isPremium, isTrialActive, dailyTranslationsUsed on all platforms (Phase 50). This phase consumes those properties for UI gating — no new manager code needed, only UI components that read from it.
- **D-02:** Server-side RLS is the hard gate for translation limits (3/day). Client-side is UX-only — shows the upgrade prompt before the server would reject. Client never blocks a request the server would allow.

### Upgrade Prompt Design
- **D-03:** After the 3rd translation in a day, free users see a non-blocking upgrade prompt (bottom sheet / modal) with "Upgrade" button that navigates to the paywall entry point from Phase 52. User can dismiss it.
- **D-04:** Lock icons on premium features (AI translation, community contribution, export/share). Tapping a locked feature shows the same upgrade prompt.

### History Limit
- **D-05:** Free users see only the last 10 history items. Implementation: filter on the client side using the existing history query. No server-side limit needed — the full history is synced, we just don't display it all for free users.

### Watch App
- **D-06:** Watch app inherits phone subscription status via EntitlementManager (same Supabase auth.uid, same RevenueCat identity). No separate purchase or entitlement check. Watch features are gated the same way as phone — read isPremium from EntitlementManager.

### Claude's Discretion
- Exact UI design of upgrade prompt (bottom sheet vs modal vs inline banner)
- Lock icon visual treatment (icon overlay, disabled state, etc.)
- How to count daily translations on client (EntitlementManager.dailyTranslationsUsed already tracks this)
- History filter implementation details (query limit vs client-side slice)

</decisions>

<canonical_refs>
## Canonical References

### RevenueCat Integration
- `.planning/research/STACK.md` — SDK versions, entitlement checking patterns
- `.planning/research/ARCHITECTURE.md` — Data flow diagrams, feature gating sequence

### Existing Codebase Patterns
- `WoofTalk/EntitlementManager.swift` — iOS entitlement state with dailyTranslationsUsed
- `android/WoofTalk/app/src/main/java/com/wooftalk/EntitlementManager.kt` — Android entitlement state
- `web/src/lib/entitlement-store.ts` — Web Zustand store with isPremium, dailyTranslationsUsed
- Phase 52 paywall entry points on all platforms

### Prior Phase Context
- `.planning/phases/51-subscription-backend/51-CONTEXT.md` — RLS policies for translation_requests (3/day limit)
- `.planning/phases/52-paywall-ui/52-CONTEXT.md` — Paywall entry points from Settings

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **EntitlementManager (all platforms)**: Already provides isPremium, isTrialActive, dailyTranslationsUsed. Feature gates read from these.
- **RLS policy (Phase 51)**: Server already enforces 3 translation_requests INSERTs per day for free users. Client just needs to show a friendly prompt before the server rejects.
- **Paywall entry points (Phase 52)**: iOS Settings row → PaywallView, Android Settings row → Paywall composable, Web Settings → /subscribe. Upgrade prompt navigates to these.

### Integration Points
- **iOS TranslationView**: After translation completes, check dailyTranslationsUsed. If >= 3 and !isPremium, show upgrade prompt.
- **Android TranslationScreen**: Same pattern as iOS.
- **Web translate page**: Same pattern.
- **History views (all platforms)**: Filter to last 10 items for free users.
- **AI translation toggle (all platforms)**: Disable for free users, show lock icon.
- **Community contribution (all platforms)**: Disable submit for free users.
- **Export/share (all platforms)**: Disable for free users.

</code_context>

<specifics>
## Specific Ideas

- 3 translations/day for free users — server-enforced via RLS (SUB-08), client shows upgrade prompt at limit
- Last 10 history items for free users — client-side filter
- AI translation, community contribution, export/share — premium only
- Upgrade prompt: non-blocking, dismissible, links to paywall entry point
- Lock icons on premium features when user is on free tier
- Watch app reads isPremium from EntitlementManager — no separate logic

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 53-feature-gating*
*Context gathered: 2026-04-17*
