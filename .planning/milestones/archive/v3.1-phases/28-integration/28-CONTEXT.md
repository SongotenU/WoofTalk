# Phase 28: Integration - Context

**Gathered:** 2026-03-31
**Status:** Ready for planning

<domain>
## Phase Boundary

This is the final integration phase for Milestone v3.1 (Web + Smartwatch). It validates end-to-end flows across all platforms (iOS, Android, Web, Watch), ensures performance targets are met, and configures deployment for web (Vercel/Netlify) and Play Store readiness for the watch app.

</domain>

<decisions>
## Implementation Decisions

### E2E Testing
- Web E2E: voice → translate → share → sync to mobile
- Watch E2E: voice → translate → sync to phone
- Cross-platform sync validation across all 4 platforms

### Performance Targets
- Web Core Web Vitals: LCP <2.5s, FID <100ms, CLS <0.1
- Translation latency: <3s end-to-end
- UI render: <16ms frame time

### Deployment
- Web: Vercel deployment with custom domain
- Watch: Play Store submission readiness
- All platforms share same Supabase backend

</decisions>

<code_context>
## Existing Code Insights

### Platforms to Integrate
- iOS: SwiftUI app (existing)
- Android: Kotlin + Jetpack Compose (Phase 19-24)
- Web: Next.js app (Phase 25-26)
- Watch: Wear OS (Phase 27)

### Shared Backend
- Supabase: PostgreSQL, auth, realtime, edge functions
- All platforms use same Supabase project

### Performance Monitoring
- Web: Core Web Vitals via Next.js analytics
- Mobile: Firebase Performance / custom metrics
- Watch: Android vitals

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond ROADMAP success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — stayed within phase scope.

</deferred>
