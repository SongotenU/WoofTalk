# WoofTalk Production Monitoring

## Overview
Production monitoring setup for WoofTalk across iOS, Android, and Web platforms.

## Error Tracking

### Web (Sentry)
- **Status**: ✅ Configured
- **SDK**: `@sentry/nextjs`
- **Config**: `web/next.config.ts` and `web/src/instrumentation.ts`
- **Project**: `wooftalk-web` (Sentry org: `wooftalk`)
- **DSN**: Set via `SENTRY_DSN` environment variable

### iOS (Sentry)
- **Status**: ✅ Configured
- **SDK**: SentrySwift (via SPM)
- **Config**: `WoofTalk/ErrorReporting/SentryManager.swift`
- **Initialization**: `WoofTalkApp.swift` → `SentryManager.shared.initialize()`
- **DSN**: Set via `SENTRY_DSN` environment variable
- **Features**: Auto session tracking, stack traces, breadcrumbs

### Android (Firebase Crashlytics)
- **Status**: ✅ Configured
- **SDK**: `com.google.firebase:firebase-crashlytics`
- **Config**: `android/WoofTalk/app/build.gradle.kts`
- **Plugin**: `com.google.firebase.crashlytics`
- **DSN**: Automatic via `google-services.json`

## Performance Monitoring

### Firebase Performance (Android)
- **Status**: ✅ Configured
- **SDK**: `com.google.firebase:firebase-perf`
- **Plugin**: `com.google.firebase.firebase-perf`
- **Metrics**: App startup, network requests, translation latency

## Uptime Monitoring

### GitHub Actions Uptime Monitor
- **Status**: ✅ Configured
- **Workflow**: `.github/workflows/uptime-monitor.yml`
- **Schedule**: Every 5 minutes
- **Endpoints**:
  - Supabase REST API (`/rest/v1/`)
  - Web app (`WEB_APP_URL`)
  - RevenueCat API (optional)
- **Alerts**: Slack webhook (`SLACK_WEBHOOK_URL`)

## Supabase Monitoring

### Dashboard Configuration
1. **Database Metrics**: CPU, memory, connections, disk usage
2. **Auth Metrics**: Sign-ups, sign-ins, active users
3. **API Metrics**: Request count, latency, error rates
4. **Realtime Metrics**: Connections, events/second

### Alerting
- Database CPU >80%
- API error rate >5%
- Auth failure rate >10%
- Realtime connection limits
- Notification: Slack webhook

### Logging & Audit
- Postgres slow query logs (>500ms)
- Auth audit logs
- Log retention: 30 days

## RevenueCat Analytics

### Dashboard Configuration
1. **Subscription Metrics**: MRR, churn, conversion rates
2. **Revenue Tracking**: Daily/monthly revenue
3. **Cohort Analysis**: User retention
4. **Alerts**: Revenue drop >20%, webhook failures

## Performance Metrics

| Metric | Target | Current |
|--------|--------|---------|
| App launch time (iOS/Android) | <2s | TBD |
| Translation API latency (p95) | <500ms | TBD |
| Web page load time | <1.5s | TBD |
| Error rate (all platforms) | <1% | TBD |

## Alert Channels

- **Slack**: `#wooftalk-alerts` (via webhook)
- **Email**: On-call rotation (configured in Supabase/RevenueCat)
- **Sentry**: Error alerts → Slack

## Verification

Run verification after setup:
```bash
# Test Sentry iOS
# Add break point or force crash in debug, verify in Sentry dashboard

# Test Crashlytics Android
# Use `FirebaseCrashlytics.getInstance().crash()` in debug

# Test uptime monitor
git commit --allow-empty -m "Test uptime monitor" && git push

# Verify Supabase alerts
# Check Supabase dashboard → Monitoring → Alerts
```

## Next Steps
1. Add `SENTRY_DSN` to iOS/Android/Web environment configs
2. Configure Slack webhook URL in GitHub secrets
3. Set up Supabase alert notification channel
4. Enable RevenueCat webhook for subscription events
5. Run verification tests
