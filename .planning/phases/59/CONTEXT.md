# Phase 59 Context: iOS App Store Submission

## Goal
Prepare and submit iOS app to App Store Connect, including creating store listing, generating screenshots, writing metadata, and uploading build.

## Current State
- Phase 55: iOS Build Fixes & Production Prep (5/7 complete, 71.4%)
- iOS app compiles with 0 errors, 0 warnings (Swift 6, MainActor isolation)
- RevenueCat v5.x migration complete (async/await)
- DB concurrency fixes in progress (55-06)
- Final verification pending (55-07)
- Bundle ID: `vandopha.WoofTalk` (from Xcode project)
- Store assets created: description, keywords, privacy policy, release notes

## Plans (6 tasks)
- 59-01: Create App Store Connect Listing
- 59-02: Generate Screenshots for All Device Sizes
- 59-03: Write App Description, Keywords, Privacy Policy
- 59-04: Configure App Metadata and Build Settings
- 59-05: Upload Build to App Store Connect
- 59-06: Submit for Review

## Dependencies
- Depends on: Phase 55 (iOS Build Fixes), Phase 58 (CI/CD Pipeline)
- Blocks: Phase 61 (End-to-End Testing) — can run in parallel with Phase 60

## Success Criteria
1. App listing created in App Store Connect
2. Screenshots generated for all required device sizes (iPhone 6.7", 6.5", 5.5", iPad)
3. All metadata completed (description, keywords, privacy policy)
4. Build uploaded and processed in App Store Connect
5. App submitted for Apple review
6. Status changes to "Waiting for Review"

## Manual Steps Required
- App Store Connect login and app creation
- Screenshot capture via iOS Simulator
- Build upload via Xcode (Product → Archive → Upload)
- Complete all metadata sections in App Store Connect
- Submit for review (24-48 hour review time)

## Notes
- Bundle ID must match exactly: `vandopha.WoofTalk`
- RevenueCat products must be configured in App Store Connect before submission
- Privacy policy hosted at: https://wooftalk.app/privacy
- iOS deployment target: 17.0+
