# S03: Core UI & UX - Plan

**Goal:** Build a native iOS app with intuitive translation interface that maintains real-time performance and adds offline capability
**Demo:** Launch the iOS app, perform real-time translation between human and dog, switch to offline mode, and verify all UI flows work smoothly

## Must-Haves
- Native iOS app launches successfully with proper entry point
- Real-time translation interface functional with smooth animations
- Offline mode works with cached translations and connectivity detection
- App Store compliance features implemented
- Sub-2-second translation latency maintained

## Proof Level

- This slice proves: final-assembly
- Real runtime required: yes
- Human/UAT required: yes

## Verification

- `XCTest` suite with UI tests covering launch, translation flow, and offline mode
- `IntegrationTests.swift` testing end-to-end translation functionality
- Manual verification: app launches, translation works, offline mode accessible
- Performance verification: latency <2 seconds maintained

## Observability / Diagnostics

- Runtime signals: translation state machine status, latency metrics, connectivity indicators
- Inspection surfaces: Xcode debug console, performance profiling, network logs
- Failure visibility: translation errors, audio processing failures, connectivity status
- Redaction constraints: no user data logging, secure API key handling

## Integration Closure

- Upstream surfaces consumed: TranslationEngine, AudioTranslationBridge, OfflineTranslationManager from S02
- New wiring introduced in this slice: AppDelegate, Main.storyboard, navigation controllers, offline mode integration
- What remains before the milestone is truly usable end-to-end: App Store submission preparation, final compliance review

## Tasks

- [x] **T01: Create App Entry Point and Core Navigation** `est:2h`
  - Why: Establish the foundation for the entire iOS app structure
  - Files: `AppDelegate.swift`, `Main.storyboard`, `Info.plist`, `MainViewController.swift`
  - Do: Create app entry point with proper lifecycle management, set up main navigation controller with tab bar, configure Info.plist for App Store compliance
  - Verify: App launches successfully, navigation structure works, App Store metadata present
  - Done when: App builds and launches with main navigation visible
- [x] **T02: Implement Real-time Translation Interface** `est:3h`
  - Why: Build the core UI that users interact with for translation
  - Files: `TranslationViewController.swift`, `RealTranslationController.swift`, UI assets, translation interface storyboard
  - Do: Implement real-time translation UI with smooth animations, latency indicators, translation history, and audio controls
  - Verify: Real-time translation works, latency <2 seconds, UI responsive during audio processing
  - Done when: Translation interface functional and meets performance requirements
- [ ] **T03: Add Offline Mode and Settings** `est:2h`
  - Why: Complete the core app functionality with offline capability and user preferences
  - Files: `OfflineModeViewController.swift`, `SettingsViewController.swift`, `ConnectivityManager.swift`, offline UI components
  - Do: Implement offline mode UI, connectivity detection, cached translation access, and user settings management
  - Verify: Offline mode works, cached translations accessible, settings persist
  - Done when: Offline functionality complete and integrated with main app flow
- [ ] **T04: Add App Store Compliance and Polish** `est:1h`
  - Why: Ensure the app meets App Store requirements and has professional polish
  - Files: App Store metadata, privacy policy, help documentation, final UI refinements
  - Do: Add App Store compliance features, privacy policy, help system, and final UI polish
  - Verify: App passes App Store compliance checks, all UI elements functional
  - Done when: App is polished and compliant with App Store guidelines

## Files Likely Touched

- `AppDelegate.swift`
- `Main.storyboard`
- `MainViewController.swift`
- `TranslationViewController.swift`
- `OfflineModeViewController.swift`
- `SettingsViewController.swift`
- `Info.plist`
- App Store metadata files
- UI assets and resources
- Test files for UI and integration testing