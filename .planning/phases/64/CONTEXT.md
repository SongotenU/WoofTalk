# Phase 64: Documentation & Store Assets - Context

**Gathered:** 2026-05-05
**Status:** Ready for execution (significant assets exist)

<domain>
## Phase Boundary

This phase completes all documentation and creates store listing assets for WoofTalk across all platforms. Updates README.md with production information, finalizes API documentation, generates App Store and Play Store assets (screenshots, promo video, feature graphic), and completes privacy policy and terms of service. Most documentation already exists and needs only updates.

**Prerequisites:** Phase 63 (Release Management) can run in parallel.

</domain>

<decisions>

## Implementation Decisions

### Documentation Updates
- README.md: Minor updates for v1.0.0 production (badges, URLs, M010 milestone)
- API.md: New file with Supabase Edge Functions documentation
- Privacy Policy: Review and update if needed (currently dated March 2025)
- Terms of Service: Review and update if needed (currently dated March 2025)

### Store Assets
- iOS Screenshots: Use existing `AppStoreScreenshots/` directory, update if needed
- Android Screenshots: Create in `store-assets/android/` (currently empty)
- App Preview Video: Create 15-30 second video showing translation flow
- Play Store Feature Graphic: Create 1024x500 JPEG/PNG

### User Documentation
- Expand existing `USER_GUIDE.md` with 6+ help center articles
- Host on website: https://wooftalk.app/help
- Include FAQs and troubleshooting

</decisions>

<code_context>

## Existing Code Insights

### Documentation Assets (Exist)
- `README.md` — Comprehensive, 200+ lines, covers all platforms
- `ReleaseNotes.md` — v1.0.0 and v1.1.0 release notes
- `PrivacyPolicy.md` — Complete, dated March 2025
- `TermsOfService.md` — Complete, dated March 2025
- `USER_GUIDE.md` — Complete user guide
- `ARCHITECTURE.mmd` — Architecture diagram (Mermaid)
- `v1.0-REQUIREMENTS.md` — v1.0 requirements (archive)
- `v2.0-REQUIREMENTS.md` — v2.0 requirements (archive)

### Store Assets (Partial)
- `AppStoreScreenshots/` — Existing iOS screenshots
- `store-assets/ios/` — Empty, ready for new assets
- `store-assets/android/` — Empty, ready for new assets
- `AppStoreMetadata.json` — iOS metadata

### API Documentation (Needs Creation)
- Supabase Edge Functions in `supabase/functions/`:
  - `/translate` — translation with entitlement check
  - `/phrases/search` — full-text phrase search
  - `/leaderboard` — computed leaderboard
  - `/activity/batch` — batch activity creation
- Need to create `API.md` with request/response examples

### Web Assets (PWA)
- `web/public/` — Check for manifest.json, favicon, OG images
- PWA configured via Next.js

</code_context>

<specifics>

## Specific Ideas

### Immediate Actions (Can Start Now)
1. **Update README.md (T1)**
   - Verify badges point to correct URLs (App Store, Play Store, Web)
   - Add M010 (Ship to Production) to milestones table
   - Update M009 status to reflect shipping date
   - Minor tweaks only, no rewrite needed

2. **Create API.md (T2)**
   - Document all Supabase Edge Functions
   - Include request/response examples
   - Document authentication requirements (JWT)
   - Document rate limiting (100 req/min per user)

3. **Review Legal Docs (T10-T11)**
   - Read `PrivacyPolicy.md` and `TermsOfService.md`
   - Verify compliance with GDPR, CCPA
   - Update dates to 2026 if needed
   - Ensure published at https://wooftalk.app/privacy and /terms

4. **Generate Screenshots (T4, T7)**
   - iOS: Use Simulator for 6.7", 6.5", 5.5" displays
   - Android: Use Emulator for phone and tablet
   - Capture: translation screen, voice input, community phrases, subscription paywall, settings
   - Ensure high-quality (PNG for iOS, JPEG/PNG for Android)

5. **Create App Preview Video (T5)**
   - Record 15-30 second video
   - Show translation flow, premium features
   - Export in MOV format (iOS), upload to YouTube (Android)
   - Use QuickTime or screen recording tool

6. **Create Play Store Feature Graphic (T8)**
   - Design 1024x500 JPEG/PNG
   - Include app logo, tagline, key features
   - Use vibrant colors, readable text
   - Can use Canva or Adobe Illustrator

</specifics>

<deferred>

## Deferred Ideas

- Interactive API documentation (Swagger/OpenAPI) — Phase 70+
- Video tutorials for user documentation — Phase 70+
- Localized store assets (non-English) — Phase 70+
- Press kit with high-res logos and images — Phase 70+

</deferred>
