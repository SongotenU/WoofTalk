# Code Review Report - iOS Platform
**Date**: 2026-04-30
**Scope**: iOS source files (WoofTalk/)
**Depth**: standard

## Summary
The iOS platform code covers analytics, audio processing, WatchKit extension, Core Data models, and SwiftUI views. While the code is functional for a demo/MVP, several critical security issues and bugs were found: a service role key is exposed in client-side code, Core Data view context is accessed from a background thread, and the Watch app storyboard has invalid XML. Multiple logic errors exist in audio processing algorithms and Core Data query predicates. Several features (COPPA consent, RevenueCat cancellation) are stubs that silently fail.

## Findings

### [CRITICAL] Service Role Key Exposed in Client Code
**File**: `WoofTalk/Analytics/ErrorTrackingService.swift:27`
**Severity**: CRITICAL
**Category**: Security
**Description**: The ErrorTrackingService sends the Supabase service role key in the Authorization header from the iOS client. Service role keys have admin privileges and bypass all Row Level Security (RLS) policies. This key should never be embedded in client-side code as it can be extracted by inspecting the app binary or network traffic.
**Evidence**:
```swift
request.setValue("Bearer \(SupabaseManager.shared.serviceRoleKey)", forHTTPHeaderField: "Authorization")
```
**Recommendation**: Remove the service role key from client code. Create a server-side edge function that receives error reports and internally uses the service role key. The iOS client should authenticate with an anonymous key or user JWT instead:
```swift
if let session = SupabaseManager.shared.client?.auth.currentSession {
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
}
```

### [CRITICAL] Core Data View Context Accessed from Background Thread
**File**: `WoofTalk/TranslationFeedbackManager.swift:24`
**Severity**: CRITICAL
**Category**: Bug
**Description**: The `storeCorrection` function accesses `self.persistence.container.viewContext` inside a `queue.async` block, which runs on a background queue. The Core Data view context is not thread-safe and must only be accessed from the main thread. This can cause crashes, data corruption, or undefined behavior.
**Evidence**:
```swift
func storeCorrection(...) {
    queue.async {
        let context = self.persistence.container.viewContext
        let correction = TranslationCorrection(context: context)
        // ...
        try context.save()
    }
}
```
**Recommendation**: Use a background context for background queue operations:
```swift
func storeCorrection(...) {
    queue.async {
        let context = self.persistence.container.newBackgroundContext()
        context.perform {
            let correction = TranslationCorrection(context: context)
            // ...
            try context.save()
        }
    }
}
```

### [CRITICAL] Invalid WatchKit Storyboard XML
**File**: `WoofTalk/WatchKitExtension/Interface.storyboard:20,54`
**Severity**: CRITICAL
**Category**: Bug
**Description**: The storyboard contains duplicate element IDs (`GaT-6B-2dR` appears twice on lines 20 and 54) which is invalid XML for Interface Builder documents. Additionally, line 33-35 defines an outlet connection inside a `<label>` element rather than on the controller, which is incorrect.
**Evidence**:
```xml
<!-- Line 20: First occurrence of GaT-6B-2dR -->
<label text="WoofTalk Ready" alignment="center" id="GaT-6B-2dR">

<!-- Line 54: Duplicate ID (also GaT-6B-2dR) -->
<label text="WoofTalk Ready" alignment="center" id="GaT-6B-2dR" customClass="WKInterfaceLabel">

<!-- Line 33-35: Outlet incorrectly defined inside a label -->
<connections>
    <outlet property="lastTranslationLabel" destination="GaT-6B-2dR" id="NnM-0I-6hG"/>
</connections>
```
**Recommendation**: Fix the storyboard by ensuring unique IDs for all elements and moving outlet definitions to the controller element. Recreate the storyboard in Interface Builder if needed.

### [CRITICAL] RevenueCat `cancel()` Method Does Not Exist
**File**: `WoofTalk/CancellationSurveyView.swift:80`
**Severity**: CRITICAL
**Category**: Bug
**Description**: The code calls `Purchases.shared.cancel()` which is not a valid RevenueCat method on iOS. Subscriptions cannot be cancelled programmatically — users must manage subscriptions through the App Store. This code will either fail to compile or crash at runtime.
**Evidence**:
```swift
try await Purchases.shared.cancel()
```
**Recommendation**: Remove the `cancel()` call. Instead, guide the user to the App Store subscription settings:
```swift
// Remove the Purchases.shared.cancel() call
// If you want to show subscription management:
if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
    await MainActor.run { UIApplication.shared.open(url) }
}
```

### [HIGH] `isSubmitting` State Modified from Background Thread
**File**: `WoofTalk/CancellationSurveyView.swift:73-86`
**Severity**: HIGH
**Category**: Bug
**Description**: The `submitSurvey` function uses a `Task` to perform async work but sets `isSubmitting = false` inside the Task without ensuring it runs on the main thread. Since `isSubmitting` is `@State`, modifying it from a background thread can cause UI corruption or crashes.
**Evidence**:
```swift
private func submitSurvey() {
    // ...
    Task {
        do {
            try await submitToSupabase()
            try await Purchases.shared.cancel()
            onComplete()
        } catch {
            showError = true
        }
        isSubmitting = false  // Not on main thread!
    }
}
```
**Recommendation**: Wrap state modifications in `MainActor.run` or use `@MainActor`:
```swift
Task {
    do {
        try await submitToSupabase()
        // ...
    } catch {
        await MainActor.run { showError = true }
    }
    await MainActor.run { isSubmitting = false }
}
```

### [HIGH] Incorrect Dominant Frequency Calculation in Bark Detector
**File**: `WoofTalk/AudioProcessing/BarkDetector.swift:37-41`
**Severity**: HIGH
**Category**: Bug
**Description**: The code attempts to find the "dominant frequency" by computing the maximum sample-to-sample delta (slope), not the actual dominant frequency. This gives a value related to the highest frequency content, not the dominant frequency. The variable `dominantFreq` is misnamed and the algorithm is incorrect.
**Evidence**:
```swift
var dominantFreq: Double = 0
for i in 1..<frameCount-1 {
    let delta = Double(samples[i] - samples[i-1])
    if abs(delta) > abs(dominantFreq) { dominantFreq = delta }
}
```
**Recommendation**: Implement proper frequency estimation using FFT (vDSP_fft_zrip) or autocorrelation. The current approach does not give a meaningful frequency value.

### [HIGH] Dog Emotion Detector Autocorrelation Returns Invalid Frequency
**File**: `WoofTalk/DogEmotionDetector.swift:68-93`
**Severity**: HIGH
**Category**: Bug
**Description**: The `estimateDominantFrequency` function initializes `maxLagIndex = 1`. If all correlation values are <= 0 (possible with audio data), the function returns `sampleRate / 1`, which is the Nyquist frequency and is almost certainly wrong. The function should handle the case where no valid peak is found.
**Evidence**:
```swift
var maxCorr: Float = 0
var maxLagIndex = 1  // Starts at 1, not 0
for lag in 1..<maxLag {
    if correlation[lag] > maxCorr {
        maxCorr = correlation[lag]
        maxLagIndex = lag
    }
}
guard maxLagIndex > 0 else { return 0 }
return sampleRate / Double(maxLagIndex)  // If maxLagIndex=1, returns sampleRate
```
**Recommendation**: Initialize `maxLagIndex = 0` and check for valid peak detection:
```swift
var maxLagIndex = 0
// ...
guard maxLagIndex > 0 else { return 0 }  // Now correctly returns 0 if no peak found
```

### [HIGH] Core Data Predicate with Potentially Nil UUID
**File**: `WoofTalk/MessagingView.swift:50-53`
**Severity**: HIGH
**Category**: Bug
**Description**: The `participantName` function creates a UUID from a string that might be nil or invalid. `UUID(uuidString: otherID ?? "")` returns `nil` for empty strings, and passing `nil as CVarArg` to NSPredicate may produce undefined behavior or fail silently.
**Evidence**:
```swift
fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: otherID ?? "") as CVarArg)
```
**Recommendation**: Add proper nil and validity checking:
```swift
guard let otherID = otherID, let uuid = UUID(uuidString: otherID) else { return "Unknown" }
fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
```

### [MEDIUM] COPPA Consent Request and Verification Are Stubs
**File**: `WoofTalk/COPPAAgeVerificationView.swift:63-66,102-104`
**Severity**: MEDIUM
**Category**: Bug
**Description**: The `sendConsentRequest()` function only prints to console instead of actually sending a consent email. The `verifyConsent()` function also just prints and dismisses without validating the consent code. This means COPPA compliance is not actually enforced.
**Evidence**:
```swift
private func sendConsentRequest() {
    print("COPPA consent request sent to: \(parentEmail)")
}

private func verifyConsent() {
    print("Verifying COPPA consent code: \(consentCode)")
    presentationMode.wrappedValue.dismiss()
}
```
**Recommendation**: Implement actual email sending via Supabase edge function or email service, and validate the consent code against a server-side stored value:
```swift
private func sendConsentRequest() {
    guard !parentEmail.isEmpty else { return }
    // Call Supabase function to send consent email with a verification code
    Task { try? await sendConsentEmail(parentEmail) }
}
```

### [MEDIUM] Misleading Variable Name and Comment in DogProfileView
**File**: `WoofTalk/DogProfileView.swift:70-75`
**Severity**: MEDIUM
**Category**: Quality
**Description**: The comment says "Phrases by this dog's owner" but the code calls `getDogs(for:)`, and the variable is named `phrases` but contains `[DogProfile]` objects. This is confusing and appears to be a copy-paste error.
**Evidence**:
```swift
// Phrases by this dog's owner
if let phrases = dog.owner.flatMap({ DogProfileManager.shared.getDogs(for: $0) }),
   !phrases.isEmpty {
    Text("This owner has \(phrases.count) dog(s)")
```
**Recommendation**: Fix the comment and variable name to match the actual behavior:
```swift
// Dogs owned by this dog's owner
if let ownerDogs = dog.owner.flatMap({ DogProfileManager.shared.getDogs(for: $0) }),
   !ownerDogs.isEmpty {
    Text("This owner has \(ownerDogs.count) dog(s)")
```

### [MEDIUM] Widget Timeline with Past Dates Causes Frequent Reloads
**File**: `WoofTalk/Widgets/WoofTalkWidget.swift:22-26`
**Severity**: MEDIUM
**Category**: Bug
**Description**: The widget timeline entries use timestamps from past translations. With `TimelinePolicy.atEnd`, the system will immediately request a new timeline since all entries are in the past. This causes unnecessary frequent reloads.
**Evidence**:
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<TranslationEntry>) -> Void) {
    let entries = loadRecentTranslations()  // Entries have past timestamps
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
}
```
**Recommendation**: Add a future entry to control reload frequency:
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<TranslationEntry>) -> Void) {
    var entries = loadRecentTranslations()
    // Add a future entry to control when the timeline refreshes
    let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    entries.append(TranslationEntry(date: refreshDate, humanText: "No recent translations", dogTranslation: ""))
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
}
```

### [MEDIUM] Watch History Re-Translates Instead of Using Stored Translation
**File**: `WoofTalk/WatchKitExtension/Controllers/HistoryInterfaceController.swift:34`
**Severity**: MEDIUM
**Category**: Quality
**Description**: When a user selects a history item, the code re-translates the input string instead of using the already-translated text that's stored in the `WatchTranslation` object. This is wasteful and could produce a different translation than what was originally stored.
**Evidence**:
```swift
let result = WatchTranslationService.shared.translate(input: translation.input, direction: ...)
VoiceFeedbackManager.shared.speak(result.translatedText)
```
**Recommendation**: Use the stored translation directly:
```swift
VoiceFeedbackManager.shared.speak(translation.translated)
HapticManager.shared.play(.playful)
```

### [LOW] Silent JSON Serialization Failures
**File**: `WoofTalk/Analytics/ErrorTrackingService.swift:42-44`
**Severity**: LOW
**Category**: Quality
**Description**: If JSON serialization fails when creating the error tracking payload, the function silently returns without logging or attempting alternative error reporting.
**Evidence**:
```swift
do {
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
} catch { return }
```
**Recommendation**: Log the error for debugging:
```swift
do {
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
} catch {
    print("[ErrorTracking] Failed to serialize payload: \(error)")
    return
}
```

### [LOW] Feature Flag Manager Defaults to Empty User ID
**File**: `WoofTalk/Analytics/FeatureFlagManager.swift:24`
**Severity**: LOW
**Category**: Bug
**Description**: If both the `userId` parameter and `SupabaseManager.shared.currentUserId` are nil, the user ID defaults to an empty string. This could cause unexpected behavior in the backend when evaluating feature flags.
**Evidence**:
```swift
func isEnabled(_ key: String, userId: String? = nil, completion: @escaping (Bool) -> Void) {
    let userId = userId ?? SupabaseManager.shared.currentUserId ?? ""
    // Empty string sent to backend...
```
**Recommendation**: Return early or use a device identifier:
```swift
let userId = userId ?? SupabaseManager.shared.currentUserId
guard let userId = userId else {
    DispatchQueue.main.async { completion(false) }
    return
}
```

### [LOW] Watch WCSession Used Without Activation Check
**File**: `WoofTalk/WatchKitExtension/Controllers/TranslationViewController.swift:77`
**Severity**: LOW
**Category**: Bug
**Description**: The code calls `WCSession.default.transferUserInfo(context)` without verifying that the session is activated and reachable. If the session isn't active, the data won't be transferred.
**Evidence**:
```swift
private func updateComplication() {
    if let newData = WatchTranslationStore.shared.lastTranslation() {
        let context: [String: Any] = [...]
        WCSession.default.transferUserInfo(context)  // No activation check
    }
}
```
**Recommendation**: Check session state before transferring:
```swift
private func updateComplication() {
    guard WCSession.default.activationState == .activated else { return }
    if let newData = WatchTranslationStore.shared.lastTranslation() {
        // ...
        WCSession.default.transferUserInfo(context)
    }
}
```

## Findings by Severity
- CRITICAL: 4
- HIGH: 4
- MEDIUM: 4
- LOW: 3

## Findings by Category
- Bug: 11
- Security: 1
- Quality: 3
