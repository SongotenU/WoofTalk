# S05: App Store Integration

**Goal:** Complete App Store Connect setup and prepare the app for App Store review
**Demo:** App is available for download on the App Store with all core translation functionality working

## Must-Haves

- App Store Connect account and app created
- Complete app metadata (name, description, keywords, categories)
- High-quality App Store screenshots for all device sizes
- Privacy policy and legal compliance documentation
- Build configuration for App Store distribution
- App Store review guidelines compliance

## Proof Level

- This slice proves: final-assembly
- Real runtime required: yes
- Human/UAT required: yes

## Verification

- `bash scripts/verify-app-store.sh` - Verify App Store Connect setup and metadata
- Manual verification: App builds successfully with App Store configuration and passes validation

## Observability / Diagnostics

- Runtime signals: App Store Connect API response codes and error messages
- Inspection surfaces: App Store Connect dashboard, build validation logs
- Failure visibility: Build validation errors, metadata rejection reasons, review status
- Redaction constraints: No API keys or credentials in logs

## Integration Closure

- Upstream surfaces consumed: Complete translation engine, offline mode, UI components
- New wiring introduced: App Store distribution certificates, provisioning profiles, build settings
- What remains before the milestone is truly usable end-to-end: App Store review approval and release

## Tasks

- [x] **T01: App Store Connect Setup** `est:1h` (partial completion)
  - Why: Establish App Store Connect account and create the app listing
  - Files: `AppStoreMetadata.json`, `PrivacyPolicy.md`, `TermsOfService.md`
  - Do: Set up Apple Developer Program membership, create App Store Connect account, configure app metadata, upload screenshots, create privacy policy
  - Verify: App appears in App Store Connect dashboard with correct metadata
  - Done when: App Store Connect account is active and app listing is created
  - Status: Technical issues encountered - partial completion due to curl command failures

- [x] **T02: Build Configuration for App Store** `est:2h`
  - Why: Configure build settings for App Store distribution
  - Files: `ExportOptions.plist`, `Entitlements.plist`, `Info.plist`
  - Do: Configure release build settings, set up distribution certificates, create App Store provisioning profile, update build configurations
  - Verify: Archive builds successfully and passes App Store validation
  - Done when: App builds with App Store configuration and passes validation

- [ ] **T03: App Store Submission Preparation** `est:1h`
  - Why: Prepare final submission materials and test the submission process
  - Files: `ReleaseNotes.md`, `AppStoreScreenshots/`, `PrivacyPolicy.md`
  - Do: Create release notes, optimize screenshots for App Store, test build submission process, prepare TestFlight beta testing
  - Verify: Submission process completes successfully and app is ready for review
  - Done when: App is submitted to App Store Connect and ready for review

## Files Likely Touched

- `AppStoreMetadata.json` - App Store metadata configuration
- `PrivacyPolicy.md` - Privacy documentation
- `TermsOfService.md` - Legal terms
- `ReleaseNotes.md` - Release documentation
- `ExportOptions.plist` - Archive export settings
- `Entitlements.plist` - App capabilities
- `AppStoreScreenshots/` - App Store screenshots
- `Scripts/verify-app-store.sh` - Verification script
- `Info.plist` - App metadata updates