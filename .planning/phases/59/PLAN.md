# Phase 59 Plan: iOS App Store Submission

## Goal
Prepare and submit iOS app to App Store Connect, including creating store listing, generating screenshots, writing metadata, and uploading build.

## Plans (6 tasks)

### 59-01: Create App Store Connect Listing
**Goal**: Create app listing in App Store Connect with all required metadata

**Steps**:
1. Create new app in App Store Connect (https://appstoreconnect.apple.com)
2. Set bundle ID: vandopha.WoofTalk (matches Xcode project)
3. Configure app information:
   - Name: WoofTalk
   - Primary Category: Utilities
   - Secondary Category: Lifestyle
   - Content Rights: No (user-generated content)
   - Age Rating: 4+ (no objectionable content)
4. Set pricing: Free with In-App Purchases
5. Configure Game Center: Disabled

**Manual Steps Required**:
- Log in to App Store Connect
- Create app with bundle ID matching Xcode project
- Complete app information form

**Verification**: App appears in App Store Connect with "Prepare for Submission" status

---

### 59-02: Generate Screenshots for All Device Sizes
**Goal**: Create screenshots for all required iOS device sizes using simulator

**Steps**:
1. Launch iOS app in Simulator (iPhone 16 Pro Max, iPhone 16, iPad Pro)
2. Navigate through key screens:
   - Translation screen (main feature)
   - Voice input in action
   - Community phrases browser
   - Subscription/paywall screen
   - Settings screen
3. Capture screenshots at each size:
   - iPhone 6.7" (iPhone 16 Pro Max): 1320 x 2868 px
   - iPhone 6.5" (iPhone 16 Pro): 1206 x 2622 px
   - iPhone 5.5" (iPhone 8 Plus): 1242 x 2208 px
   - iPad Pro 12.9": 2048 x 2732 px
   - iPad Pro 11": 1668 x 2388 px
4. Add device frames using Xcode's screenshot organizer or third-party tool
5. Save to `fastlane/screenshots/ios/`

**Commands**:
```bash
# Launch simulator
open -a Simulator --args -CurrentDeviceUDID <device_id>

# Take screenshots via Xcode or manually
# Organize by device size
```

**Files to create**:
- Screenshots in `fastlane/screenshots/ios/` directory
- `fastlane/Snapfile` for automated capture (optional)

**Verification**: Screenshots available for all required device sizes

---

### 59-03: Write App Description, Keywords, and Privacy Policy
**Goal**: Create compelling app store metadata

**Steps**:
1. Write app description (4000 char max):
   - Highlight key features: translation, voice I/O, cross-platform sync
   - Mention supported animals: Dogs, Cats, Birds
   - Include "Privacy-focused" and "Real-time sync"
2. Create keyword list (100 char max):
   - "dog translator,cat translator,bird translator,pet communication,animal translation"
3. Write subtitle (30 char max): "Talk to Your Pets"
4. Create privacy policy (required):
   - Use template from https://www.privacypolicytemplate.net/
   - Host at: https://wooftalk.app/privacy
   - Key points: no data selling, Supabase auth, local-first storage
5. Write support URL and marketing URL

**Files to create**:
- `store-assets/ios/description.txt`
- `store-assets/ios/keywords.txt`
- `store-assets/ios/privacy-policy.md`
- `store-assets/ios/release-notes.txt`

**App Store Metadata**:
- Name: WoofTalk
- Subtitle: Talk to Your Pets
- Category: Utilities
- Keywords: dog translator,cat translator,bird translator,pet communication,animal translation
- Description: (see description.txt)
- Privacy Policy URL: https://wooftalk.app/privacy
- Support URL: https://wooftalk.app/support

**Verification**: All required text fields populated in App Store Connect

---

### 59-04: Configure App Metadata and Build Settings
**Goal**: Ensure Xcode project is configured correctly for App Store submission

**Steps**:
1. Verify Xcode project settings:
   - Bundle ID: com.wooftalk.app
   - Version: 1.0.0 (or current version)
   - Build: Increment for each submission
   - Deployment Target: iOS 17.0+
   - Devices: iPhone (and iPad if supported)
2. Configure Info.plist:
   - Privacy - Microphone Usage Description: "WoofTalk needs microphone access to translate your voice to pet language."
   - Privacy - Speech Recognition Usage Description: "Speech recognition is used to convert your voice to text for translation."
3. Enable capabilities:
   - Push Notifications (if using)
   - Background Modes (if needed)
4. Archive build in Xcode:
   - Product → Archive
   - Validate Archive
   - Check for errors/warnings

**Files to modify**:
- `WoofTalk/WoofTalk/Info.plist` (verify privacy strings)
- `WoofTalk.xcodeproj/project.pbxproj` (verify build settings)

**Verification**: Archive validates successfully in Xcode

---

### 59-05: Upload Build to App Store Connect
**Goal**: Upload production build to App Store Connect

**Steps**:
1. Clean build folder in Xcode (Shift+Cmd+K)
2. Set build configuration to Release
3. Archive the app (Product → Archive)
4. In Organizer window:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Upload" (not Export)
   - Include bitcode: No (deprecated)
   - Include symbols: Yes
   - Upload build
5. Wait for processing (10-30 minutes)
6. Verify build appears in App Store Connect → Activities → iOS Builds

**Manual Steps Required**:
- Use Xcode to archive and upload
- Monitor processing status in App Store Connect

**Verification**: Build shows "Processing" then "Ready to Submit" in App Store Connect

---

### 59-06: Submit for Review
**Goal**: Complete all App Store Connect sections and submit for Apple review

**Steps**:
1. In App Store Connect, select the build under "Build"
2. Complete App Store tab:
   - Add screenshots for all device sizes
   - Add app preview video (optional but recommended)
   - Fill in description, keywords, support URL
   - Set privacy policy URL
3. Complete Pricing and Availability:
   - Price: Free
   - Availability: All territories
   - In-App Purchases: Configure RevenueCat products
4. Complete App Privacy:
   - Data collection: Yes (analytics, diagnostics)
   - Privacy policy URL
   - Answer privacy questions about data collection
5. Complete App Review Information:
   - Contact information
   - Notes for reviewer (test account if needed)
   - Demo account: Create test account
6. Click "Submit for Review"

**Review Notes Template**:
```
WoofTalk is a pet translation app that uses AI to translate between human and animal languages (Dog, Cat, Bird). The app includes:
- Voice input/output for natural conversations
- Community-contributed phrases
- In-app purchases for premium features (RevenueCat)
- Real-time sync across iOS, Android, and Web

Test Account:
Email: test@wooftalk.app
Password: [Provided separately]

Premium features: Monthly $4.99, Annual $39.99
```

**Manual Steps Required**:
- Complete all App Store Connect sections
- Submit for Apple review
- Monitor review status (24-48 hours typical)

**Verification**: App status changes to "Waiting for Review"

---

## Execution Order
59-01 → 59-02 → 59-03 → 59-04 → 59-05 → 59-06

## Dependencies
- Depends on: Phase 58 (CI/CD Pipeline) — for automated builds
- Blocks: Phase 60 (Android Play Store Submission) — can run in parallel

## Notes
- Phases 59 and 60 can run in parallel once Phase 58 completes
- Some steps require manual interaction with Apple/Google consoles
- RevenueCat products must be configured before store submission
- App privacy details must accurately reflect data collection
