---
estimated_steps: 6
estimated_files: 4
---

# T01: App Store Connect Setup

**Slice:** S05 — App Store Integration
**Milestone:** M001

## Description

Set up Apple Developer Program membership and create the App Store Connect account and app listing. This task establishes the foundation for App Store distribution by configuring all necessary metadata, legal documentation, and account setup.

## Steps

1. Research Apple Developer Program requirements and costs ($99/year)
2. Set up Apple Developer account and enroll in Developer Program
3. Create App Store Connect account and verify developer credentials
4. Configure app metadata (name, description, keywords, categories, primary language)
5. Prepare and upload App Store screenshots for all required device sizes
6. Create privacy policy documentation and upload to App Store Connect

## Must-Haves

- [ ] Apple Developer Program membership active
- [ ] App Store Connect account created and verified
- [ ] App metadata configured with name, description, keywords, categories
- [ ] App Store screenshots uploaded (minimum 3 per device size)
- [ ] Privacy policy created and linked
- [ ] App listing appears in App Store Connect dashboard

## Verification

- App Store Connect dashboard shows the app with correct metadata
- All required fields are populated and validated
- Screenshots appear correctly in the app listing preview
- Privacy policy is linked and accessible

## Observability Impact

- Signals added: App Store Connect API response codes, validation status
- How a future agent inspects this: App Store Connect dashboard, developer account status
- Failure state exposed: Account verification failures, metadata validation errors, screenshot upload issues

## Inputs

- Existing translation app functionality (from S01-S04)
- Legal requirements for privacy policy and terms of service
- App Store review guidelines and requirements

## Expected Output

- `AppStoreMetadata.json` — Complete app metadata configuration
- `PrivacyPolicy.md` — Privacy policy documentation
- `TermsOfService.md` — Legal terms of service
- App Store Connect account and app listing ready for build submission