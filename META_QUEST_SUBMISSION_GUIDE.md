# Meta Quest Store Submission Guide

## 1. Quest Build Process

### Unity Build Settings
1. Open `vr-quest/` project in Unity 2022 LTS
2. File → Build Settings
3. Platform: **Android**
4. Architecture: **ARM64**
5. Scripting Backend: **IL2CPP**
6. Texture Compression: **ASTC**
7. Development Build: **unchecked** (for release builds)
8. Click **Build** → Output as `.apk` or use **Meta Quest Deploy** tool

### Required Build Configurations
- Target API Level: 32+ (Quest OS requirement)
- Minimum API Level: 29
- Package Name: `com.wooftalk.vr`
- Version Code: Increment with each release
- Keystore: Sign APK with release keystore (create once, reuse for all updates)

## 2. Meta Quest Store Listing

### App Screenshots Requirements
- Format: 1920x1080 PNG or JPG
- Minimum: 3 screenshots required
- Recommended: 6-8 screenshots
- Content must showcase:
  1. Main translation bubble interface
  2. Environment selection screen
  3. Hand tracking menu navigation
  4. Settings menu
  5. Dog avatar customization
  6. Different virtual environment (park/living room/beach)

### Store Listing Assets
| Asset | Specification |
|-------|---------------|
| App Icon | 512x512 PNG (no transparency) |
| Screenshots | 1920x1080, 3+ required |
| Trailer Video | Optional, 30-90 seconds, MP4 |
| Description | 100-4000 characters |
| Short Description | 55 characters max |
| Category | Education, Productivity |

### Privacy Policy URL
- Host a privacy policy page on your website
- Must describe: camera/microphone data collection, storage, third-party sharing

## 3. Compliance Checklist

### Health & Safety Warnings
- [ ] **Health Warning Screen**: Display before app starts (epilepsy, photosensitivity, motion sickness)
- [ ] **Boundary System**: Respect Guardian/Play Area boundaries
- [ ] **Comfort Settings Documented**: List all comfort options in app (vignette, teleportation, snap-turn)

### Age Rating
- [ ] App rated **Everyone** or **12+** depending on content
- [ ] Rating justification provided in submission

### Technical Requirements
- [ ] Minimum 72 FPS on Quest 2 (Quest 3: 90 FPS)
- [ ] No crashes during 30-minute session
- [ ] Hand tracking or controller support functional
- [ ] Audio output clear and at reasonable levels

### Privacy
- [ ] Privacy policy URL provided
- [ ] User data collection disclosed
- [ ] Account creation not required for basic use (anonymous auth OK)

### Content Guidelines
- [ ] No offensive content in dog breed selections or translations
- [ ] Community features moderated or user-reportable
- [ ] In-app purchases (if any) clearly disclosed

## 4. Meta Quest App Lab (Testing Distribution)

For early testing before full Store submission:

### App Lab Setup
1. Create Meta Developer account at [developers.meta.com](https://developers.meta.com/)
2. Create Organization for your team
3. Generate Access Token for Unity Package Manager
4. Upload APK via Meta Quest Developer Dashboard

### Side-Loading for Testing
1. Enable Developer Mode on Quest device via Meta Quest mobile app
2. Connect Quest via USB-C to development machine
3. Install `adb` on your machine
4. Run `adb install woofTalk-vr.apk`
5. Launch from **Unknown Sources** in Quest Library

### App Lab Submission
1. Submit build to App Lab via Developer Dashboard
2. Provide screenshots, description, pricing
3. Review timeline: 2-4 weeks (similar to Store review)

## 5. Submission Review Process

### Initial Review
1. Meta team tests your app on Quest 2 and Quest 3 hardware
2. Checks for crashes, performance issues, compliance violations
3. Reviews store listing accuracy (screenshots, description, icon)

### Feedback
- Meta may reject with specific areas to fix
- Common rejections: FPS below 72, crashes, missing health warnings
- You can resubmit after fixing issues

### Approval & Publication
- After approval: you choose publication date
- App goes live in Meta Quest Store
- Users can discover and purchase

## 6. Timeline

| Step | Duration |
|------|----------|
| Build and sign APK | 30-60 min |
| Prepare store assets | 2-4 hours |
| App Lab upload | 30 min |
| Meta Review | 2-4 weeks |
| Rejection response (if needed) | 1-2 weeks per round |
| Publication | 24-48 hours after approval |

---

*Last updated: 2026-04-03 | Phase 42: Cross-Platform Integration*
