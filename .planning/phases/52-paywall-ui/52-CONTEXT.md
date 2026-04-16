# Phase 52: Paywall UI - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Platform-native paywalls displaying subscription offerings (monthly $4.99/mo, annual $39.99/yr) and completing purchases on iOS, Android, and Web. iOS uses RevenueCatUI templates with StoreKit-only purchases. Android uses RevenueCatUI with Play Billing. Web uses custom React /subscribe page with RevenueCat hosted checkout (Stripe) in new tab. Does NOT include feature gating or soft-paywall triggers (Phase 53) or cross-platform sync (Phase 54).

</domain>

<decisions>
## Implementation Decisions

### Paywall Entry Points
- **D-01:** Paywall accessible only from Settings screen via "Subscription" row. Tapping the row opens the platform-native paywall. No banners, CTAs, or subscribe buttons on other screens. (Phase 53 handles soft-paywall nudges after hitting limits.)
- **D-02:** Settings "Subscription" row is a standard list row (like iOS Settings > Apple ID pattern). Simple, expected, not visually prominent. Premium users see current plan info; free users see "Subscribe" action.

### iOS RevenueCatUI Approach
- **D-03:** Use RevenueCatUI pre-built template paywalls on iOS. Faster to ship, App Store compliant by default, handles edge cases (loading, errors, restore). Limited visual customization acceptable. Configurable via RevenueCat dashboard.
- **D-04:** Android also uses RevenueCatUI (`purchases-ui:9.9.0` already in gradle). Same template approach across both mobile platforms.

### Web Paywall Layout
- **D-05:** Dedicated `/subscribe` page (Next.js app route). Full layout, clean URL, deep-linkable. Displays offerings from `getOfferings()` and presents monthly/annual plans.
- **D-06:** RevenueCat hosted checkout (Stripe) opens in a new browser tab. User completes payment there, then returns to WoofTalk tab. Entitlement state updates via `customerInfoUpdated` listener after checkout completes.

### Purchase Confirmation UX
- **D-07:** After purchase: loading spinner on paywall until entitlement confirmed via EntitlementManager. On confirmation: dismiss paywall, return to Settings. Subscription row now reflects "Pro" status. No success screen, no toast — minimal.
- **D-08:** All platforms follow same flow: loading → confirmed → dismiss. EntitlementManager drives the loading/completion state (it already has `isLoading` flag).

### Claude's Discretion
- Exact RevenueCatUI template selection and dashboard configuration
- Web /subscribe page visual design (within Tailwind + existing patterns)
- Error states: what happens when purchase fails, offerings unavailable, network error
- Restore purchases button placement within paywall (PAY-07 requires it on all platforms)
- "Save 33%" badge visual treatment on annual plan (PAY-05)
- How subscription status displays in Settings row for premium vs free users
- iOS Podfile / SPM addition for RevenueCatUI (not currently in repo)
- Web: how to detect when user returns from new-tab checkout (polling vs listener)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### RevenueCat Integration
- `.planning/research/STACK.md` — SDK versions, purchases-ui package details, hosted checkout setup
- `.planning/research/ARCHITECTURE.md` — Data flow diagrams, paywall interaction sequence, build order
- `.planning/research/PITFALLS.md` — Pitfall 1 (App Store rejection for external payment links), Pitfall 5 (web checkout return handling)

### Existing Codebase Patterns
- `WoofTalk/Backend/RevenueCatManager.swift` — iOS SDK init, PurchasesDelegate, logIn/logOut
- `WoofTalk/EntitlementManager.swift` — iOS entitlement state, isReadyToAccessPaywall, CustomerInfoUpdated notification
- `android/WoofTalk/app/src/main/java/com/wooftalk/EntitlementManager.kt` — Android entitlement state, UpdatedCustomerInfoListener
- `web/src/lib/entitlement-store.ts` — Web Zustand store with isPremium, isTrialActive, isReadyToAccessPaywall
- `web/src/lib/revenuecat.ts` — Web SDK init, loginRevenueCat, refreshEntitlements
- `web/src/providers/EntitlementProvider.tsx` — React provider wiring SDK → Zustand store

### Prior Phase Context
- `.planning/phases/50-revenuecat-sdk-integration/50-CONTEXT.md` — SDK init decisions, EntitlementManager wrapper spec, product IDs
- `.planning/phases/51-subscription-backend/51-CONTEXT.md` — subscription_status schema, entitlement verification, RLS policies

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **EntitlementManager (all 3 platforms)**: Already provides `isPremium`, `isTrialActive`, `isReadyToAccessPaywall`, `isLoading`. Paywall can observe these for loading/completion state.
- **RevenueCatManager (iOS)**: SDK configured, PurchasesDelegate wired, logIn/logOut working. Paywall just needs to present RevenueCatUI.
- **purchases-ui:9.9.0 (Android)**: Already in gradle dependencies. RevenueCatUI Android available.
- **revenuecat.ts + entitlement-store.ts (Web)**: SDK init, auth linking, Zustand store all working. Paywall page reads offerings and routes to hosted checkout.
- **Settings screens exist on all platforms**: iOS `SettingsView`, Android `SettingsScreen.kt`, Web `settings/page.tsx`. Add Subscription row to each.

### Established Patterns
- **iOS**: SwiftUI `@MainActor`, `ObservableObject`, `NotificationCenter` for CustomerInfo updates. RevenueCatUI uses `PaywallView` presentation.
- **Android**: Compose + Hilt, `StateFlow` for state, MVVM. RevenueCatUI uses `Paywall` composable.
- **Web**: Next.js 15 app router, Tailwind CSS, Zustand stores, shadcn/ui not yet installed but Tailwind available.
- **All platforms**: `getOfferings()` fetches current products. Product IDs: `wooftalk_monthly`, `wooftalk_annual`. Entitlement: `pro`.

### Integration Points
- **iOS Settings**: Add Subscription row. On tap, present RevenueCatUI PaywallView as sheet or full-screen cover.
- **Android Settings**: Add Subscription row in `SettingsScreen.kt`. On tap, navigate to RevenueCatUI Paywall composable.
- **Web Settings**: Add Subscription link in `settings/page.tsx`. Links to `/subscribe` page.
- **Web /subscribe**: New page at `web/src/app/subscribe/page.tsx`. Reads offerings from RevenueCat JS SDK, displays plans, opens hosted checkout URL in new tab.
- **All platforms**: After purchase confirmation, EntitlementManager updates `isPremium = true`. Settings Subscription row reflects new status.

</code_context>

<specifics>
## Specific Ideas

- Product IDs: `wooftalk_monthly`, `wooftalk_annual` — must match RevenueCat dashboard
- Entitlement ID: `pro` — single entitlement that unlocks all premium features
- Annual plan shows "Save 33%" badge (PAY-05)
- 7-day free trial included with both plans (PAY-04)
- Restore purchases button on all paywalls (PAY-07)
- Products verified via getOfferings() before paywall displayed — no stale offerings (PAY-09)
- iOS paywall fully compliant with App Store Guideline 3.1.1 — no external payment links, no "cheaper on web" text (PAY-06)
- Loading state shown after purchase until entitlement confirmed (PAY-08)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 52-paywall-ui*
*Context gathered: 2026-04-16*
