# WoofTalk Store Assets Checklist

Generated: 2026-05-05  
Platforms: iOS (App Store), Android (Play Store)

---

## iOS App Store Assets (Required)

### Screenshots (Required)
| Device | Size | Qty Needed | Status |
|--------|------|------------|--------|
| iPhone 6.7" (Pro Max) | 1290×2796 px | 3-10 | ⬜ TODO |
| iPhone 6.5" (XS Max) | 1242×2688 px | 3-10 | ⬜ TODO |
| iPhone 5.5" (Plus) | 1242×2208 px | 3-10 | ⬜ TODO |
| iPad Pro 12.9" | 2048×2732 px | 3-10 | ⬜ TODO |

**Screenshot Content Checklist:**
- [ ] Translation screen (Dog translation in action)
- [ ] Community phrases browser
- [ ] Social features (leaderboard, followers)
- [ ] Settings/Subscription screen
- [ ] Watch app (if shown on iPhone)

### App Icon
- [ ] 1024×1024 px (PNG, no alpha)
- [ ] No rounded corners (Apple adds them)
- [ ] High contrast, recognizable at small sizes
- **Status**: ⬜ TODO (design needed)

### Promo Video (Optional but Recommended)
- [ ] 15-30 second demo video
- [ ] Show translation in action
- [ ] Highlight premium features
- **Status**: ⬜ TODO

### App Store Metadata
- [ ] App name: "WoofTalk — Dog Translator"
- [ ] Subtitle: "Talk to your pets!"
- [ ] Category: Entertainment / Utilities
- [ ] Keywords: dog, translator, pet, communication, animal
- [ ] Privacy policy URL: https://wooftalk.app/privacy
- [ ] Support URL: https://wooftalk.app/support
- **Status**: ⬜ TODO

---

## Google Play Store Assets (Required)

### Screenshots — Phone
| Type | Size | Qty Needed | Status |
|------|------|------------|--------|
| JPEG/PNG | 16:9 (1920×1080) or 9:16 (1080×1920) | 2-8 | ⬜ TODO |
| Feature Graphic | 1024×500 px | 1 | ⬜ TODO |

**Screenshot Content (same as iOS):**
- [ ] Translation screen
- [ ] Community phrases
- [ ] Social features
- [ ] Settings/Subscription

### Screenshots — Tablet (Optional)
- [ ] 7-inch and 10-inch tablet screenshots
- **Status**: ⬜ TODO

### App Icon
- [ ] 512×512 px (PNG, 32-bit)
- [ ] Adaptive icon (foreground + background layers)
- **Status**: ⬜ TODO (design needed)

### Promo Video (Optional)
- [ ] YouTube link (public or unlisted)
- [ ] 30-second demo
- **Status**: ⬜ TODO

### Play Store Metadata
- [ ] App name: "WoofTalk — Dog Translator"
- [ ] Short description: "Translate between humans and dogs, cats, and birds!"
- [ ] Full description: (use content from README.md)
- [ ] Privacy policy URL: https://wooftalk.app/privacy
- [ ] Content rating questionnaire (completed in Play Console)
- **Status**: ⬜ TODO

---

## Wear OS App (Google Play)

### Screenshots
- [ ] Square (1:1) 320×320 px
- [ ] Round (1:1) 320×320 px
- **Status**: ⬜ TODO

---

## Web App Assets

- [ ] Favicon (16×16, 32×32, 64×64)
- [ ] Social sharing image (1200×630 px, for Open Graph)
- [ ] PWA icons (192×192, 512×512)
- **Status**: ✅ Mostly configured in `web/public/`

---

## How to Generate Screenshots

### iOS (Simulator)
```bash
# 1. Open Xcode → Run on simulator (iPhone 15 Pro Max)
# 2. Navigate through the app (translation, community, etc.)
# 3. Take screenshot: Device → Screenshot (Cmd+S)
# 4. Save to: /AppStoreScreenshots/ios/
```

### Android (Emulator)
```bash
# 1. Open Android Studio → Run on emulator (Pixel 8 Pro)
# 2. Navigate through the app
# 3. Take screenshot: Click camera icon in emulator toolbar
# 4. Save to: /AppStoreScreenshots/android/
```

### Tools
- **Xnapper** / **CleanShot X** (macOS) — for nice borders/effects
- **App Store Screenshot Maker** — auto-generate sizd variations
- **Figma** — design app icon, feature graphic

---

## Estimated Time
- Screenshots: 2-3 hours (capture + edit)
- App icon: 1-2 hours (design)
- Feature graphic: 1 hour (design)
- Metadata entry: 1 hour
- **Total**: 5-7 hours

---

## Next Steps
1. Capture screenshots on simulators/emulators
2. Edit with consistent styling (borders, device frames)
3. Design app icon (if not already done)
4. Resize to all required dimensions
5. Upload to App Store Connect / Google Play Console
6. Complete metadata forms
7. Submit for review
