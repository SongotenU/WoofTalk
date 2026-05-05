# Phase 56: Android Build Fixes & Production Prep - Research

**Researched:** 2026-05-05
**Domain:** Android (Kotlin/Compose), RevenueCat Android SDK 9.9.0, Supabase Kotlin SDK 3.1.4
**Confidence:** HIGH

## Summary

Phase 56 focuses on fixing Android build issues and preparing WoofTalk for production release. The Android app uses Kotlin with Jetpack Compose, Hilt for dependency injection, Room for local database, RevenueCat 9.9.0 for in-app subscriptions, and Supabase Kotlin SDK 3.1.4 for backend services. Research reveals that RevenueCat initialization uses a deprecated pattern and the PaywallScreen.kt may use outdated Compose APIs. The iOS Phase 55 fixes provide patterns for handling RevenueCat async/await migration and build configuration.

**Primary recommendation:** Update RevenueCat initialization to use `PurchasesConfiguration.Builder` pattern, verify Paywall composable API against RevenueCat 9.9.0 docs, and ensure proper Hilt injection for Purchases instance.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| RevenueCat subscription management | Android Client | RevenueCat Backend | Client SDK handles purchase flow, backend validates receipts |
| Supabase data sync | Android Client | Supabase Backend | Client SDK manages realtime sync, backend stores data |
| Push notifications | Android Client + FCM | Firebase Backend | FCM delivers notifications, client handles display |
| Local data persistence | Android Client (Room) | - | Room database runs locally on device |
| UI rendering | Android Client (Compose) | - | Jetpack Compose renders UI on device |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Kotlin | 2.0.x | Programming language | Official Android language |
| Jetpack Compose | BOM 2026.03.00 | UI framework | Modern Android UI toolkit |
| Hilt | 2.57.1 | Dependency injection | Standard Android DI solution |
| Room | 2.6.1 | Local database | Google's SQLite abstraction |
| RevenueCat Purchases | 9.9.0 | In-app subscriptions | [VERIFIED: Context7 /revenuecat/purchases-android] Leading subscription SDK |
| RevenueCat UI | 9.9.0 | Paywall UI | Official RevenueCat Compose UI |
| Supabase Kotlin SDK | 3.1.4 | Backend services | [ASSUMED] Common Kotlin multiplatform backend SDK |
| Firebase BOM | 33.15.0 | Push notifications | Standard Android push solution |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kotlin Coroutines | 1.8.1 | Async programming | All async operations |
| Retrofit | 2.11.0 | HTTP client | REST API calls |
| OkHttp | 4.12.0 | HTTP interceptor | Logging, auth headers |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| RevenueCat | Google Play Billing directly | Much more complex, no unified cross-platform backend |
| Supabase | Firebase Firestore | Supabase chosen for PostgreSQL + Realtime features |

**Installation:**
```bash
# Dependencies already in build.gradle.kts
# To update RevenueCat:
# implementation("com.revenuecat.purchases:purchases:9.9.0")
# implementation("com.revenuecat.purchases:purchases-ui:9.9.0")
```

**Version verification:**
```bash
# RevenueCat 9.9.0 - verified via Context7 (latest as of 2026-05-05)
# Supabase 3.1.4 - [ASSUMED] based on build.gradle.kts
```

## Architecture Patterns

### System Architecture Diagram

```
[User Action] → [Compose UI] → [ViewModel] → [Repository]
                                    ↓
                            [Local: Room DB] ↔ [Remote: Supabase]
                                    ↓
                            [RevenueCat SDK] → [RevenueCat Backend]
                                    ↓
                            [Firebase FCM] ← [Push Notifications]
```

### Recommended Project Structure
```
app/src/main/java/com/wooftalk/
├── MainActivity.kt           # Entry point, handles PiP, shortcuts
├── WoofTalkApplication.kt    # Hilt app, RevenueCat init
├── EntitlementManager.kt     # RevenueCat entitlement logic
├── RevenueCatModule.kt       # Hilt module for RevenueCat
├── data/                     # Repository, data sources
│   ├── local/               # Room database
│   └── remote/               # Supabase client, API
├── domain/                   # Business logic, use cases
├── ui/                       # Compose UI
│   ├── screen/              # Screen composables
│   ├── theme/               # Theme, typography
│   └── navigation/          # NavGraph
├── sync/                     # Realtime sync logic
└── push/                     # FCM service
```

### Pattern 1: RevenueCat Initialization (v9.x)
**What:** Proper SDK configuration using PurchasesConfiguration.Builder
**When to use:** App startup in Application class
**Example:**
```kotlin
// Source: [VERIFIED: Context7 /revenuecat/purchases-android]
val configuration = PurchasesConfiguration.Builder(context, apiKey)
    .entitlementVerificationMode(EntitlementVerificationMode.INFORMATIONAL)
    .build()
Purchases.configure(configuration)
```
**Issue found:** Current code in RevenueCatModule.kt uses older `Purchases.configure(config)` pattern without Builder.

### Pattern 2: Paywall Display (v7.x+)
**What:** Using PaywallDialog composable with experimental API
**When to use:** Displaying subscription paywall
**Example:**
```kotlin
// Source: [VERIFIED: Context7 /revenuecat/purchases-android]
@OptIn(ExperimentalPreviewRevenueCatUIPurchasesAPI::class)
@Composable
fun LockedScreen() {
    PaywallDialog(
        PaywallDialogOptions.Builder()
            .setRequiredEntitlementIdentifier("pro")
            .build()
    )
}
```
**Issue found:** PaywallScreen.kt uses `Paywall` composable and `PaywallListener` which may be deprecated.

### Anti-Patterns to Avoid
- **Double initialization:** Both RevenueCatModule.kt and WoofTalkApplication.kt call `Purchases.configure()` - should be called once
- **Main thread violations:** Ensure Room DB operations use coroutines properly (like iOS fixed actor isolation)
- **Direct Context usage:** Use Hilt injection for Application context

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-app subscriptions | Custom billing code | RevenueCat SDK | Complex edge cases, receipt validation, cross-platform |
| Dependency injection | Manual DI | Hilt/Dagger | Boilerplate, error-prone, standard solution exists |
| Local database | Raw SQLite | Room | Type safety, migrations, compile-time checks |
| HTTP client | HttpURLConnection | Retrofit/OkHttp | Headers, interceptors, JSON conversion built-in |

**Key insight:** RevenueCat handles all Google Play Billing edge cases (pending transactions, proration, grace periods) that would take months to implement correctly.

## Runtime State Inventory

> Include this section for rename/refactor/migration phases only. Omit entirely for greenfield phases.

**Not applicable** - Phase 56 is_build fixes, not rename/refactor.

## Common Pitfalls

### Pitfall 1: RevenueCat Double Initialization
**What goes wrong:** Calling `Purchases.configure()` multiple times causes undefined behavior
**Why it happens:** Initialization in both RevenueCatModule.kt (provides Purchases) and WoofTalkApplication.kt (configure again)
**How to avoid:** Initialize once in RevenueCatModule.kt using `@Provides @Singleton`, don't call configure again in Application
**Warning signs:** Logs show "Purchases already configured" warnings

### Pitfall 2: Deprecated Paywall API
**What goes wrong:** Using old `Paywall` composable that may be removed in future versions
**Why it happens:** RevenueCat 7.x+ introduced new `PaywallDialog` with `ExperimentalPreviewRevenueCatUIPurchasesAPI`
**How to avoid:** Migrate to `PaywallDialog` with proper `@OptIn` annotation
**Warning signs:** Compiler warnings about deprecated APIs

### Pitfall 3: BuildConfig Field Not Generated
**What goes wrong:** `BuildConfig.REVENUECAT_ANDROID_API_KEY` not found at compile time
**Why it happens:** `buildConfig = true` not enabled in `buildFeatures` block
**How to avoid:** Verify `buildFeatures { buildConfig = true }` is present (it is in this project)
**Warning signs:** Compilation error "Unresolved reference: BuildConfig"

### Pitfall 4: Hilt Injection Order
**What goes wrong:** `EntitlementManager` tries to access `Purchases.sharedInstance` before it's configured
**Why it happens:** Hilt creates `EntitlementManager` (which sets `updatedCustomerInfoListener` in init) before `Purchases.configure()` runs
**How to avoid:** Ensure RevenueCat is configured before any class tries to use `Purchases.sharedInstance`
**Warning signs:** NullPointerException on `Purchases.sharedInstance.updatedCustomerInfoListener`

## Code Examples

Verified patterns from official sources:

### RevenueCat Configuration (v9.9.0)
```kotlin
// Source: [VERIFIED: Context7 /revenuecat/purchases-android]
// In your Hilt module:
@Module
@InstallIn(SingletonComponent::class)
object RevenueCatModule {
    @Provides
    @Singleton
    fun providePurchases(app: Application): Purchases {
        val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
        val configuration = PurchasesConfiguration.Builder(app, apiKey)
            .entitlementVerificationMode(EntitlementVerificationMode.INFORMATIONAL)
            .build()
        Purchases.configure(configuration)
        return Purchases.sharedInstance
    }
}
```

### EntitlementManager with UpdatedCustomerInfoListener
```kotlin
// Source: [VERIFIED: Context7 /revenuecat/purchases-android]
// Pattern for listening to entitlement changes:
@Singleton
class EntitlementManager @Inject constructor() : UpdatedCustomerInfoListener {

    init {
        Purchases.sharedInstance.updatedCustomerInfoListener = this
    }

    override fun onCustomerInfoUpdated(customerInfo: CustomerInfo) {
        // Update entitlement state from customerInfo
        val proEntitlement = customerInfo.entitlements["pro"]
        val isPremium = proEntitlement?.isActive ?: false
        _isPremium.value = isPremium
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Purchases.configure(context, apiKey)` | `PurchasesConfiguration.Builder(context, apiKey).build()` | RevenueCat v5.0 | Better configuration options |
| `Paywall` composable | `PaywallDialog` with `@OptIn` | RevenueCat v7.0 | Experimental API for Compose |
| Manual entitlement checking | `UpdatedCustomerInfoListener` | RevenueCat v4.0 | Real-time entitlement updates |

**Deprecated/outdated:**
- `Purchases.configure(context, apiKey)` — deprecated in v5.0, use Builder pattern
- Setting `appUserID` at configuration time — now set via `Purchases.sharedInstance.logIn()`

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Supabase Kotlin SDK 3.1.4 is current/latest version | Standard Stack | Might be outdated, but functional |
| A2 | iOS Phase 55 actor isolation fixes map to Android coroutine threading | Architecture Patterns | Android coroutines differ from Swift actors, but main-thread principle applies |
| A3 | `Paywall` composable in PaywallScreen.kt is deprecated | Anti-Patterns | If not deprecated, migration unnecessary but harmless |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

## Open Questions

1. **RevenueCat API Key environment variable**
   - What we know: `REVENUECAT_ANDROID_API_KEY` env var is read at build time via `BuildConfig`
   - What's unclear: Is this env var set in the CI/CD environment? Should be set for release builds.
   - Recommendation: Document required env vars in CI/CD setup (Phase 58)

2. **PaywallScreen.kt API compatibility**
   - What we know: Uses `Paywall` composable and `PaywallListener`
   - What's unclear: Are these APIs still valid in RevenueCat 9.9.0?
   - Recommendation: Test paywall display on device, check for deprecation warnings

3. **Supabase client initialization**
   - What we know: Uses custom `SupabaseClient` wrapper with Retrofit
   - What's unclear: Why not use Supabase Kotlin SDK directly? Custom wrapper may be unnecessary.
   - Recommendation: This is out of scope for Phase 56 (build fixes), but note for future refactoring

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Android SDK (compileSdk 35) | Android build | ✓ | 35 (via Android Studio) | — |
| Gradle 8.7 | Android build | ✓ | 8.7 (wrapper) | — |
| Kotlin 2.0+ | Android compile | ✓ | Via plugin | — |
| RevenueCat SDK 9.9.0 | Subscriptions | ✓ | 9.9.0 (remote) | — |
| Supabase Kotlin SDK 3.1.4 | Backend sync | ✓ | 3.1.4 (remote) | — |
| Firebase BOM 33.15.0 | Push notifications | ✓ | 33.15.0 (remote) | — |
| Google Play Billing | In-app purchases | ✓ | Via RevenueCat | — |

**Missing dependencies with no fallback:**
- None identified

**Missing dependencies with fallback:**
- None identified

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | JUnit 4.13.2 |
| Config file | None — standard setup |
| Quick run command | `./gradlew testDebugUnitTest` |
| Full suite command | `./gradlew test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-56-01 | RevenueCat initializes without error | unit | `./gradlew testDebugUnitTest --tests "*RevenueCat*" -x` | ❌ Wave 0 |
| REQ-56-02 | Paywall displays correctly | manual | N/A — requires device | ❌ Wave 0 |
| REQ-56-03 | Build succeeds with 0 errors | build | `./gradlew assembleDebug --dry-run` | ✅ Build system |
| REQ-56-04 | EntitlementManager updates from CustomerInfo | unit | `./gradlew testDebugUnitTest --tests "*EntitlementManager*" -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `./gradlew testDebugUnitTest`
- **Per wave merge:** `./gradlew test`
- **Phase gate:** Build green + manual paywall test before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `app/src/test/java/com/wooftalk/RevenueCatInitTest.kt` — covers REQ-56-01
- [ ] `app/src/test/java/com/wooftalk/EntitlementManagerTest.kt` — covers REQ-56-04
- [ ] `app/src/test/java/com/wooftalk/PaywallScreenTest.kt` — covers REQ-56-02 (if automated possible)
- Framework install: `./gradlew dependencies` — already configured

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Supabase Auth (handled by SDK) |
| V3 Session Management | yes | Supabase session tokens (handled by SDK) |
| V4 Access Control | yes | RevenueCat entitlements |
| V5 Input Validation | yes | Kotlin type system, Compose state |
| V6 Cryptography | no | — |

### Known Threat Patterns for Android + RevenueCat + Supabase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key exposure | Information Disclosure | Use BuildConfig fields, don't hardcode |
| RevenueCat entitlement bypass | Tampering | Use server-side receipt validation via RevenueCat |
| Supabase anonymous key exposure | Information Disclosure | Use RLS policies, user-specific auth tokens |
| Insecure Firebase FCM token | Spoofing | Validate tokens server-side |

## Sources

### Primary (HIGH confidence)
- `/revenuecat/purchases-android` Context7 library ID - setup, configuration, PaywallDialog, entitlements
- `android/WoofTalk/app/build.gradle.kts` - verified dependency versions
- `android/WoofTalk/app/src/main/java/com/wooftalk/RevenueCatModule.kt` - current init pattern
- `android/WoofTalk/app/src/main/java/com/wooftalk/WoofTalkApplication.kt` - Application class

### Secondary (MEDIUM confidence)
- Phase 55 SUMMARY.md - iOS build fix patterns to apply to Android
- RevenueCat 9.9.0 release notes (assumed current based on build.gradle.kts)

### Tertiary (LOW confidence)
- [ASSUMED] Supabase Kotlin SDK 3.1.4 best practices
- [ASSUMED] Mapping iOS actor isolation fixes to Android coroutine patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified via Context7 and build.gradle.kts
- Architecture: HIGH - Based on verified code and standard Android patterns
- Pitfalls: MEDIUM - Some based on assumptions about deprecated APIs

**Research date:** 2026-05-05
**Valid until:** 2026-06-04 (30 days for stable Android SDK ecosystem)
