# Stack Research

**Domain:** Android Mobile Application (iOS to Android Port)
**Researched:** 2026-03-31
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Kotlin | 2.0.0+ | Primary language | Google's recommended Android language, 100% interoperable with Java, coroutines native |
| Jetpack Compose BOM | 2026.03.00 | Declarative UI framework | Google's recommended replacement for XML views, direct equivalent to SwiftUI |
| Android Gradle Plugin | 8.7.0 | Build system | Stable, compatible with Kotlin 2.0.x and Compose |
| Room | 2.6.1 | Local database | Official Core Data equivalent for Android, Kotlin-first with Flow support |
| Kotlin Coroutines | 1.8.1 | Async operations | Built-in coroutine support in Room, Flow, and Android lifecycle |
| Hilt | 2.57.1 | Dependency Injection | Google's recommended DI, built on Dagger, standard for Android architecture |
| AndroidX Lifecycle | 2.10.0 | ViewModel & lifecycle | MVVM architecture, Compose integration |
| Material3 | (via Compose BOM) | Design system | Modern UI components, theming, accessibility |

### Voice I/O Technologies

| Technology | Purpose | iOS Equivalent | Notes |
|------------|---------|----------------|-------|
| android.speech.SpeechRecognizer | Speech-to-text | SFSpeechRecognizer | Requires RECORD_AUDIO permission |
| android.speech.tts.TextToSpeech | Text-to-speech | AVSpeechSynthesizer | Built-in Android TTS engine |
| AudioRecord / AudioTrack | Raw audio handling | AVAudioEngine | For custom audio processing |

### Network & Backend

| Technology | Version | Purpose | Notes |
|------------|---------|---------|-------|
| Retrofit | 2.11.0 | REST client | For API calls to translation backend |
| OkHttp | 4.12.0 | HTTP client | Interceptors for auth, logging |
| Moshi | 1.15.1 | JSON parsing | Type-safe JSON, KSP codegen |
| Firebase SDK | BoM 33.0.0+ | Auth, Firestore, Cloud Messaging | For cross-platform sync (as per v3.0 plan) |

### Error Reporting

| Technology | Version | Purpose | Notes |
|------------|---------|---------|-------|
| Sentry Android SDK | 8.0.0+ | Error & crash reporting | Direct equivalent to iOS Sentry integration, coroutines-aware |

---

## Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Navigation Compose | 2.8.0 | Screen navigation | Replacing SwiftUI Navigation |
| DataStore Preferences | 1.1.1 | Key-value persistence | Simple settings storage |
| Accompanist Permissions | 0.36.0 | Runtime permissions | Compose-friendly permission handling |
| Coil Compose | 2.7.0 | Image loading | Profile images, community photos |
| WorkManager | 2.9.1 | Background tasks | Offline sync, analytics upload |
| ExoPlayer (Media3) | 1.5.0 | Audio playback | Advanced audio playback needs |

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Android Studio Ladybug+ | IDE | Full Compose support, emulator, AI assistant |
| Firebase Emulator Suite | Local backend testing | For offline development |
| LeakCanary | Memory leak detection | Debug builds only |
| Android Lint | Code analysis | Built into AGP |

---

## Installation

```kotlin
// build.gradle.kts (Project level)
plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
    id("com.google.dagger.hilt.android") version "2.57.1" apply false
    id("com.google.devtools.ksp") version "2.0.0-1.0.27" apply false
}

// build.gradle.kts (App level)
dependencies {
    // Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:2026.03.00")
    implementation(composeBom)
    
    // Compose
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.3")
    
    // Lifecycle & ViewModel
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.10.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.10.0")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.8.5")
    
    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:2.57.1")
    ksp("com.google.dagger:hilt-compiler:2.57.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    
    // Network
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-moshi:2.11.0")
    implementation("com.squareup.moshi:moshi-kotlin:1.15.1")
    ksp("com.squareup.moshi:moshi-kotlin-codegen:1.15.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Sentry
    implementation("io.sentry:sentry-android:8.0.0")
    
    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.1.1")
    
    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("androidx.hilt:hilt-work:1.2.0")
    ksp("androidx.hilt:hilt-compiler:1.2.0")
}
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Room | Realm Kotlin | If you need cross-platform (iOS/Android) with same API |
| Hilt | Koin | If you prefer simpler, less code-generation-heavy DI |
| Retrofit | Ktor Client | If you want fully Kotlin-native HTTP client |
| Compose | XML + View Binding | If you have existing XML layouts to migrate |
| Firebase | Supabase | If you prefer open-source, more SQL-like backend |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| XML Layouts with ViewBinding | Verbose, not declarative, opposite of SwiftUI paradigm | Jetpack Compose |
| Kotlin 1.x versions < 2.0 | Missing latest coroutine features, deprecated APIs | Kotlin 2.0.0+ |
| Dagger (non-Hilt) | Excessive boilerplate, Hilt is now standard | Hilt 2.57.1 |
| LiveData (deprecated for new code) | Replaced by StateFlow in Compose | Kotlin StateFlow |
| RxJava | Complex, Kotlin coroutines are simpler | Kotlin Coroutines + Flow |
| Old Sentry SDK (< 8.x) | Deprecated API, missing coroutines support | Sentry 8.0.0+ |
| Java | No coroutines/Flow support, verbose, missing Kotlin extensions | Kotlin |
| SharedPreferences | Not type-safe, no coroutine support | DataStore Preferences |
| Gson | Runtime reflection, slower than Moshi | Moshi with KSP codegen |

---

## Stack Patterns by Variant

**If porting from iOS with SwiftUI:**
- Use Jetpack Compose with Material3 — directly maps to SwiftUI paradigms
- Use Room with Flow — maps to Swift's @FetchRequest and publishers
- Use Hilt — maps to Swift's @Environment(\.dependency) pattern

**If building new Android-first:**
- Consider Kotlin Multiplatform (KMP) — share translation logic between iOS/Android
- Consider Compose Multiplatform — share UI code with iOS (experimental)

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Kotlin 2.0.0 | AGP 8.7.x, Compose BOM 2026.x | Use KSP 2.0.0-1.0.27 matching Kotlin version |
| Compose BOM 2026.03.00 | Android API 21+ | MinSdk 24 recommended for full features |
| Room 2.6.1 | Kotlin 2.0.x, Coroutines 1.8.x | KSP required for compiler |
| Hilt 2.57.1 | Dagger 2.57.1, Kotlin 2.0.x | KSP plugin required |
| Sentry 8.0.0+ | Android API 21+ | AGP 8.x compatible, coroutines-aware |

---

## Android-Specific Permissions Required

| Permission | Purpose | iOS Equivalent | Notes |
|------------|---------|----------------|-------|
| `android.permission.RECORD_AUDIO` | Speech recognition input | NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription | Runtime permission required |
| `android.permission.INTERNET` | API calls, sync | Same (implicit) | Required for OpenAI API |
| `android.permission.VIBRATE` | Haptic feedback on translation | UIImpactFeedbackGenerator | Optional |
| `android.permission.ACCESS_NETWORK_STATE` | Check connectivity | Same | For offline detection |
| `android.permission.POST_NOTIFICATIONS` | Translation notifications (Android 13+) | UNNotificationCenter | Optional feature |
| `android.permission.FOREGROUND_SERVICE` | Background audio processing | Background audio mode | For voice recording service |

**AndroidManifest.xml:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Voice/Recording Permissions -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <!-- Network Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Optional: Haptic feedback -->
    <uses-permission android:name="android.permission.VIBRATE" />
    
    <!-- Optional: Notifications (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Optional: Background audio service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    
    <!-- Feature declarations (Play Store filtering) -->
    <uses-feature 
        android:name="android.hardware.microphone" 
        android:required="false" />
    <uses-feature 
        android:name="android.hardware.speech.recognition" 
        android:required="false" />
</manifest>
```

**Runtime Permission Request (Kotlin/Compose):**
```kotlin
@Composable
fun RequestVoicePermissions() {
    val micPermission = Manifest.permission.RECORD_AUDIO
    
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        // Handle permission result
        if (isGranted) {
            // Enable voice input features
        }
    }
    
    Button(onClick = { permissionLauncher.launch(micPermission) }) {
        Text("Grant Microphone Access")
    }
}
```

**Privacy manifest additions (Android 13+):**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## iOS to Android Mapping Reference

| iOS (WoofTalk) | Android Equivalent |
|---------------|-------------------|
| SwiftUI | Jetpack Compose |
| Core Data | Room Database |
| SFSpeechRecognizer | android.speech.SpeechRecognizer |
| AVSpeechSynthesizer | android.speech.tts.TextToSpeech |
| Combine/Flow | Kotlin Flow + StateFlow |
| @Environment injection | Hilt @Inject |
| @ObservableObject | StateFlow in ViewModel |
| Sentry SDK | Sentry Android SDK |
| Combine Publishers | Kotlin Coroutines Flow |

---

## Feature Parity Mapping

### Translation Engine

| iOS Feature | Android Implementation |
|-------------|----------------------|
| Rule-based translation | Port TranslationEngine.kt logic |
| OpenAI API integration | Retrofit + OpenAI Kotlin SDK |
| Real-time streaming | OkHttp WebSocket |
| Multi-language (Dog/Cat/Bird) | Same language routing logic |

### Voice I/O

| iOS Feature | Android Implementation |
|-------------|----------------------|
| SpeechRecognizer (SFSpeechRecognizer) | SpeechRecognizer API |
| Audio synthesis (AVSpeechSynthesizer) | TextToSpeech |
| Audio session management | AudioManager + AudioFocus |
| Audio capture/processing | AudioRecord API |

### Community Phrase System

| iOS Feature | Android Implementation |
|-------------|----------------------|
| CommunityPhraseBrowserView | Compose list with LazyColumn |
| ContributionManager | Room + WorkManager for offline queue |
| ContributionValidationService | API validation endpoint |
| ModerationView | Compose UI with approval workflow |

### Social Features

| iOS Feature | Android Implementation |
|-------------|----------------------|
| SocialSharingManager | Intent-based sharing (ShareSheet) |
| SocialGraphManager | Firebase/Supabase Graph API |
| LeaderboardManager | RecyclerView with Compose |
| Follow system | Firestore real-time listeners |

### Analytics Dashboard

| iOS Feature | Android Implementation |
|-------------|----------------------|
| AnalyticsViewController | Compose screens with charts |
| TranslationAnalyticsService | Analytics SDK integration |
| PerformanceMonitor | CustomMetrics API |

### Offline-First Architecture

| iOS Feature | Android Implementation |
|-------------|----------------------|
| OfflineTranslationManager | Room + WorkManager sync queue |
| OfflineModeView | Network connectivity StateFlow |
| Core Data sync | Room + Firestore sync |
| NetworkOptimizer | ConnectivityManager + OkHttp interceptors |

### Performance Optimization

| iOS Feature | Android Implementation |
|-------------|----------------------|
| MemoryManager | Android Profiler + LeakCanary |
| BatteryOptimizer | BatteryManager + WorkManager |
| NetworkOptimizer | OkHttp cache + DataStore |
| OfflineManager | Room + WorkManager |

---

## Sources

- Context7: `/websites/developer_android_develop_ui_compose` — Jetpack Compose BOM 2026.03.00 setup
- Context7: `/websites/developer_android` — Room database, Voice APIs, Architecture Components
- Context7: `/websites/dagger_dev_hilt` — Hilt 2.57.1 dependency injection setup
- Context7: `/getsentry/sentry-docs` — Sentry Android SDK 8.0.0 integration
- Official: https://developer.android.com/jetpack/androidx/releases/compose — Latest BOM versions
- Official: https://dagger.dev/hilt/gradle-setup — Hilt configuration
- Official: https://developer.android.com/reference/android/speech/package-summary — Speech APIs
- Android Developers: https://developer.android.com/develop/ui/compose/bom — Compose BOM management

---

*Stack research for: Android Platform Port*
*Researched: 2026-03-31*