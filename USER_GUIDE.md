# User Guide — WoofTalk

## 1. Getting Started

### iOS/iPadOS
1. Download WoofTalk from the App Store
2. Grant microphone and notification permissions
3. Tap the microphone icon and speak
4. View translations in text and hear them spoken aloud

### Android
1. Install WoofTalk from Google Play Store
2. Grant microphone and notification permissions
3. Tap the mic button, speak, and see translations

### Web
1. Visit [wooftalk.app](https://wooftalk.app)
2. Sign in with your existing account (or create one)
3. Use your browser's microphone for voice input
4. Install as PWA for offline support

### Smartwatch (Wear OS)
1. Install WoofTalk from Play Store on your watch
2. Tap the watch complication to launch
3. Speak into your watch for quick translations

### Apple Vision Pro (AR)
1. Download WoofTalk AR from the App Store on your Vision Pro
2. Launch the app in AR mode
3. Point your view at a dog
4. Bark detection triggers translation bubbles in your field of view

**For users without Vision Pro:** WoofTalk also works with ARKit on supported iPhones — use the iPhone AR mode to see translation bubbles overlaid in your camera view.

### Meta Quest (VR)
1. Install WoofTalk VR from the Meta Quest Store (or App Lab during beta)
2. Put on your headset
3. You'll spawn in a virtual environment with a dog avatar
4. Speak or wait for bark detection
5. Translation bubbles appear near the avatar with spatial audio

## 2. Using AR Features (Vision Pro)

### Bark Detection
- The app continuously listens for dog barks via the Vision Pro's microphone
- When bark confidence exceeds 70%, a translation bubble appears
- Bubbles appear within 2 seconds of detection

### Bubble Interaction
- **Gaze**: Bubbles appear along your line of sight, positioned 1-10 meters away
- **Pinch**: Tap a bubble to dismiss it
- **Long-press**: Pin and hold bubbles so they don't auto-dismiss

### Readability
- Text scales dynamically based on distance (1-10m range)
- High contrast dark background with white text
- Drop shadow for outdoor readability

### Performance
- Target: 90 FPS with 3+ active bubbles
- If performance drops, bubbles with lower opacity auto-dismiss sooner

## 3. Using VR Features (Meta Quest)

### Environments
Choose from 3 virtual scenes:
- **Park**: Green grass, trees, outdoor feel
- **Living Room**: Cozy indoor setting with furniture
- **Beach**: Sand, ocean, bright sun

### Hand Tracking
- Look at your hands — they should appear in VR
- **Pinch**: Index finger + thumb together to press buttons
- Point at menu buttons and pinch to select

### Avatar Customization
- Access Settings → Avatar
- Choose breed: Golden, Black, Brown, White
- Toggle accessories: Collar, Hat, Glasses

### Comfort Settings
- **Vignette**: Reduces motion sickness during movement
- **Head-Locked UI**: Important info always visible in your view
- **FPS Display**: Toggle to monitor performance

### Bark Detection
- Speak near your Quest's microphone or play dog bark audio
- Bubbles appear near the dog avatar's position
- Spatial audio plays from the bubble's location (headphones recommended)

## 4. Bark Detection Accuracy Tips

1. **Minimize background noise** — loud environments reduce detection accuracy
2. **Position the microphone close** to the dog for best results
3. **Speak clearly** — the translation engine works best with distinct words
4. **Use high-quality speakers** for playing bark audio during testing
5. **Adjust confidence threshold** in Settings if you get false positives (increase) or missed detections (decrease)

## 5. Troubleshooting

### Common Issues

| Issue | Fix |
|-------|-----|
| No translation appears | Check internet connection, retry |
| Voice input not working | Grant microphone permission in system settings |
| AR bubbles not visible | Ensure camera passthrough is enabled (Vision Pro) |
| Hand tracking not working | Enable hand tracking in Quest system settings |
| Audio sounds flat | Use headphones for spatial audio on Quest |
| Slow response time | Check network latency, try reducing AI model complexity |
| VR motion sickness | Enable vignette in Comfort Settings, reduce session time |
| Bark detection triggers too often | Increase confidence threshold in Settings |
| Bark detection not triggering | Decrease confidence threshold, minimize background noise |

### Platform-Specific Fixes

**visionOS:**
- App crashes on launch → Ensure visionOS SDK is installed, reinstall from TestFlight
- Camera passthrough not available → Check that camera permission is granted in Settings

**Meta Quest:**
- APK won't install → Enable developer mode, check USB connection, try `adb devices`
- FPS below 72 → Lower environment quality in Settings (Quest 2 mode)

**iPhone ARKit (fallback):**
- AR not starting → Check `ARWorldTrackingConfiguration.isSupported`, update iOS
- Translation bubble off-screen → Calibrate device position, restart app

## 6. iPhone ARKit Fallback

For users without a Vision Pro:

1. Install WoofTalk on an iPhone with ARKit support (iPhone 6s or later)
2. Tap the AR button on the main screen
3. Allow camera access
4. Point your phone at a dog
5. Translation bubbles appear in your camera view

**ARKit vs Vision Pro differences:**
| Feature | Vision Pro | iPhone ARKit |
|---|---|---|
| Immersive passthrough | Full mixed reality | Camera overlay |
| Hand tracking | Yes (pinch, point) | Tap screen |
| Spatial audio | 3D anchored | Mono/stereo |
| Environment switching | Multiple virtual scenes | Camera passthrough only |

---

*Last updated: 2026-04-03 | Phase 42: Cross-Platform Integration*
