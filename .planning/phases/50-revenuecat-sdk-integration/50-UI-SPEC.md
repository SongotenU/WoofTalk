---
phase: 50
slug: revenuecat-sdk-integration
status: draft
shadcn_initialized: true
preset: existing
created: 2026-04-15
---

# Phase 50 — UI Design Contract

> Visual and interaction contract for Phase 50: RevenueCat SDK Integration.
> This phase is primarily SDK/backend — UI scope is limited to entitlement state indicators and auth gating.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | shadcn/ui (already installed) |
| Preset | Existing WoofTalk design system |
| Component library | Radix UI (via shadcn) |
| Icon library | Lucide React |
| Font | System (existing) |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: none

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14px | 400 | 1.5 |
| Label | 12px | 500 | 1.4 |
| Heading | 20px | 600 | 1.3 |
| Display | 28px | 700 | 1.2 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #FFFFFF | Background, surfaces |
| Secondary (30%) | #F8FAFC | Cards, sidebar, nav |
| Accent (10%) | #6366F1 (indigo-500) | Premium badges, subscription CTA, lock icons |
| Destructive | #EF4444 | Cancellation warnings only |

Accent reserved for: premium status indicators, subscription upgrade prompts, lock icons on premium features

---

## Phase 50 UI Scope

Phase 50 is **SDK integration only** — no paywall UI or feature gating UI. The visual elements are:

### 1. Entitlement State Indicator (Web only — minimal)
- Zustand store holds entitlement state
- No dedicated UI component in this phase
- State consumed by future paywall/gating components (Phase 52/53)

### 2. Auth-Gated Access (All platforms)
- If user is unauthenticated, paywall route is blocked (SDK-06)
- iOS: Navigation guard preventing paywall view
- Android: Compose navigation guard
- Web: Next.js middleware or route guard redirect

### 3. EntitlementManager Properties (All platforms)
- `isPremium: Boolean` — shows lock/unlock state
- `isTrialActive: Boolean` — trial indicator
- `dailyTranslationsUsed: Int` — usage counter
- `subscriptionTier: String` — "free" | "trial" | "pro"

No visual components are built in Phase 50 — only state management infrastructure.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Premium badge | "PRO" |
| Trial badge | "TRIAL" |
| Lock icon label | "Premium" |
| Auth required message | "Sign in to access premium features" |
| Entitlement loading | "Checking subscription..." |
| Entitlement error | "Unable to verify subscription. Please try again." |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | Badge, Skeleton | not required |
| Lucide icons | Lock, Crown, Shield | not required |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS (minimal — no visual components in this phase)
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
