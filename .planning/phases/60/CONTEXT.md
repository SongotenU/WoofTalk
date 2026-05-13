# Phase 60 Context: Android Play Store Submission

## Goal
Prepare and submit Android app to Google Play Console, including creating store listing, generating screenshots, writing metadata, and uploading AAB.

## Current State
- Phase 56: Android Build Fixes & Production Prep (pending)
- Android app builds successfully with Release AAB
- Package name: `com.wooftalk` (from build.gradle.kts namespace)
- Version: 1.0 (versionCode: 1, versionName: "1.0")
- minSdk: 26 (Android 8.0), targetSdk: 35 (Android 15)
- RevenueCat integration configured
- ProGuard enabled for release builds
- Store assets created: short description, full description, release notes
- Privacy policy: reuse iOS version (same policy)

## Plans (6 tasks)
- 60-01: Create Google Play Console Listing
- 60-02: Generate Screenshots for All Device Sizes
- 60-03: Write App Description, Keywords, Privacy Policy
- 60-04: Configure App Metadata and Build Settings
- 60-05: Upload AAB to Play Console
- 60-06: Submit for Review

## Dependencies
- Depends on: Phase 56 (Android Build Fixes), Phase 58 (CI/CD Pipeline)
- Blocks: Phase 61 (End-to-End Testing) — can run in parallel with Phase 59

## Success Criteria
1. App listing created in Google Play Console
2. Screenshots generated for phone and tablet form factors
3. All metadata completed (short description, full description, privacy policy)
4. AAB uploaded and processed in Play Console
5. App submitted for Google review
6. Status changes to "In review" or "Available on Google Play"

## Manual Steps Required
- Google Play Console login and app creation ($25 one-time fee if not paid)
- Screenshot capture via Android Emulator
- AAB build and upload via Play Console
- Complete all metadata sections (store presence, content rating, data safety)
- Submit for review (1-3 day review time)

## Notes
- Package name must match exactly: `com.wooftalk`
- RevenueCat products must be configured in Play Console before submission
- Privacy policy hosted at: https://wooftalk.app/privacy
- AAB format is mandatory for new apps on Google Play
- Consider staged rollout (10% → 50% → 100%) for first release
- Same privacy policy as iOS (GDPR/CCPA compliant)
