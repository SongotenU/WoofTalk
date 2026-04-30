# Code Review Report - Phase 52: paywall-ui
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 52 built paywall UI across iOS, Android, and Web. iOS uses RevenueCatUI PaywallView in UIHostingController with auth gate and refresh on dismiss. Android added Subscription row + Paywall route with RevenueCatUI composable. Web created /subscribe page with custom UI, RevenueCat hosted checkout (`getWebPurchaseURL()`), polling for purchase confirmation, and restore functionality. Key issues: iOS `presentPaywallIfAllowed()` fallback alert is misleading ("Sign In Required" but entitlement might be loading), SettingsViewController.swift row count hardcoded to 14 (fragile), and Web subscribe page's `checkoutOpen` state is set but `handleSubscribe` checks it redundantly.

## Findings

### [WARNING] WR-01: iOS presentPaywallIfAllowed uses misleading alert message
**File**: `WoofTalk/SettingsViewController.swift:223-236`
**Severity**: WARNING
**Category**: Bug
**Description**: The `presentPaywallIfAllowed()` method shows "Sign In Required" alert when `isReadyToAccessPaywall` is false. However, `isReadyToAccessPaywall` depends on `AuthManager.shared.isAuthenticated`, which might be `false` during initial auth state loading (before Supabase auth initializes). Users who ARE signed in might see this alert briefly, or the check might race with auth initialization.
**Recommendation**: Add a loading state check before showing the alert:
```swift
private func presentPaywallIfAllowed() {
    if AuthManager.shared.isAuthenticated {
        let hostingController = UIHostingController(rootView: PaywallView())
        hostingController.isModalInPresentation = true
        present(hostingController, animated: true) { /* refresh */ }
    } else {
        // Check if we're still loading auth state
        if AuthManager.shared.isLoading {
            presentAlert(title: "Loading", message: "Please wait while we verify your account...")
        } else {
            presentAlert(title: "Sign In Required", message: "Please sign in to manage your subscription.")
        }
    }
}
```

### [WARNING] WR-02: SettingsViewController hardcoded row count (14) is fragile
**File**: `WoofTalk/SettingsViewController.swift:40`
**Severity**: WARNING
**Category**: Code Quality
**Description**: `numberOfRowsInSection` returns hardcoded `14`. Adding or removing settings rows requires updating this number manually. If it's wrong, the app crashes when trying to access non-existent rows, or rows become inaccessible.
**Recommendation**: Use an enum or computed property:
```swift
enum SettingsRow: Int, CaseIterable {
    case latencyThreshold, audioQuality, translationLanguage, translationMode,
         enableVibration, clearHistory, about, subscription,
         restorePurchases, manageSubscription, exportData, deleteAccount,
         cancelSubscription, referFriend
    
    static var count: Int { allCases.count }
}
// Then: func tableView(...) -> Int { SettingsRow.count }
```

### [INFO] IN-01: Web subscribe page `checkoutOpen` state is redundant with `selectedPlan`
**File**: `web/src/app/subscribe/page.tsx:114-134`
**Severity**: INFO
**Category**: Code Quality
**Description**: The `handleSubscribe` function checks `if (!checkoutOpen) return;` but `checkoutOpen` is set to `true` when a plan button is clicked, and `selectedPlan` is also set. The `checkoutOpen` check is redundant — if `selectedPlan` is set, the modal is already open. The `handleSubscribe` is only called from the modal's subscribe button.
**Recommendation**: Remove `checkoutOpen` check from `handleSubscribe`, or combine the two states into a single derived state.

### [INFO] IN-02: iOS Cancel Subscription row (case 12) hidden but row still takes height
**File**: `WoofTalk/SettingsViewController.swift:93-100`
**Severity**: INFO
**Category**: Code Quality
**Description**: Case 12 sets `cell.isHidden = true` for non-premium users, but the row still occupies space in the table (heightForRow returns 60 for all rows). This leaves a blank 60pt gap in the settings list.
**Recommendation**: Return `CGFloat.leastNonzeroMagnitude` (or 0) for hidden rows in `heightForRowAt`, or filter the data source to exclude hidden rows entirely.

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 2
