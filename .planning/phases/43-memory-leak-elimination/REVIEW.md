# Code Review Report - Phase 43: memory-leak-elimination
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 43 aimed to fix NotificationCenter and Timer memory leaks in iOS codebase. While some files were properly updated with deinit methods and timer invalidation, several issues were found including missing deinit in BatteryOptimizer, incorrect claims in SUMMARY.md about TranslationViewController (which has no NotificationCenter usage), and thread safety concerns in LeaderboardManager's CoreData access pattern.

## Findings

### [WARNING] WR-01: BatteryOptimizer missing deinit cleanup
**File**: `WoofTalk/Performance/BatteryOptimizer.swift:1-87`
**Severity**: WARNING
**Category**: Bug
**Description**: BatteryOptimizer has `startMonitoring()` that adds NotificationCenter observers and creates a CADisplayLink, with a `stopMonitoring()` method for cleanup. However, there is no `deinit` method. As a singleton this is less critical, but violates the defensive programming pattern stated in the plan's "Truths" section. If the class is ever refactored to be non-singleton, it will leak.
**Recommendation**: Add deinit method:
```swift
deinit {
    displayLink?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

### [WARNING] WR-02: LeaderboardManager missing @MainActor and has thread safety issues
**File**: `WoofTalk/LeaderboardManager.swift:31-197`
**Severity**: WARNING
**Category**: Bug
**Description**: The PLAN.md states LeaderboardManager should have `@MainActor` isolation. The current code does not have this. More critically, the `refresh()` method (line 54-68) dispatches CoreData work to a background queue but accesses `self.selectedPeriod` from the background thread without synchronization. Additionally, CoreData contexts are not thread-safe and should not be accessed across queues without proper coordination.
**Recommendation**: 
1. Add `@MainActor` to class or specific methods
2. Capture needed values before dispatching to background queue:
```swift
func refresh() {
    isLoading = true
    let period = selectedPeriod  // Capture on main thread
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        let newEntries = self.calculateLeaderboard(for: period)
        
        DispatchQueue.main.async {
            self.entries = newEntries
            // ...
        }
    }
}
```

### [INFO] IN-01: TranslationViewController.swift SUMMARY.md discrepancy
**File**: `WoofTalk/TranslationViewController.swift:1-64`
**Severity**: INFO
**Category**: Quality
**Description**: SUMMARY.md claims "Added `deinit { NotificationCenter.default.removeObserver(self) }`" for this file. However, the current file has no NotificationCenter usage and no deinit. Either the file wasn't updated, or the SUMMARY.md is incorrect about what changed. The file appears to not need this fix as it doesn't use NotificationCenter.
**Recommendation**: Update SUMMARY.md to reflect actual changes, or verify if a different file was intended.

### [INFO] IN-02: LeaderboardManager refresh uses CoreData on background thread unsafely
**File**: `WoofTalk/LeaderboardManager.swift:54-68`
**Severity**: INFO
**Category**: Quality
**Description**: The `calculateLeaderboard(for:)` method is called on a background queue but uses `coreDataContext` directly. CoreData contexts should typically be used on the queue they were created on, or a new background context should be created.
**Recommendation**: Use a background CoreData context for the fetch operation.

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 2
