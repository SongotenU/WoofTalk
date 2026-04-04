# Phase 42: Cross-Platform Integration - Context

**Date:** 2026-04-03
**Status:** Ready for planning

## Phase Requirements

### Cross-Platform Sync
- X-01: Translation history sync across all platforms (iOS, Android, Web, Watch, AR, VR) via Supabase
- X-02: Shared user settings (bubble preferences, audio volume, default platform)
- X-03: Platform-specific analytics (session length, accuracy feedback, FPS metrics)

### Store Submission
- X-04: visionOS App Store submission guide, TestFlight beta distribution
- X-05: Meta Quest Store submission (screenshots, videos, compliance checklist)

### Deployment
- X-06: Deployment documentation, user guides, fallback strategies (iPhone ARKit for non-Vision Pro)

### Data Model Extensions
- DATA-ARVR-01: Add platform column to translation_history
- DATA-ARVR-02: Add spatial_position JSONB to translation_history
- DATA-ARVR-03: New dog_avatars table for VR avatar customization
- DATA-ARVR-04: New user_devices table for tracking registered AR/VR hardware
- DATA-ARVR-05: Backfill platform for historical records
- DATA-ARVR-06: RLS policies for new tables

## Building on Prior Phases

Phase 40: VR Foundation — Unity project, Meta XR SDK, DogAvatar, hand tracking, bubbles, bark detection, spatial audio
Phase 41: VR Environments & Polish — environment switching, avatar customization, performance, motion sickness, settings, testing

## Decisions from Prior Phases (inherited)

- Meta XR All-in-One SDK v63+ via scoped registry
- TFLite model with mock fallback for bark detection
- Bubble pool size 5, auto-dismiss 5s
- Quality presets: Quest 2 (72 FPS), Quest 3 (90 FPS)
- Settings persistence via PlayerPrefs
- EnvironmentManager supports park/livingroom/beach

## Claude's Discretion

All implementation choices at Claude's discretion — use ROADMAP requirements and codebase conventions.
