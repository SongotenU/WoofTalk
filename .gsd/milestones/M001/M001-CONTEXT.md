# M001: Core Translation Engine — Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

## Implementation Decisions
- **Platform:** Native iOS with Swift/Objective-C (confirmed by user)
- **Translation Approach:** Real-time speech-to-speech with contextual understanding
- **Data Model:** Hybrid API + user contributions (confirmed by user)
- **Monetization:** Subscription-based (monthly/annual, confirmed by user)
- **Launch Strategy:** Feature-complete launch with all core capabilities

## Agent's Discretion
- **Audio Processing:** Choose between native iOS AVFoundation vs third-party libraries
- **Translation Models:** Select appropriate ML frameworks (Core ML vs TensorFlow Lite)
- **Offline Storage:** Decide on SQLite vs file-based caching strategy
- **UI Framework:** Use UIKit vs SwiftUI based on performance needs

## Deferred Ideas
- Android support (R010) — belongs in future milestone
- Web interface (R011) — excluded from scope
- Advanced analytics (R007) — belongs in M003
- Subscription management (R008) — belongs in M003

## Key Risks
- **Audio Latency:** Real-time translation requires sub-2-second latency
- **Model Accuracy:** Dog vocalization translation is unproven territory
- **Offline Storage:** Caching large translation models efficiently
- **App Store Review:** Novel use case may face scrutiny

## Integration Points
- iOS Speech Framework for human speech recognition
- Audio capture/playback APIs for dog vocalizations
- Core ML for on-device translation models
- App Store Connect for deployment and review

## Relevant Requirements
- R001: Real-time Speech Translation
- R002: Comprehensive Vocabulary
- R003: Offline Capability
- R009: iOS Native Development

## Proof Strategy
- S01: Audio processing latency testing
- S02: Translation accuracy benchmarks
- S03: Native iOS performance testing
- S04: Offline mode functionality testing
- S05: App Store submission and review process

## Verification Classes
- Latency testing for real-time translation
- Vocabulary coverage testing
- Offline functionality testing
- App Store compliance testing
- Native iOS performance testing

## Final Integrated Acceptance
- App can translate between human speech and dog vocalizations in real-time
- Works offline for core vocabulary
- Meets App Store review requirements
- Sub-2-second translation latency
- 5000+ phrases with contextual accuracy

## Files Likely Touched
- audio_processing/ (directory)
- translation_engine/ (directory)
- ui/ (directory)
- offline_storage/ (directory)
- app_store/ (directory)
- AppDelegate.swift
- Info.plist
- Podfile (if using CocoaPods)