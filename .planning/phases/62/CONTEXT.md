# Phase 62: Production Monitoring - Context

**Gathered:** 2026-05-05
**Status:** Ready for execution (partial infrastructure exists)

<domain>
## Phase Boundary

This phase sets up comprehensive production monitoring, analytics, error tracking, and alerting systems for WoofTalk across all platforms. Ensures visibility into app health, user behavior, subscription metrics, and performance. Some infrastructure already exists (Sentry-ready code, GitHub Actions uptime monitor).

**Prerequisites:** Phase 61 (E2E Testing) can run in parallel after Wave 1.

</domain>

<decisions>

## Implementation Decisions

### Monitoring Stack
- **Supabase Dashboard:** Database, auth, API, realtime metrics
- **RevenueCat Dashboard:** Subscription metrics, MRR, churn, cohort analysis
- **Sentry:** Error tracking for Web app
- **Firebase Crashlytics:** Crash reporting for iOS and Android
- **UptimeRobot/Pingdom:** External uptime monitoring for Web app and APIs

### Alert Configuration
- Critical alerts: Database CPU >80%, API error rate >5%, crash-free users <95%
- Warning alerts: Auth failure rate >10%, webhook failures, revenue drop >20%
- Notification channels: Email (primary), Slack (secondary if configured)

### Sampling Rates
- Error tracking: 10% for production (Sentry), 100% for crashes (Crashlytics)
- Performance monitoring: 5% sampling for non-critical metrics
- Analytics: 100% for subscription events, 10% for usage events

</decisions>

<code_context>

## Existing Code Insights

### Sentry Integration (Ready to Configure)
- `ios/WoofTalk/ErrorReporter.swift` — Sentry-ready error tracking code exists
- Needs: Sentry DSN in environment variables, `@sentry/nextjs` for Web

### GitHub Actions Uptime Monitor
- `.github/workflows/` — Uptime checks every 5 minutes
- Needs: External uptime service (UptimeRobot) for public visibility

### Supabase Monitoring
- Supabase project: `https://bzcyllgdetedwrifrgvc.supabase.co`
- Dashboard available at supabase.com/dashboard
- Needs: Enable monitoring, configure alerts

### RevenueCat Analytics
- RevenueCat project configured (iOS, Android, Web apps)
- Dashboard at app.revenuecat.com
- Needs: Verify sandbox vs production data separation, enable webhooks

### k6 Load Testing
- `scripts/load-tests/` — k6 scripts exist
- Can be used for performance baseline testing

</code_context>

<specifics>

## Specific Ideas

### Immediate Actions (Can Start Now)
1. **Supabase Dashboard (T1-T3)**
   - Enable monitoring for production project
   - Configure alerts for database CPU, API errors, auth failures
   - Set up Postgres logs for slow queries (>500ms)
   - Configure log retention (30 days)

2. **Sentry Web Integration (T6)**
   - Install `@sentry/nextjs` in `web/package.json`
   - Configure DSN in `web/.env.local`
   - Set up release tracking
   - Upload source maps for production builds

3. **Crashlytics iOS (T7)**
   - Add `Firebase/Crashlytics` via Swift Package Manager
   - Configure `GoogleService-Info.plist` for production
   - Enable in Xcode build phases
   - Test with intentional crash

4. **Crashlytics Android (T8)**
   - Add `com.google.firebase:firebase-crashlytics` to Gradle
   - Configure `google-services.json` for production
   - Enable in Firebase console

5. **Uptime Monitoring (T11)**
   - Sign up for UptimeRobot (free tier: 50 monitors)
   - Configure health check endpoint on Web app
   - Monitor: Web app, Supabase API, RevenueCat API
   - Set up alerts for downtime >5 minutes

</specifics>

<deferred>

## Deferred Ideas

- Custom metrics dashboard (Grafana/Looker Studio) — Phase 70+
- Real-time user session recording (Hotjar/FullStory) — Phase 70+
- Advanced APM (New Relic/Datadog) — Phase 70+
- Log aggregation (ELK stack) — Phase 70+

</deferred>
