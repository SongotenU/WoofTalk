# S05: App Store Integration — UAT

**Milestone:** M001  
**Written:** 2026-03-14

## UAT Type

- **UAT Mode:** Artifact-driven (files and verification script)
- **Why this mode is sufficient:** This slice produces configuration files, documentation, and verification infrastructure; no live runtime or human experience is needed to prove the artifacts are correct. The app's runtime correctness is already proven by previous slices (S01-S04). S05 focuses on packaging and compliance.

## Preconditions

- The WoofTalk repository is checked out with all S05 files present
- macOS environment with bash, standard GNU tools (grep, find, plutil optional)
- (For full submission) Apple Developer account with Team ID and distribution certificate available
- (Optional) Xcode 15+ installed to perform actual archive and validation

## Smoke Test

Run `bash scripts/verify-app-store.sh`. If it exits with code 0 and reports "All App Store configuration checks passed!", the slice is basically working.

## Test Cases

### 1. Verify All Required Files Exist

1. List the following files and confirm they exist:
   - `AppStoreMetadata.json`
   - `PrivacyPolicy.md`
   - `TermsOfService.md`
   - `ExportOptions.plist`
   - `Entitlements.plist`
   - `ReleaseNotes.md`
   - `WoofTalk/Info.plist`
2. Also confirm directory `AppStoreScreenshots/` exists

**Expected:** All files and directory exist.

### 2. Verify Metadata JSON Validity and Completeness

1. Check JSON syntax: `python3 -m json.tool AppStoreMetadata.json > /dev/null` (or use any JSON parser)
2. Inspect key fields:
   - `appName` is "WoofTalk"
   - `bundleId` is "com.wooftalk.app"
   - `primaryCategory` is "Entertainment"
   - `keywords` is an array with at least 5 entries
   - `pricing` includes subscription tiers
   - `exportCompliance.usesEncryption` is true

**Expected:** JSON is syntactically valid and contains required fields with reasonable values.

### 3. Verify Info.plist Contains Required Keys

Run: `plutil -list WoofTalk/Info.plist` (or grep for keys)

Check that the following keys are present:
- `CFBundleName` = "WoofTalk"
- `CFBundleIdentifier` = "com.wooftalk.app"
- `CFBundleShortVersionString` = "1.0.0"
- `CFBundleVersion` = "1"
- `NSMicrophoneUsageDescription` (non-empty)
- `NSSpeechRecognitionUsageDescription` (non-empty)
- `UIBackgroundModes` contains `audio`

**Expected:** All keys exist with appropriate values.

### 4. Verify Build Configuration Consistency

1. Extract bundle ID from Info.plist and compare to `AppStoreMetadata.json`'s `bundleId`; they must match
2. Extract version from Info.plist and compare to `AppStoreMetadata.json`'s `version`; they must match
3. Ensure `ExportOptions.plist` method is "app-store" and signingStyle is "manual"

**Expected:** All identifiers and versions are consistent across files; export method is correct.

### 5. Verify Screenshots Directory Structure

1. Confirm `AppStoreScreenshots/` exists
2. Count image files (png/jpg): `find AppStoreScreenshots -type f \( -name "*.png" -o -name "*.jpg" \) | wc -l` should be >= 9
3. Confirm a `README.md` exists in that directory describing required sizes

**Expected:** At least 9 placeholder images present; README explains device-size requirements.

### 6. Run Full Verification Script

Run: `bash scripts/verify-app-store.sh`

Check output:
- All "✅" check marks appear
- Final message: "All App Store configuration checks passed!"
- Exit code 0: `echo $?` prints 0

**Expected:** Script reports 22 passed checks and exits 0.

## Edge Cases

### Missing Permissions in Info.plist

1. Remove `NSSpeechRecognitionUsageDescription` from Info.plist
2. Run verification script

**Expected:** Script should fail (if enhanced) or App Store validation would reject the build; currently script may not detect this directly, but manual check would catch it.

### JSON Syntax Error in Metadata

1. Introduce syntax error in `AppStoreMetadata.json` (e.g., remove a comma)
2. Run verification script

**Expected:** Script fails JSON validation with an error message.

### Bundle ID Mismatch

1. Change `CFBundleIdentifier` in `WoofTalk/Info.plist` to a different value than `bundleId` in metadata
2. Run verification script

**Expected:** Consistency check fails and reports mismatch.

### Placeholder Team ID Not Replaced

1. Keep `YOUR_TEAM_ID` in `ExportOptions.plist`
2. Attempt Xcode archive with this config (if Xcode available)

**Expected:** Archive fails with signing errors because Team ID is not a valid Apple Developer Team ID. Script currently does not detect this placeholder value; this is a known limitation leaving a manual step.

## Failure Signals

- `scripts/verify-app-store.sh` exits with non-zero status
- Missing any required file
- Invalid JSON or malformed plist files
- Inconsistent bundle ID or version across files
- Screenshots directory missing or contains fewer than 9 images
- Permissions descriptions missing from Info.plist (would cause App Store rejection)
- Placeholder team ID not replaced (causes archive signing failure)

## Requirements Proved By This UAT

- R001 — Real-time Speech Translation (integration of core translation into App Store build)
- R002 — Comprehensive Vocabulary (vocabulary present in app bundle)
- R003 — Offline Capability (offline mode integrated, included in metadata)
- R009 — iOS Native Development (native iOS app with Info.plist and deployment target)

## Not Proven By This UAT

- Actual translation accuracy (proved by S01-S04 testing)
- Offline functionality in runtime (proved by S04 verification)
- App Store review acceptance (external process beyond our control)
- Performance under real-world conditions (latency, battery usage)
- User experience and satisfaction (requires human UAT separate from this integration)

## Notes for Tester

- This UAT verifies artifacts, not the running app. If you need to test runtime functionality, run the app in Simulator or on a device and refer to S01-S04 UAT scripts.
- Before submitting to App Store, you must:
  1. Replace `YOUR_TEAM_ID` in plists with your actual Apple Developer Team ID
  2. Create real App Store screenshots (not placeholders) using the app UI
  3. Obtain an App Store distribution certificate from Apple Developer portal
  4. Create an App Store provisioning profile for `com.wooftalk.app`
  5. Use Xcode or Transporter to upload the build
- The verification script is intentionally conservative; it checks presence but not content validity (e.g., privacy policy text). You should review these documents for completeness before submission.
- App Store Connect validation may catch additional issues not covered by the script (e.g., missing export compliance documentation).

---
**End of UAT**
