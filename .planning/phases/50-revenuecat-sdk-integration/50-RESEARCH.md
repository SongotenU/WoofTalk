# Phase 50 Research: RevenueCat SDK Integration

**Phase:** 50 — RevenueCat SDK Integration
**Researched:** 2026-04-14
**Confidence:** HIGH
**Sources:** STACK.md, ARCHITECTURE.md, PITFALLS.md, codebase analysis

---

## 1. SDK Initialization Per Platform

### iOS (Swift/SwiftUI)

**SDK:** RevenueCat 5.43.0+ via Swift Package Manager
```swift
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.43.0")
```

**Init pattern (from CONTEXT D-01):**
- Configure with placeholder/anonymous in `@main` App struct `init()`
- Call `Purchases.shared.logIn(auth.uid)` after Supabase auth resolves
- Call `Purchases.shared.logIn(auth.uid)` on every launch (D-02)

**Key API:**
- `Purchases.configure(withAPIKey:appUserID:)` — SDK init
- `Purchases.shared.logIn(appUserID:)` — identity linking
- `Purchases.shared.getCustomerInfo()` — entitlement check
- `Purchases.shared.delegate` — CustomerInfo update listener

**EntitlementManager (from CONTEXT D-04):**
- `ObservableObject` / `@Published` properties for SwiftUI reactivity
- Provides: `isPremium`, `isTrialActive`, `dailyTranslationsUsed`, `subscriptionTier`
- Wraps `CustomerInfo.activeEntitlements` — no direct CustomerInfo access in views

**Integration points in codebase:**
- iOS is standalone Xcode project (not in repo root — Package.swift is AR target only)
- Existing Supabase auth provides `auth.uid`
- SwiftUI app lifecycle: `@main` App struct

### Android (Kotlin/Compose)

**SDK:** purchases 9.9.0+ + purchases-ui 9.9.0+ via Gradle
```kotlin
implementation("com.revenuecat.purchases:purchases:9.9.0")
implementation("com.revenuecat.purchases:purchases-ui:9.9.0")
```

**Init pattern (from CONTEXT D-01):**
- Configure in Application class via Hilt module
- Call `Purchases.sharedInstance.logIn(auth.uid)` after Supabase auth
- Call on every launch (D-02)

**Key API:**
- `Purchases.configure(PurchasesConfiguration.Builder(context, apiKey).appUserID(uid).build())`
- `Purchases.sharedInstance.logIn(appUserID:)` — identity linking
- `Purchases.sharedInstance.getCustomerInfo()` — entitlement check
- `Purchases.sharedInstance.customerInfoListener` — CustomerInfo updates

**EntitlementManager:**
- Hilt `@Singleton` providing ViewModel state
- Same interface: `isPremium`, `isTrialActive`, `dailyTranslationsUsed`, `subscriptionTier`

**Integration points in codebase:**
- `Android/WoofTalk/app/build.gradle.kts` — Hilt DI, compileSdk 35, minSdk 26
- Existing Supabase auth integration
- Hilt DI pattern already established

### Web (Next.js/React)

**SDK:** @revenuecat/purchases-js 1.0+ via npm
```bash
npm install @revenuecat/purchases-js
```

**Init pattern (from CONTEXT D-01):**
- Initialize in layout/provider component
- Call `Purchases.logIn(auth.uid)` after Supabase auth
- Call on every launch (D-02)

**Key API:**
- `Purchases.configure({ apiKey, appUserID })` — SDK init
- `Purchases.logIn(appUserID:)` — identity linking
- `Purchases.getCustomerInfo()` — entitlement check
- `Purchases.addEventListener('customerInfoUpdate', callback)` — listener

**EntitlementManager:**
- Zustand store (Web already uses Zustand ^5.0.3)
- Same interface: `isPremium`, `isTrialActive`, `dailyTranslationsUsed`, `subscriptionTier`
- React context for provider

**Integration points in codebase:**
- `Web/package.json` — Next.js 15, React 19, Zustand 5
- `Web/src/lib/supabase.ts` — Supabase client init pattern
- React context patterns in existing hooks

---

## 2. PurchasesDelegate / Listener Setup

### iOS
```swift
class EntitlementManager: ObservableObject, PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedCustomerInfo customerInfo: CustomerInfo) {
        // Update published properties from CustomerInfo
    }
}
```

### Android
```kotlin
class EntitlementManager @Inject constructor() : CustomerInfoListener {
    override fun onCustomerInfoUpdated(customerInfo: CustomerInfo) {
        // Update StateFlow properties from CustomerInfo
    }
}
```

### Web
```typescript
Purchases.addEventListener('customerInfoUpdate', (customerInfo) => {
    // Update Zustand store from CustomerInfo
});
```

---

## 3. Post-Purchase Refresh (CONTEXT D-05 / Pitfall 2)

After any purchase completes:
1. Immediately call `getCustomerInfo()` to force cache refresh
2. Show loading state until entitlement confirmed
3. Only then proceed to premium content

This prevents stale cache (Pitfall 2) where user completes purchase but CustomerInfo still shows free tier.

---

## 4. Login Required Before Paywall (SDK-06)

From CONTEXT and Pitfall 4:
- Unauthenticated users cannot access paywall
- Use Supabase `auth.uid` as RevenueCat `appUserID` on ALL platforms
- This ensures cross-platform identity consistency
- `logIn(auth.uid)` on every launch ensures correct identity

---

## 5. Offline Entitlement Policy (CONTEXT D-05)

- Trust cached `CustomerInfo` when offline
- RevenueCat SDK caches locally already
- If cache says premium → treat as premium
- If cache says free → treat as free
- No warning banner, no blocking

---

## 6. Existing Codebase Patterns to Follow

### iOS
- SwiftUI app lifecycle (`@main` App struct)
- Supabase Swift SDK already integrated (in Package.swift for AR target)
- Auth provides `auth.uid`

### Android
- Hilt DI (already in build.gradle.kts)
- MVVM architecture with ViewModels
- Kotlin + Compose UI
- Room DB for local storage

### Web
- Zustand for state management (already installed)
- `Web/src/lib/supabase.ts` pattern for client initialization
- Next.js 15 App Router
- React context for providers

### Backend
- 6 existing Edge Functions in `supabase/functions/`
- 12 existing migrations in `supabase/migrations/`
- PostgreSQL with RLS policies

---

## 7. Files to Create/Modify Per Platform

### iOS (new files)
- `EntitlementManager.swift` — ObservableObject wrapping CustomerInfo
- Modify `WoofTalkApp.swift` (or equivalent `@main`) — SDK init + delegate setup

### Android (new files)
- `EntitlementManager.kt` — @Singleton Hilt module
- `RevenueCatModule.kt` — Hilt module for Purchases dependency
- Modify `WoofTalkApplication.kt` — SDK init
- Modify `build.gradle.kts` — add RevenueCat dependencies

### Web (new files)
- `src/lib/entitlement-store.ts` — Zustand store for entitlement state
- `src/lib/revenuecat.ts` — RevenueCat client initialization
- `src/providers/EntitlementProvider.tsx` — React context provider
- Modify `src/lib/supabase.ts` or auth flow — logIn after auth
- Modify `package.json` — add @revenuecat/purchases-js

---

## 8. Environment Variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `REVENUECAT_IOS_API_KEY` | iOS app config | Client-side SDK init |
| `REVENUECAT_ANDROID_API_KEY` | Android app config | Client-side SDK init |
| `NEXT_PUBLIC_REVENUECAT_WEB_API_KEY` | Web app config | Client-side SDK init |

---

## Validation Architecture

### Critical paths to test:
1. SDK initializes without crash on all 3 platforms
2. `logIn(auth.uid)` successfully links Supabase user to RevenueCat customer
3. `PurchasesDelegate`/listener fires when CustomerInfo updates
4. `getCustomerInfo()` returns correct entitlement after `logIn`
5. Unauthenticated state: no paywall access, no premium features
6. Offline: cached CustomerInfo is trusted (D-05)
7. Post-purchase: `getCustomerInfo()` forces refresh (SDK-05)

### Test approach per platform:
- **iOS:** XCUITest or manual test with RevenueCat sandbox
- **Android:** Instrumented test with BillingClient sandbox
- **Web:** Jest + React Testing Library with mocked RevenueCat SDK

---

## RESEARCH COMPLETE
