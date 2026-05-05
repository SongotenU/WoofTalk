# Phase 63: Release Management - Context

**Gathered:** 2026-05-05
**Status:** Ready for execution (existing assets available)

<domain>
## Phase Boundary

This phase manages the release process for WoofTalk across all platforms (iOS, Android, Web). Sets version numbers, prepares release notes, defines staged rollout plan, documents rollback procedures, and prepares release communication. Significant assets already exist (ReleaseNotes.md, AppStoreMetadata.json, PrivacyPolicy.md, TermsOfService.md).

**Prerequisites:** Phase 62 (Production Monitoring) can run in parallel.

</domain>

<decisions>

## Implementation Decisions

### Version Strategy
- Semantic versioning: 1.0.0 (major.minor.patch)
- Build numbers: Increment by 1 for each build (iOS CFBundleVersion, Android versionCode)
- Web version: Store in `VERSION` file and `package.json`

### Staged Rollout
- iOS: 5% → 20% → 50% → 100% (over 7 days)
- Android: 10% → 25% → 50% → 100% (over 7 days)
- Web: Blue-green deployment (instant rollback via Vercel)

### Rollback Strategy
- iOS: Pause rollout in App Store Connect, submit fix version
- Android: Halt rollout in Play Console, submit fix version
- Web: Revert to previous Vercel deployment
- Database: Rollback migrations only if schema changed (not needed for v1.0.0)

### Communication
- Internal: Email/Slack announcement with release timeline
- Users: In-app release notes, email newsletter (if applicable)
- Stakeholders: Formal notification with success metrics to track

</decisions>

<code_context>

## Existing Code Insights

### Version Numbers (Current)
- **iOS:** Check `WoofTalk.xcodeproj` project settings (CFBundleShortVersionString, CFBundleVersion)
- **Android:** `android/WoofTalk/app/build.gradle` (versionName, versionCode)
- **Web:** `web/package.json` ("version" field)

### Release Assets (Exist)
- `ReleaseNotes.md` — v1.0.0 and v1.1.0 release notes
- `AppStoreMetadata.json` — iOS App Store metadata
- `PrivacyPolicy.md` — Privacy policy (dated March 2025, needs review)
- `TermsOfService.md` — Terms of service (dated March 2025, needs review)
- `USER_GUIDE.md` — User documentation

### App Store Listings
- iOS: App Store Connect project needed
- Android: Google Play Console project needed
- Web: Already deployed on Vercel (wooftalk.app)

### GitHub Repository
- Main branch: `main`
- Latest commit: `35fbcef` (chore: create work handoff for Phase 55 pause)
- Tags: None yet for v1.0.0

</code_context>

<specifics>

## Specific Ideas

### Immediate Actions (Can Start Now)
1. **Verify Version Numbers (T1-T3)**
   - Check iOS version in Xcode project
   - Check Android version in build.gradle
   - Check Web version in package.json
   - Update if needed to 1.0.0

2. **Adapt Release Notes (T4-T6)**
   - Use existing `ReleaseNotes.md` as template
   - Highlight v1.0.0 features: subscription, cross-platform sync, Watch app
   - Create iOS (4000 chars), Android (shorter), Web (CHANGELOG.md) versions
   - Localize for supported languages

3. **Define Rollout Plan (T7-T9)**
   - iOS: 5% → 20% → 50% → 100% over 7 days
   - Android: 10% → 25% → 50% → 100% over 7 days
   - Web: Blue-green deployment via Vercel
   - Define halt criteria (crash rate >1%, critical bugs)

4. **Document Rollback (T10-T13)**
   - iOS: Pause rollout in App Store Connect
   - Android: Halt rollout in Play Console
   - Web: Vercel instant rollback
   - Emergency contacts list

5. **Prepare Communication (T14-T16)**
   - Internal announcement template
   - User release notes message
   - Stakeholder notification

</specifics>

<deferred>

## Deferred Ideas

- Automated release pipeline (Fastlane) — Phase 70+
- A/B testing for release notes — Phase 70+
- Feature flags for gradual feature rollout — Phase 70+
- Release analytics dashboard — Phase 70+

</deferred>
