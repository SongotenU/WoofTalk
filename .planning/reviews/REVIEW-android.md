# Code Review Report - Android Platform
**Date**: 2026-04-30
**Scope**: Android source files (android/)
**Depth**: standard

## Summary
The Android platform implementation contains several critical issues that will cause runtime crashes, most notably `TODO()` calls in production navigation code that throw `NotImplementedError` when reached. The FirebaseMessagingService has notification handling bugs including conflicting sound settings and collision-prone notification IDs. The RevenueCat module provides configuration but never initializes the SDK. Several screens contain unused parameters and incomplete implementations. One empty FCM token upload method means push token registration never occurs.

## Findings

### [BLOCKER] TODO() in production navigation causes runtime crash
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/navigation/AppNavigation.kt:35`
**Severity**: BLOCKER
**Category**: Bug
**Description**: The `CancellationSurveyScreen` composable call passes `entitlementManager = TODO()`, which will throw `NotImplementedError` the moment a user navigates to the cancellation survey screen. Similarly, line 42 has the same issue for `ReferralScreen`.
**Evidence**:
```kotlin
composable(Screen.CancellationSurvey.route) {
    CancellationSurveyScreen(
        entitlementManager = TODO(), // Pass EntitlementManager
        onComplete = { navController.popBackStack() },
        onNavigateBack = { navController.popBackStack() }
    )
}
composable(Screen.Referral.route) {
    ReferralScreen(
        entitlementManager = TODO(), // Pass EntitlementManager
        onNavigateBack = { navController.popBackStack() }
    )
}
```
**Recommendation**: Replace `TODO()` with an actual `EntitlementManager` instance, likely obtained via Hilt injection or passed from a higher-level provider. For example:
```kotlin
val entitlementManager = hiltViewModel<SomeViewModel>().entitlementManager
// or
val entitlementManager = LocalEntitlementManager.current
```

### [BLOCKER] FCM token never sent to server
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/push/FirebaseMessagingService.kt:92-95`
**Severity**: BLOCKER
**Category**: Bug
**Description**: The `sendTokenToServer` method is completely empty. When `onNewToken` is called (line 30-34), it calls `sendTokenToServer(token)` but the method has no implementation. This means FCM push tokens are never registered with the backend, and push notifications will fail for all devices after token refresh.
**Evidence**:
```kotlin
private fun sendTokenToServer(token: String) {
    // Send FCM token to Supabase backend for push registration
    // Implement via your API client
}
```
**Recommendation**: Implement the token upload logic, e.g.:
```kotlin
private fun sendTokenToServer(token: String) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            // Use your API client to send token to Supabase
            // e.g., supabaseClient.auth.setPushToken(token)
        } catch (e: Exception) {
            Log.e("FCM", "Failed to send token", e)
        }
    }
}
```

### [WARNING] Notification sound overridden by DEFAULT_ALL flags
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/push/FirebaseMessagingService.kt:55,58`
**Severity**: WARNING
**Category**: Bug
**Description**: Line 55 sets a custom sound via `setSound(soundUri)`, but line 58 calls `setDefaults(Notification.DEFAULT_ALL)` which includes `DEFAULT_SOUND`. The `DEFAULT_ALL` flag overrides the custom sound that was just set, making the sound configuration on line 55 ineffective.
**Evidence**:
```kotlin
.setSound(soundUri)              // Line 55 - custom sound set
.setPriority(NotificationCompat.PRIORITY_HIGH)
.setDefaults(Notification.DEFAULT_ALL)  // Line 58 - overrides sound
```
**Recommendation**: Remove `DEFAULT_SOUND` from the defaults, or remove the `setSound` call and rely on defaults. To preserve custom sound:
```kotlin
.setDefaults(Notification.DEFAULT_LIGHTS or Notification.DEFAULT_VIBRATE)
```

### [WARNING] Notification ID collision risk with currentTimeMillis().toInt()
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/push/FirebaseMessagingService.kt:75`
**Severity**: WARNING
**Category**: Bug
**Description**: Using `System.currentTimeMillis().toInt()` as the notification ID is unreliable. Multiple notifications arriving within the same millisecond (or within clock precision) will collide, causing notifications to replace each other instead of stacking. Additionally, casting to `Int` wraps the long value, creating further collision risk.
**Evidence**:
```kotlin
notificationManager.notify(System.currentTimeMillis().toInt(), notification)
```
**Recommendation**: Use a unique incrementing ID or a hash of the message content:
```kotlin
private var notificationId = AtomicInteger(0)
// then
notificationManager.notify(notificationId.incrementAndGet(), notification)
```

### [WARNING] Notification channel recreated on every notification
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/push/FirebaseMessagingService.kt:62-73`
**Severity**: WARNING
**Category**: Quality
**Description**: The notification channel is recreated every time `showNotification` is called (lines 62-73). While `createNotificationChannel` is safe to call repeatedly on API 26+, it is wasteful and the channel ID can be influenced by unvalidated remote `data["channel_id"]` input on line 47.
**Evidence**:
```kotlin
val channelId = data["channel_id"] ?: CHANNEL_ID  // Line 47 - from remote data
// ...
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    val channel = NotificationChannel(...)  // Recreated every call
    notificationManager.createNotificationChannel(channel)
}
```
**Recommendation**: Create the channel once during app startup or service initialization. Validate or restrict the `channel_id` from remote data to prevent channel ID injection:
```kotlin
val channelId = when (data["channel_id"]) {
    "wooftalk_push_channel" -> data["channel_id"]!!
    else -> CHANNEL_ID
}
```

### [WARNING] TranslationTileService state can desynchronize with actual service state
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/tiles/TranslationTileService.kt:10,24`
**Severity**: WARNING
**Category**: Bug
**Description**: The `isListening` boolean is a local variable that can easily become out of sync with the actual `VoiceTranslationService` state. If the service is stopped externally (e.g., by system, or by the service itself), the tile will still show `STATE_ACTIVE`. The tile state is updated after toggling, but there is no mechanism to verify the actual service state.
**Evidence**:
```kotlin
private var isListening = false

override fun onClick() {
    super.onClick()
    if (isListening) {
        stopTranslation()
    } else {
        startTranslation()
    }
    isListening = !isListening  // Blind toggle - no verification
    updateTileState()
}
```
**Recommendation**: Check actual service state or use a shared state mechanism (e.g., a bounded service connection, or listening to service lifecycle events).

### [WARNING] No-op icon expression in updateTileState
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/tiles/TranslationTileService.kt:51`
**Severity**: WARNING
**Category**: Quality
**Description**: Line 51 contains `icon` as a standalone expression that does nothing. It appears to be an incomplete attempt to set the tile icon. The result of accessing `icon` is discarded, so the tile never gets its icon updated.
**Evidence**:
```kotlin
if (isListening) {
    state = Tile.STATE_ACTIVE
    label = getString(R.string.tile_stop_translation)
    icon  // Line 51 - no-op, should be qsTile.icon = ...
} else {
    state = Tile.STATE_INACTIVE
    label = getString(R.string.tile_start_translation)
}
```
**Recommendation**: Set the icon properly:
```kotlin
qsTile?.apply {
    if (isListening) {
        state = Tile.STATE_ACTIVE
        label = getString(R.string.tile_stop_translation)
        icon = Icon.createWithResource(context, R.drawable.ic_stop_translation)
    } else {
        state = Tile.STATE_INACTIVE
        label = getString(R.string.tile_start_translation)
        icon = Icon.createWithResource(context, R.drawable.ic_start_translation)
    }
    updateTile()
}
```

### [WARNING] Unused EntitlementManager parameter in CancellationSurveyScreen
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/screen/CancellationSurveyScreen.kt:14,20`
**Severity**: WARNING
**Category**: Quality
**Description**: The `entitlementManager` parameter is accepted but never used anywhere in the composable function. This suggests either the parameter is dead code, or the screen is missing functionality that should use it (e.g., to check/restrict cancellation based on entitlement status).
**Evidence**:
```kotlin
fun CancellationSurveyScreen(
    entitlementManager: EntitlementManager,  // Accepted but never used
    onComplete: () -> Unit,
    onNavigateBack: () -> Unit
) {
```
**Recommendation**: Either remove the unused parameter or implement the entitlement check. If the screen needs to verify the user's subscription state before allowing cancellation, use the manager.

### [WARNING] Unused EntitlementManager parameter in ReferralScreen
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/screen/ReferralScreen.kt:15,20`
**Severity**: WARNING
**Category**: Quality
**Description**: Same issue as above — `entitlementManager` is accepted but never used in the composable. The referral feature likely needs entitlement checks to determine if the user is eligible for referral rewards.
**Evidence**:
```kotlin
fun ReferralScreen(
    entitlementManager: EntitlementManager,  // Accepted but never used
    onNavigateBack: () -> Unit
) {
```
**Recommendation**: Remove the unused parameter or implement entitlement-gated logic for the referral feature.

### [WARNING] Referral link uses placeholder data
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/screen/ReferralScreen.kt:34-39`
**Severity**: WARNING
**Category**: Quality
**Description**: The referral code is hardcoded to `"COMING_SOON"` and the link points to a placeholder URL. The `LaunchedEffect` wraps this in a `scope.launch` but the code inside is not suspending and doesn't actually fetch from any backend. This means the referral feature is non-functional.
**Evidence**:
```kotlin
LaunchedEffect(Unit) {
    scope.launch {
        // Fetch or generate referral code from Supabase
        // For now, generate a placeholder
        referralCode = "COMING_SOON"
        referralLink = "https://wooftalk.app/subscribe?ref=$referralCode"
    }
}
```
**Recommendation**: Implement actual referral code fetching from Supabase or remove the placeholder UI until the backend is ready. The `scope.launch` inside `LaunchedEffect` is also redundant — `LaunchedEffect` already runs in a coroutine scope.

### [WARNING] History shortcut uses microphone icon
**File**: `android/WoofTalk/app/src/main/res/xml/shortcuts.xml:55`
**Severity**: WARNING
**Category**: Quality
**Description**: The history shortcut (line 55) uses `@drawable/ic_mic` (microphone icon) which is semantically incorrect for a history feature. The translate shortcuts (lines 7, 31) also use `ic_mic`, which is correct for them, but inappropriate for history.
**Evidence**:
```xml
<shortcut
    android:shortcutId="history"
    android:icon="@drawable/ic_mic"  <!-- Wrong icon for history -->
    ...>
```
**Recommendation**: Create and use a history-specific icon (e.g., `@drawable/ic_history`) for the history shortcut.

### [WARNING] RevenueCat SDK never initialized
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/RevenueCatModule.kt`
**Severity**: WARNING
**Category**: Bug
**Description**: The module provides a `PurchasesConfiguration` but there is no code that actually calls `Purchases.configure()` with this configuration. The RevenueCat SDK requires explicit initialization, typically in `Application.onCreate()` or via a Hilt `Initializer` entry point. Without initialization, all RevenueCat features (paywall, entitlement checks) will fail.
**Evidence**:
```kotlin
@Provides
@Singleton
fun providePurchasesConfiguration(
    app: android.app.Application
): PurchasesConfiguration {
    val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
    return PurchasesConfiguration.Builder(app, apiKey)
        .build()
}
// No Purchases.configure() call anywhere
```
**Recommendation**: Add an initialization block, either in an `Application` class or via Hilt:
```kotlin
@Provides
@Singleton
fun providePurchases(
    app: android.app.Application,
    config: PurchasesConfiguration
): Purchases {
    Purchases.configure(config)
    return Purchases.sharedInstance
}
```

### [WARNING] Empty composable destinations in NavHost
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/navigation/AppNavigation.kt:25-27`
**Severity**: WARNING
**Category**: Quality
**Description**: The Translate, History, and Settings destinations have empty composable blocks (`{ /* TranslationScreen */ }`). These screens will render nothing when navigated to, making those features inaccessible.
**Evidence**:
```kotlin
composable(Screen.Translate.route) { /* TranslationScreen */ }
composable(Screen.History.route) { /* HistoryScreen */ }
composable(Screen.Settings.route) { /* SettingsScreen */ }
```
**Recommendation**: Wire up the actual screen composables:
```kotlin
composable(Screen.Translate.route) { TranslateScreen() }
composable(Screen.History.route) { HistoryScreen() }
composable(Screen.Settings.route) { SettingsScreen() }
```

## Findings by Severity
- BLOCKER: 2
- WARNING: 11

## Findings by Category
- Bug: 6
- Security: 0
- Quality: 7
