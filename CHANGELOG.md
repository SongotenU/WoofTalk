# Changelog

All notable changes to WoofTalk Web will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] — 2026-05-13

### Added
- Web Vitals performance monitoring (CLS, INP, LCP, FCP, TTFB) via Web Vitals library
- WebAssembly runtime detection and graceful degradation
- Service worker with version caching for offline resilience
- Web Speech API integration for audio playback (bark previews, text-to-speech)
- Phase 61 E2E test suite: 5/5 Playwright smoke tests passing

### Changed
- AGP downgraded 8.10→8.7.0 for Gradle 8.9 compatibility
- iOS project files rebuilt with correct source references
- E2E test selectors hardened for hydration compatibility
- Next.js config simplified with static export support
- Error instrumentation streamlined (11 imports, single init)

### Fixed
- Missing heading on translate page (E2E requirement)
- iOS project.pbxproj source file references restored from backup
- Navigation test hydration race condition
- Web Vitals library import path corrected

### Known Limitations
- Android build: AGP classloader conflict requires clean environment (no Gradle daemon corruption)
- iOS Archive: requires Xcode GUI for signing/distribution
- App Store submissions: require manual developer account access

---

## [1.0.0] — 2026-05-05

### Added
- Real-time dog bark translation using AI
- User authentication with Supabase (email + OAuth)
- Premium subscription with RevenueCat (monthly/yearly)
- Paywall UI with 3-day free trial
- Cross-platform sync (iOS ↔ Android ↔ Web)
- Apple Watch companion app support
- Push notifications via FCM
- Translation history and phrase library
- Community phrase sharing

### Changed
- Web app migrated to Next.js 14 with App Router
- Sentry integration for production error tracking
- Performance optimizations for translation API

### Fixed
- SupabaseManager nil client crash (iOS)
- RevenueCat v5.x async/await migration (iOS)
- Build errors for iOS/Android production builds
- Web deployment pipeline with Vercel

### Security
- Environment-based API key storage
- Secure authentication flow with Supabase Auth
- RevenueCat receipt validation

---

## [0.9.0] — 2026-04-29 (Beta)

### Added
- Beta testing release for internal team
- Initial subscription flow
- Basic translation functionality

---

## Template for Future Releases

## [X.Y.Z] — YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Any bug fixes

### Security
- Security fixes
