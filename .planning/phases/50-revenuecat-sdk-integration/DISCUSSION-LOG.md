# Discussion Log: Phase 50 — RevenueCat SDK Integration

**Date:** 2026-04-14
**Mode:** Discuss (interactive)

## Areas Discussed

### 1. SDK Init Timing
**Question:** When should RevenueCat SDK initialize and when should logIn(auth.uid) be called?

**Options presented:**
- Init early, logIn after auth
- Init after auth only
- Init with auth.uid from start

**Decision (D-01):** Init early with placeholder/anonymous config. Call `logIn(auth.uid)` after Supabase auth completes. Paywall unavailable until auth resolves.

**Follow-up (D-02):** Call `logIn(auth.uid)` on every app launch — ensures identity is always correct. RevenueCat handles duplicate calls gracefully (no-op if same user).

### 2. Entitlement Check UX
**Question:** How should premium features appear to free-tier users?

**Options presented:**
- Full UI with locks (Recommended)
- Hide premium features entirely
- Show preview with blur/overlay

**Decision (D-03):** Free-tier users see full UI with lock icons on premium features. Does not hide premium features — shows what they're missing to drive upgrades.

**Follow-up — Entitlement state access pattern:**
- Single EntitlementManager (Recommended)
- Direct CustomerInfo access per view
- Reactive store/stream pattern

**Decision (D-04):** Single EntitlementManager class on each platform wrapping `CustomerInfo`. Provides `isPremium`, `isTrialActive`, `dailyTranslationsUsed`, `subscriptionTier`. All views call this one source — no direct `CustomerInfo` access.

### 3. Offline Entitlement Policy
**Question:** How should the app behave when offline and entitlement cache may be stale?

**Options presented:**
- Trust cache (Recommended)
- Block premium features when offline
- Show warning banner, allow access

**Decision (D-05):** Trust cached `CustomerInfo` when offline. If cache says premium, treat as premium. If cache says free, treat as free. No warning banner, no blocking. RevenueCat SDK caches locally already.

## Areas Not Discussed

- Error handling patterns for SDK init failures — delegated to Claude's discretion
- Logging/debugging patterns for entitlement state changes — delegated to Claude's discretion
- Exact file names and package structure — delegated to Claude's discretion
- iOS SDK init placement in SwiftUI app lifecycle — delegated to Claude's discretion
- Android Hilt module structure — delegated to Claude's discretion
- Web Zustand store integration pattern — delegated to Claude's discretion

## Decisions Summary

| ID | Decision | Rationale |
|----|----------|-----------|
| D-01 | Init early, logIn after auth | SDK ready immediately; identity linked when auth resolves |
| D-02 | logIn on every launch | Ensures correct identity always; RevenueCat handles duplicates |
| D-03 | Full UI with locks | Shows value of premium; drives upgrades |
| D-04 | Single EntitlementManager | One source of truth; no direct CustomerInfo access |
| D-05 | Trust cached CustomerInfo offline | RevenueCat caches locally; no false negatives |

---

*Discussion completed: 2026-04-14*
