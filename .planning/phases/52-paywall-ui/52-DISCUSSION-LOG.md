# Phase 52: Paywall UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 52-paywall-ui
**Areas discussed:** Paywall entry points, iOS RevenueCatUI approach, Web paywall layout, Purchase confirmation UX

---

## Paywall Entry Points

| Option | Description | Selected |
|--------|-------------|----------|
| Settings only | Single "Subscribe"/"Go Premium" button in Settings screen only | ✓ |
| Settings + Translation screen banner | Settings button + small banner/card on Translation screen for free users | |
| Multiple triggers | Settings + Translation banner + lock icon taps (Phase 53) all route to same paywall | |

**User's choice:** Settings only
**Notes:** Clean, uncluttered. Phase 53 handles soft-paywall nudges after hitting limits. This is just the user-initiated path.

### Settings UI for Subscription Row

| Option | Description | Selected |
|--------|-------------|----------|
| Subscription row | A "Subscription" row in the Settings list (like iOS Settings > Apple ID pattern) | ✓ |
| Premium banner at top | A "Go Premium" banner/card at top of Settings with CTA button | |
| Subscription section with status | A "Subscription" section with current plan info + "Manage"/"Upgrade" button | |

**User's choice:** Subscription row
**Notes:** Simple, expected pattern. Premium users see plan info; free users see subscribe action.

---

## iOS RevenueCatUI Approach

| Option | Description | Selected |
|--------|-------------|----------|
| RevenueCatUI templates | Pre-built, App Store compliant, configurable via dashboard. Fast to ship. | ✓ |
| Custom SwiftUI view | Full visual control but must handle StoreKit edge cases yourself | |
| You decide | Claude picks based on compliance risk vs customization | |

**User's choice:** RevenueCatUI templates
**Notes:** Android already has purchases-ui:9.9.0 in gradle. Same template approach across both mobile platforms.

---

## Web Paywall Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Full /subscribe page | Dedicated page, clean URL, deep-linkable | ✓ |
| Modal overlay | Feels integrated, less real estate, harder to deep-link | |
| Page + modal | Both approaches, more code | |

**User's choice:** Full /subscribe page

### Web Checkout Window Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| New tab redirect | RevenueCat hosted checkout opens in new tab. User returns to WoofTalk tab. | ✓ |
| Same tab redirect | User leaves WoofTalk, completes Stripe, RevenueCat redirects back | |
| You decide | Claude picks best based on constraints | |

**User's choice:** New tab redirect

---

## Purchase Confirmation UX

| Option | Description | Selected |
|--------|-------------|----------|
| Dismiss to Settings | Loading spinner → entitlement confirmed → dismiss paywall, return to Settings. Subscription row updates. | ✓ |
| Success screen before dismiss | Brief "Welcome to Pro!" screen with checkmark before returning | |
| Toast notification | Dismiss with toast "You're now a Pro subscriber!" | |

**User's choice:** Dismiss to Settings
**Notes:** Minimal. EntitlementManager drives loading/completion state. All platforms follow same flow.

---

## Claude's Discretion

- Exact RevenueCatUI template selection and dashboard configuration
- Web /subscribe page visual design
- Error states for purchase failures, unavailable offerings, network errors
- Restore purchases button placement
- "Save 33%" badge visual treatment
- iOS Podfile/SPM addition for RevenueCatUI
- Web: checkout return detection (polling vs listener)

## Deferred Ideas

None — discussion stayed within phase scope
