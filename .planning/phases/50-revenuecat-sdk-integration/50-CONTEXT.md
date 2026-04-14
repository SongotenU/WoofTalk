# Phase 50: RevenueCat SDK Integration - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Initialize RevenueCat SDK on iOS, Android, and Web with Supabase auth.uid identity linking. Provide a single EntitlementManager wrapper on each platform for checking subscription state. Ensure PurchasesDelegate/listener fires on CustomerInfo updates. Enforce login before paywall. After purchase, force entitlement refresh. No paywall UI or feature gating — those are Phase 52 and 53.

</domain>

<decisions>
## Implementation Decisions

### SDK Init Timing
- **D-01:** Initialize RevenueCat SDK at app launch with placeholder/anonymous config. Call `logIn(auth.uid)` after Supabase auth completes. Paywall unavailable until auth resolves.
- **D-02:** Call `logIn(auth.uid)` on every app launch — ensures identity is always correct. RevenueCat handles duplicate calls gracefully (no-op if same user).

### Entitlement Check UX
- **D-03:** Free-tier users see full UI with lock icons on premium features. Does not hide premium features — shows what they're missing to drive upgrades.
- **D-04:** Single EntitlementManager class on each platform wrapping `CustomerInfo`. Provides `isPremium`, `isTrialActive`, `dailyTranslationsUsed`, `subscriptionTier`. All views call this one source — no direct `CustomerInfo` access.

### Offline Entitlement Policy
- **D-05:** Trust cached `CustomerInfo` when offline. If cache says premium, treat as premium. If cache says free, treat as free. No warning banner, no blocking. RevenueCat SDK caches locally already.

### Claude's Discretion
- Exact file names and package structure for EntitlementManager on each platform
- iOS: where to place SDK init in SwiftUI app lifecycle
- Android: Hilt module structure for RevenueCat dependency injection
- Web: Zustand store integration pattern for entitlement state
- Error handling patterns for SDK init failures
- Logging/debugging patterns for entitlement state changes

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### RevenueCat SDK Integration
- `.planning/research/STACK.md` — SDK versions, installation methods, integration points per platform
- `.planning/research/ARCHITECTURE.md` — Data flow diagrams, build order, key technical decisions
- `.planning/research/PITFALLS.md` — Pitfall 2 (stale entitlement cache) and Pitfall 4 (cross-platform desync) are directly relevant to Phase 50

### Existing Codebase Patterns
- `Android/WoofTalk/app/build.gradle.kts` — Gradle dependencies and Hilt DI setup
- `Web/package.json` — Web dependencies and Zustand state management
- `Web/src/lib/supabase.ts` — Supabase client initialization pattern on Web
- `supabase/functions/` — Existing Edge Function patterns for reference

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Supabase auth**: All platforms already have Supabase auth integration. `auth.uid` is the user identifier that maps to RevenueCat `appUserID`.
- **Zustand store** (Web): `Web/package.json` includes zustand ^5.0.3 — entitlement state can be a Zustand store.
- **Hilt DI** (Android): Android app uses Hilt for dependency injection — RevenueCat can be a Hilt module.
- **6 Edge Functions** exist in `supabase/functions/` — pattern for new entitlement-check and entitlement-webhook functions.

### Established Patterns
- **Android**: Kotlin + Compose, Hilt DI, MVVM architecture, Room DB
- **Web**: Next.js 15, React 19, Zustand state, Tailwind + shadcn/ui, Supabase JS v2
- **iOS**: SwiftUI (standalone Xcode project, not in repo root — Package.swift is AR target only)
- **Supabase**: PostgreSQL, RLS policies, Edge Functions (Deno)

### Integration Points
- **iOS**: SDK init in `@main` App struct. EntitlementManager as ObservableObject/EnvironmentObject.
- **Android**: SDK init in Application class via Hilt module. EntitlementManager as ViewModel/state.
- **Web**: SDK init in layout/provider. EntitlementManager as Zustand store + React context.
- **All platforms**: `logIn(auth.uid)` called after Supabase auth resolves on each launch.

</code_context>

<specifics>
## Specific Ideas

- RevenueCat SDK versions: iOS 5.43.0+, Android 9.9.0+, Web @revenuecat/purchases-js 1.0+
- iOS uses RevenueCatUI for paywalls (Phase 52), but Phase 50 only needs core SDK + RevenueCatUI dependency
- Product IDs: `wooftalk_monthly`, `wooftalk_annual` — must match across RevenueCat, App Store Connect, and Play Console
- Entitlement ID: `pro` — single entitlement that unlocks all premium features

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 50-revenuecat-sdk-integration*
*Context gathered: 2026-04-14*
