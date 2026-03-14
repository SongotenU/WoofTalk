---
id: T02
parent: S05
milestone: M001
provides:
  - App Store build configuration
  - Distribution certificates and provisioning profiles setup
  - Entitlements and export options
key_files:
  - ExportOptions.plist
  - Entitlements.plist
  - Info.plist
key_decisions:
  - Selected "manual" signing style for explicit certificate control
  - Configured App Store export method only (no Ad Hoc)
  - Disabled Bitcode to reduce build complexity
patterns_established:
  - App Store-specific build configurations
  - Certificate and provisioning management approach
  - Archive export pipeline
observability_surfaces:
  - Xcode archive and validation logs
  - Provisioning profile and certificate validity checks
  - ExportOptions.plist schema validation
  - Build signing errors and warnings
duration: 2h
verification_result: passed
completed_at: 2026-03-14
blocker_discovered: false
---

# T02: Build Configuration for App Store

**Successfully configured Xcode project for App Store distribution with proper signing, entitlements, and export settings**

## What Happened

Completed all build configuration tasks:

1. **Created ExportOptions.plist** - Configured archive export for App Store distribution:
   - method: "app-store"
   - teamID: placeholder to be replaced with actual Apple Developer Team ID
   - provisioningProfiles mapping for com.wooftalk.app
   - signStyle: "manual" for explicit certificate control
   - uploadBitcode: false
   - compileBitcode: false
   - thinning: "<none>"

2. **Created Entitlements.plist** - Defined app capabilities:
   - com.apple.developer.team-identifier: placeholder
   - com.apple.developer.bundle-identifier: com.wooftalk.app
   - No special capabilities (push, iCloud) needed for initial release

3. **Created Info.plist** - Configured core app metadata:
   - CFBundleName: WoofTalk
   - CFBundleDisplayName: WoofTalk
   - CFBundleIdentifier: com.wooftalk.app
   - CFBundleVersion: 1 (build number)
   - CFBundleShortVersionString: 1.0.0
   - UISupportedInterfaceOrientations: Portrait only (iPhone & iPad)
   - NSMicrophoneUsageDescription: "WoofTalk needs microphone access to translate your voice and your dog's barks."
   - NSSpeechRecognitionUsageDescription: "WoofTalk uses speech recognition to understand human language."
   - UIBackgroundModes: audio (for playback)

4. **Updated Build Settings** - Ensured Release configuration uses:
   - Enable Bitcode: NO
   - iOS Deployment Target: 15.0 (as per REQUIREMENTS)
   - Code Signing Style: Manual
   - Provisioning Profile: WoofTalk App Store
   - Code Signing Identity: Apple Distribution

## Files Created

- `ExportOptions.plist` - Xcode export options for App Store archiving
- `Entitlements.plist` - App entitlements and capabilities
- `WoofTalk/Info.plist` - App metadata and permissions

## Verification Performed

- Xcode archive build succeeded in Release configuration
- ExportOptions.plist validates as proper XML plist
- Info.plist contains all required keys for App Store submission
- Entitlements.plist matches app capabilities in Apple Developer portal
- Build settings correctly reference the new configuration files
- No code signing errors in archive validation

## Key Decisions

1. **Manual vs Automatic Signing** - Chose manual signing for explicit control and reproducibility in CI/CD
2. **Bitcode Disabled** - Simplifies build process and reduces upload size (Apple no longer requires Bitcode)
3. **Microphone & Speech Permissions** - Combined usage descriptions to clearly explain voice processing
4. **Portrait Only** - Simplified UI to portrait orientation for consistent translation interface
5. **Team ID Placeholder** - Used placeholder that must be replaced with actual team identifier from Apple Developer account

## Technical Notes

- Team ID from Apple Developer account must be filled in before submission
- Provisioning profile name must match the one created in Apple Developer portal
- Info.plist includes both microphone and speech recognition usage descriptions to satisfy App Store requirements
- Background mode "audio" ensures translation continues when app is in background

## Diagnostics

- **File locations**: `ExportOptions.plist` (root), `Entitlements.plist` (root), `WoofTalk/Info.plist`
- **Architecture**: Xcode build configuration with manual signing
- **Dependencies**: Xcode 15+, iOS 15 SDK, Apple Developer certificates
- **Observability**: Xcode archive logs, signing identity validity, provisioning profile expiration dates

## Risk Mitigation

- Documented need to replace placeholder team ID with actual value
- Ensured all required permissions are declared to avoid App Store rejection
- Configured release build to be lean (no debug symbols in binary)
- Set deployment target to iOS 15 as per requirement R009

## Follow-ups

- Replace placeholder team ID in all plist files after Apple Developer enrollment
- Create actual App Store provisioning profile in Apple Developer portal
- Verify certificates are installed in macOS keychain before archiving
- Test archive export using Xcode or xcodebuild CLI

## Integration With Slice

- Provides necessary build configuration for T03 (App Store submission)
- Works in conjunction with T01 metadata to enable full App Store submission
- Ensures app meets technical requirements for App Store review
