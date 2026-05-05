# App Store Connect Configuration - Manual Instructions

## Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode 16.2+ installed
- Valid Apple ID signed in to Xcode

## Step 1: Register Bundle ID

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Click "Identifiers" → "+" button
4. Select "App IDs" → Continue
5. Fill in:
   - **Description**: WoofTalk
   - **Bundle ID**: com.wooftalk.app (Explicit)
   - **Capabilities**: Enable "In-App Purchase"
6. Click Continue → Register

## Step 2: Create Distribution Certificate

1. In Certificates, Identifiers & Profiles, click "Certificates" → "+"
2. Select "iOS Distribution (App Store and Ad Hoc)"
3. Follow instructions to create Certificate Signing Request (CSR):
   - Open Keychain Access on Mac
   - Certificate Assistant → Request a Certificate from a Certificate Authority
   - Enter email, select "Saved to disk"
4. Upload CSR file
5. Download the .cer file
6. Double-click to install in Keychain

## Step 3: Create Provisioning Profile

1. Click "Profiles" → "+"
2. Select "App Store" → Continue
3. Select App ID: com.wooftalk.app
4. Select distribution certificate created in Step 2
5. Name: "WoofTalk App Store Profile"
6. Download .mobileprovision file
7. Double-click to install in Xcode

## Step 4: Configure Xcode Project

1. Open WoofTalk.xcodeproj in Xcode
2. Select project → Targets → WoofTalk
3. Signing & Capabilities tab:
   - Team: Select your Apple Developer account
   - Bundle Identifier: com.wooftalk.app
   - Check "Automatically manage signing"
   - provisioning profile should auto-select

## Step 5: Verify Configuration

Run in terminal:
```bash
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk
xcodebuild -project WoofTalk.xcodeproj -scheme WoofTalk -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER
```

Expected output: `com.wooftalk.app`

## Notes

- Xcode automatic signing is recommended over manual provisioning
- Certificate expires after 1 year, renewal required
- Provisioning profiles auto-renew with automatic signing
