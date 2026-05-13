# Phase 60 Plan: Android Play Store Submission

## Goal
Prepare and submit Android app to Google Play Console, including creating store listing, generating screenshots, writing metadata, and uploading AAB.

## Plans (6 tasks)

### 60-01: Create Google Play Console Listing
**Goal**: Create app listing in Google Play Console with all required metadata

**Steps**:
1. Create new app in Google Play Console (https://play.google.com/console)
2. Configure app details:
   - App name: WoofTalk
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free with in-app purchases
   - Declare content: Follow Play Console guide
3. Set store presence:
   - App name: WoofTalk
   - Short description (80 chars): "Translate between human and pet languages instantly"
   - Full description (4000 chars max): (see 60-03)
4. Complete tasks in "Set up your app" checklist:
   - Privacy policy (required)
   - App category: Utilities
   - Contact details
   - Email: support@wooftalk.app

**Manual Steps Required**:
- Log in to Google Play Console
- Create app with package name: com.wooftalk (matches Android project)
- Complete initial setup wizard

**Verification**: App appears in Play Console with "Dashboard" visible

---

### 60-02: Generate Screenshots for All Device Sizes
**Goal**: Create screenshots for all required Android device sizes using emulators

**Steps**:
1. Launch Android app in Emulator (Pixel 9 Pro, Pixel 9, Pixel Tablet)
2. Navigate through key screens:
   - Translation screen with voice input
   - Community phrases browser
   - Subscription/paywall screen
   - Settings screen
3. Capture screenshots at each size:
   - Phone (1080 x 1920 px minimum)
   - 7-inch tablet (1024 x 600 px minimum)
   - 10-inch tablet (1280 x 800 px minimum)
4. Optional: Add device frames using Play Console's built-in tool
5. Save to `fastlane/screenshots/android/`

**Commands**:
```bash
cd android/WoofTalk
./gradlew installDebug
# Use emulator or device to capture screenshots
# adb shell screencap /sdcard/screenshot.png
# adb pull /sdcard/screenshot.png fastlane/screenshots/android/
```

**Files to create**:
- Screenshots in `fastlane/screenshots/android/` directory
- `fastlane/fastlane/metadata/android/en-US/` for Fastlane (optional)

**Verification**: Screenshots available for phone and tablet form factors

---

### 60-03: Write App Description, Keywords, and Privacy Policy
**Goal**: Create compelling Play Store metadata

**Steps**:
1. Write short description (80 chars max):
   - "Translate between human and pet languages. Talk to dogs, cats, and birds!"
2. Write full description (4000 chars max):
   - Lead with key features: bidirectional translation, voice I/O, real-time sync
   - Mention supported animals: Dogs, Cats, Birds
   - Highlight premium features: unlimited translations, community access
   - Include "Cross-platform: Use on Android, iOS, and Web"
   - Note: "Subscriptions managed via RevenueCat"
3. Create privacy policy (same as iOS, must match):
   - Host at: https://wooftalk.app/privacy
   - GDPR compliant for EU users
4. Write release notes for first version:
   - "Welcome to WoofTalk! Translate between human and animal languages."

**Files to create**:
- `store-assets/android/short-description.txt`
- `store-assets/android/full-description.txt`
- `store-assets/android/privacy-policy.md` (can symlink to iOS version)
- `store-assets/android/release-notes.txt`

**Play Store Metadata**:
- App Name: WoofTalk
- Short Description: Translate between human and pet languages instantly
- Full Description: (see full-description.txt)
- Category: Utilities
- Tags: pet translator, dog translator, cat translator, animal communication
- Privacy Policy URL: https://wooftalk.app/privacy
- Website: https://wooftalk.app

**Verification**: All required text fields ready for Play Console

---

### 60-04: Configure App Metadata and Build Settings
**Goal**: Ensure Android project is configured correctly for Play Store submission

**Steps**:
1. Verify app-level build.gradle.kts:
   - applicationId: com.wooftalk.app
   - versionName: "1.0.0"
   - versionCode: 1 (increment for each submission)
   - minSdk: 26 (Android 8.0)
   - targetSdk: 35 (Android 15)
2. Configure ProGuard rules (proguard-rules.pro):
   - Keep RevenueCat classes
   - Keep Supabase classes
   - Keep Kotlin coroutines
3. Generate signed release AAB:
   - Create upload keystore (once): `keytool -genkey -v -keystore wooftalk.keystore...`
   - Configure signing in build.gradle.kts
   - Build: `./gradlew :app:bundleRelease`
4. Verify AAB:
   - Use `bundletool` to check APKs
   - Test on device: `bundletool install-apks...`

**Files to modify**:
- `android/WoofTalk/app/build.gradle.kts` (verify version and signing)
- `android/WoofTalk/app/proguard-rules.pro` (verify ProGuard config)
- `android/WoofTalk/gradle.properties` (add signing config if not present)

**Verification**: AAB builds successfully and installs on test device

---

### 60-05: Upload AAB to Play Console
**Goal**: Upload production build to Google Play Console

**Steps**:
1. Build release AAB:
   ```bash
   cd android/WoofTalk
   ./gradlew clean
   ./gradlew :app:bundleRelease
   ```
2. In Play Console:
   - Go to "Release and testing" → "Production"
   - Click "Create new release"
   - Upload AAB file from `app/build/outputs/bundle/release/app-release.aab`
   - Wait for processing
3. Add release notes for this version
4. Review release summary

**Manual Steps Required**:
- Build AAB via command line or Android Studio
- Upload via Play Console web interface

**Verification**: AAB uploaded and processed successfully in Play Console

---

### 60-06: Submit for Review
**Goal**: Complete all Play Console sections and submit for Google review

**Steps**:
1. Complete "Store presence" tab:
   - Add text (short + full description)
   - Add screenshots for phone and tablet
   - Add feature graphic (1024 x 500 px)
   - Add high-res icon (512 x 512 px)
   - Add promo video (optional)
2. Complete "Content rating" questionnaire:
   - Answer questions about content
   - Expected rating: Everyone (no violence, no adult content)
3. Complete "Target audience" (if app is for kids):
   - Select age groups: 18+ (adults), or 13+ (teens and adults)
4. Complete "Data safety" section:
   - Specify data collection: profile, app activity, device ID
   - Privacy policy URL
   - Data deletion policy
5. Set pricing and availability:
   - Price: Free
   - Available in: All countries/regions
   - In-app products: Configure RevenueCat products
6. Review and roll out:
   - Click "Review release"
   - Fix any errors flagged
   - Click "Start rollout to Production"

**Data Safety Section**:
- Collected data: App info, Device ID, Diagnostics, Crash logs
- Data shared: None (or with service providers)
- Data processing: Encrypted in transit, you can request deletion

**Manual Steps Required**:
- Complete all Play Console sections
- Submit for Google review
- Monitor review status (1-3 days typical)

**Verification**: App status changes to "In review" or "Available on Google Play"

---

## Execution Order
60-01 → 60-02 → 60-03 → 60-04 → 60-05 → 60-06

## Dependencies
- Depends on: Phase 58 (CI/CD Pipeline) — for automated builds
- Can run in parallel with: Phase 59 (iOS App Store Submission)

## Notes
- Google Play review is typically faster than App Store review (1-3 days vs 24-48 hours)
- Play Console requires a one-time $25 registration fee (if not already paid)
- AAB format is mandatory for new apps on Google Play
- RevenueCat products must be configured in both stores before submission
- Consider using "Staged rollout" (10% → 50% → 100%) for first release
