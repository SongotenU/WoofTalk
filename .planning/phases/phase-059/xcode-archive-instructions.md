# Xcode Archive & Upload - Manual Instructions

## Prerequisites

- App Store Connect configured (59-03 ✅)
- App Store metadata prepared (59-01 ✅)
- Screenshots ready (59-02 ✅)
- Valid Apple Developer account signed in to Xcode

## Step 1: Open Xcode and Configure

```bash
open /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/WoofTalk.xcodeproj
```

1. In Xcode, select target: **Any iOS Device (arm64)** (top toolbar, next to Run button)
2. Go to Product → Scheme → Edit Scheme
3. Select "Archive" on left
4. Set Build Configuration to: **Release**

## Step 2: Archive the App

1. Product → Archive (or Cmd+Shift+B)
2. Wait for archive to complete (5-15 minutes)
3. Organizer window will appear automatically

**Troubleshooting:**
- If archive fails, check:
  - No compile errors (Product → Build first)
  - Signing certificate valid
  - Bundle ID registered

## Step 3: Upload to App Store Connect

1. In Organizer window, select the archive
2. Click **"Distribute App"** button
3. Select: **App Store Connect** → Next
4. Select: **Upload** (not "Export")
5. Distribution certificate: Select your iOS Distribution certificate
6. Provisioning profile: Select "WoofTalk App Store Profile"
7. Check "Include bitcode" (if needed, usually unchecked now)
8. Check "Upload your app's symbols" (recommended)
9. Click **Upload**

## Step 4: Verify Upload

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Log in with your Apple ID
3. Click "My Apps" → WoofTalk
4. Go to "TestFlight" or "App Store" tab
5. Build should appear with status: **Processing**

**Processing time:** 5-30 minutes (Apple scans the binary)

## Step 5: Complete App Information

Once build status is **Ready for Submission**:

1. App Store tab → App Information:
   - Name: WoofTalk
   - Subtitle: AI-powered pet translator
   - Primary Category: Lifestyle
   - Secondary Category: Utilities
   - Content Rights: Does not use third-party content

2. Pricing and Availability:
   - Price: Free (with IAP)
   - Availability: All territories

3. Prepare for Submission:
   - Upload screenshots (59-02)
   - Enter description, keywords (from app-store-metadata.md)
   - Add support URL: https://wooftalk.app/support
   - Add privacy policy URL: https://wooftalk.app/privacy-policy
   - Check "Made for Kids": NO

4. Build section:
   - Select the uploaded build

5. Click **"Submit for Review"**

## Expected Result

- Build status: **Waiting for Review**
- Apple review typically takes 24-48 hours
- You'll receive email notifications at each stage

## Notes

- Ensure privacy policy is accessible at the URL provided
- TestFlight internal testing is recommended before production submission
- Have login credentials ready if app requires sign-in (Apple will test)
