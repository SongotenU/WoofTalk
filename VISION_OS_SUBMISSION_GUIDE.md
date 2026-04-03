# visionOS App Store Submission Guide

## 1. Xcode Archive and Export

### Prerequisites
- Mac with Xcode 15.2+ (with visionOS SDK installed)
- Apple Developer Program membership ($99/year)
- Provisioning profiles with visionOS capability enabled

### Archive Steps
1. Open `WoofTalk.xcodeproj` in Xcode
2. Select **visionOS** as deployment target (Any visionOS Device, not Simulator)
3. Set build configuration to **Release**
4. Product → Clean Build Folder (`Cmd+Shift+K`)
5. Product → Archive (wait for build completion)

### Export Steps
1. Open Xcode → Window → Organizer
2. Select the archived build
3. Click **Distribute App** → **App Store Connect** → **Upload**
4. Xcode will validate and upload the binary

## 2. App Store Connect Setup

### Required Assets
| Asset | Specification |
|-------|---------------|
| App Icon | 1024x1024 PNG (no transparency) |
| Screenshots | 6–9 screenshots for visionOS (various display modes) |
| Subtitle | 30 characters max |
| Description | Clear description of dog translation features |
| Privacy Manifest | Required for camera and microphone usage |

### Required Entitlements
- `com.apple.developer.visionOS.camera` — for camera passthrough and bark detection
- `com.apple.developer.visionOS.microphone` — for audio recording

### Privacy Descriptions
Add to `Info.plist`:
- `NSCameraUsageDescription`: "Camera access is used for augmented reality overlay of dog translation bubbles in your physical space."
- `NSMicrophoneUsageDescription`: "Microphone access is used to detect dog barks and vocalizations for translation."

## 3. TestFlight Beta Distribution

### Upload to App Store Connect
1. Archive and upload binary (see Section 1)
2. Navigate to [App Store Connect](https://appstoreconnect.apple.com/)
3. Select your app → **TestFlight** tab
4. Wait for processing (usually 5-30 minutes)

### Add Testers
1. Create internal testers (team members with Apple ID)
2. Create external tester groups
3. Invite via email or public link
4. Set expiry date (90 days default, can be extended)

### Beta Review
- External TestFlight builds require Apple review (~24-48 hours)
- Internal builds are available immediately

## 4. Common Rejection Reasons

| Reason | Fix |
|--------|-----|
| Missing privacy strings | Ensure `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` are present in Info.plist |
| Camera permission not justified | Explain why camera is needed in app description and review notes |
| Crashes on visionOS Simulator | Test on actual hardware before submission |
| Inconsistent UI across platforms | Ensure visionOS UI follows native visionOS design patterns |
| Spatial audio issues | Test spatial audio with headphones before submission |

## 5. Submission Checklist

- [ ] App Icon uploaded (1024x1024)
- [ ] 6+ screenshots for visionOS
- [ ] Subtitle and Description finalized
- [ ] Privacy Manifest included
- [ ] Camera and Microphone usage descriptions in Info.plist
- [ ] All visionOS entitlements configured
- [ ] Binary archived and uploaded successfully
- [ ] TestFlight beta tested with 10+ users
- No critical crashes in crash logs
- Spatial audio tested on actual Vision Pro hardware
- Review notes submitted to Apple

## 6. Timeline

| Step | Duration |
|------|----------|
| Xcode Archive & Upload | 30-60 min |
| App Store Review | 24-48 hours |
| Rejection response (if needed) | 1-3 days per round |
| Approval to Live | 24 hours |

---

*Last updated: 2026-04-03 | Phase 42: Cross-Platform Integration*
