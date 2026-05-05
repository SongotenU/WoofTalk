# Changelog

All notable changes to WoofTalk Web will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
