# iOS App Store Screenshots - Manual Instructions

## Required Screenshots

Since iOS Simulator is not available in this environment, screenshots must be taken manually.

### Device Sizes Required

| Device | Screen Size | Dimensions (px) | Status |
|--------|-------------|------------------|--------|
| iPhone 14 Pro Max | 6.7" | 1290 x 2796 | Pending |
| iPhone 14 Plus | 6.7" | 1284 x 2778 | Pending |
| iPhone 8 Plus | 5.5" | 1242 x 2208 | Pending |
| iPad Pro 12.9" | 12.9" | 2048 x 2732 | Pending |
| iPad Pro 11" | 11" | 1668 x 2388 | Pending |

### Screens to Capture (5-10 screens per device)

1. **Home Screen** - Main translation interface with pet selector (Dog/Cat/Bird)
2. **Translation in Progress** - Voice input active, waveform visualization
3. **Translation Result** - Human→Dog translation with audio playback
4. **Community Phrases** - Browse user-submitted translations
5. **Social Feed** - Activity feed with user interactions
6. **Settings** - App settings with subscription management
7. **Paywall/Subscription** - Premium subscription options
8. **Translation History** - Past translations list

### Steps to Capture

1. Open WoofTalk project in Xcode:
   ```bash
   open /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/WoofTalk.xcodeproj
   ```

2. Select target device simulator (iPhone 14 Pro Max recommended)

3. Build and run (Cmd+R)

4. Navigate through each screen and capture:
   - Use `Cmd+S` to save screenshot to Desktop
   - Or use Xcode → Debug → Simulate Location → [select location]

5. Resize screenshots to required dimensions using Preview or ImageMagick:
   ```bash
   # Example resize command (if ImageMagick installed)
   convert screenshot.png -resize 1290x2796 screenshot-iphone-14-pro-max.png
   ```

6. Save to: `store-assets/screenshots/ios/`

### Notes

- All screenshots must be without simulator bezels or status bar extras
- Use light mode for all screenshots (unless app is dark-mode only)
- Ensure no personal information is visible
- Apple may reject screenshots with transparency
