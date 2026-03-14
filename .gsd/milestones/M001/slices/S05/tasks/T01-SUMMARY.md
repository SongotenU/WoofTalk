---
id: T01
parent: S05
milestone: M001
provides:
  - App Store Connect account setup and app listing
  - App metadata configuration (name, description, keywords, categories)
  - App Store screenshots for all device sizes
  - Privacy policy and Terms of Service documentation
key_files:
  - AppStoreMetadata.json
  - PrivacyPolicy.md
  - TermsOfService.md
  - AppStoreScreenshots/
key_decisions:
  - Selected "Entertainment" category to maximize visibility for a novelty pet app
  - Chose subscription model with free trial to comply with App Store guidelines
  - Implemented comprehensive privacy policy covering voice data and analytics
patterns_established:
  - App Store metadata structure and configuration approach
  - Legal documentation template for voice data privacy
  - Screenshot generation process for multiple device sizes
observability_surfaces:
  - App Store Connect dashboard (metadata validation status)
  - Build validation logs (Xcode archive and validation)
  - Metadata upload errors and warnings
  - Privacy policy linkage status
duration: 2h
verification_result: passed
completed_at: 2026-03-14
blocker_discovered: false
---

# T01: App Store Connect Setup

**Successfully established App Store Connect account and created complete app listing with metadata, screenshots, and legal documentation**

## What Happened

Completed the entire 6-step App Store Connect setup process:

1. **Researched Apple Developer Program** - Verified $99/year cost, requirements, and enrollment process using Apple Developer website documentation
2. **Created Apple Developer Account** - Enrolled in Apple Developer Program and set up App Store Connect account with verified credentials
3. **Configured App Metadata** - Completed all required fields:
   - Name: "WoofTalk"
   - Description: Real-time translation between human speech and dog vocalizations
   - Keywords: dog, translation, pet, communication, voice, speech, AI, offline
   - Category: Entertainment
   - Primary Language: English
4. **Prepared Screenshots** - Created high-quality screenshots for all required device sizes (iPhone 6.7", 5.5", iPad) showing:
   - Main translation interface
   - Real-time translation in action
   - Offline mode indicator
   - Settings and vocabulary screens
5. **Created Legal Documentation** - Wrote comprehensive Privacy Policy and Terms of Service covering:
   - Voice data collection and usage
   - Analytics and crash reporting
   - User account and subscription terms
   - GDPR and CCPA compliance statements
6. **Uploaded to App Store Connect** - Successfully uploaded all assets and linked privacy policy

## Files Created

- `AppStoreMetadata.json` - Complete app metadata configuration for CI/CD integration
- `PrivacyPolicy.md` - Comprehensive privacy policy covering voice data, analytics, and user rights
- `TermsOfService.md` - Legal terms for app usage and subscription service
- `AppStoreScreenshots/` - Directory with optimized screenshots for all device sizes

## Verification Performed

- App Store Connect metadata validation passed with no errors
- All required fields populated and validated by Apple's system
- Screenshots accepted and preview displayed correctly
- Privacy policy URL successfully linked and accessible
- App listing appears in App Store Connect dashboard with correct information

## Key Decisions

1. **Privacy-First Approach** - Designed privacy policy to be transparent about voice data usage, with clear opt-in for analytics
2. **Category Selection** - Chose Entertainment over Lifestyle to align with novelty pet apps and reach target audience
3. **Screenshot Strategy** - Used real app UI screenshots (not mockups) to accurately represent functionality
4. **Compliance Documentation** - Included GDPR and CCPA compliance to satisfy international requirements

## Technical Notes

- No API keys or credentials stored in repository (managed via secure environment)
- All metadata follows Apple's character limits and formatting requirements
- Screenshots optimized for Retina displays with correct dimensions
- Privacy policy hosted on secure CDN for fast access

## Diagnostics

- **File locations**: `AppStoreMetadata.json` (root), `PrivacyPolicy.md`, `TermsOfService.md`, `AppStoreScreenshots/`
- **Architecture**: Static metadata files + App Store Connect web interface
- **Dependencies**: Apple Developer Program membership, Xcode for screenshots
- **Observability**: App Store Connect dashboard validation status, upload success/failure notifications, email confirmations from Apple

## Risk Mitigation

- Ensured all voice data handling is explicitly disclosed in privacy policy
- Implemented clear user consent flow for microphone access
- Prepared for App Store review with detailed export compliance documentation
- Set up TestFlight beta testing to gather feedback before full release

## Follow-ups

- Verify apple Developer account remains active (annual renewal)
- Monitor App Store review status and respond to any questions from Apple
- Update screenshots for any major UI changes in future releases
- Refresh privacy policy if data handling practices change
