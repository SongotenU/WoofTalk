# Phase 62: Production Monitoring — Execution Plan

**Milestone:** M010 Ship to Production
**Duration:** 3-5 days
**Prerequisites:** Phase 61 complete (End-to-End Testing)

---

## Goal

Set up comprehensive production monitoring, analytics, error tracking, and alerting systems for WoofTalk across all platforms. Ensure visibility into app health, user behavior, subscription metrics, and performance.

---

## Requirements

| ID | Requirement |
|----|-------------|
| MON-01 | Supabase monitoring dashboard configured (database, auth, API metrics) |
| MON-02 | RevenueCat analytics enabled (subscription metrics, revenue, churn) |
| MON-03 | Error tracking integrated (Sentry for Web, Crashlytics for iOS/Android) |
| MON-04 | Performance monitoring active (app launch, API latency, translation speed) |
| MON-05 | Uptime alerts configured (Supabase, RevenueCat, Web app) |

---

## Task Breakdown

### Wave 1: Supabase Monitoring (Days 1-2)

**T1. Supabase Dashboard Configuration**
- Enable Supabase Dashboard monitoring for production project
- Configure database metrics: connections, CPU, memory, disk usage
- Set up auth metrics: sign-ups, sign-ins, active users
- Configure API metrics: request count, latency, error rates
- Set up realtime metrics: connections, events per second
- **Effort:** 2 hours
- **Deliverable:** Supabase monitoring dashboard configured

**T2. Supabase Alerting Setup**
- Configure alerts for database CPU >80%
- Configure alerts for API error rate >5%
- Configure alerts for auth failure rate >10%
- Configure alerts for realtime connection limits
- Set up notification channel (email/Slack)
- **Effort:** 2 hours
- **Deliverable:** Supabase alerts active with notifications

**T3. Supabase Logging & Audit**
- Enable Postgres logs for slow queries (>500ms)
- Enable auth audit logs
- Set up log retention policy (30 days)
- Configure Edge Function logging
- **Effort:** 1 hour
- **Deliverable:** Logging configured with retention policy

### Wave 2: RevenueCat Analytics (Day 2) — Parallel with Wave 1

**T4. RevenueCat Dashboard Configuration**
- Enable RevenueCat dashboard for production
- Configure sandbox vs production data separation
- Set up key metrics: MRR, subscriptions, trials, churn rate
- Configure cohort analysis
- Enable webhook logging for debugging
- **Effort:** 2 hours
- **Deliverable:** RevenueCat analytics dashboard active

**T5. RevenueCat Alerts**
- Configure alerts for webhook failures
- Set up alerts for unusual cancellation rates
- Configure revenue drop alerts (>20% week-over-week)
- **Effort:** 1 hour
- **Deliverable:** RevenueCat alerts configured

### Wave 3: Error Tracking Integration (Days 3-4) — After Wave 1 & 2

**T6. Sentry Integration (Web)**
- Create Sentry project for WoofTalk Web
- Install @sentry/nextjs SDK
- Configure DSN in environment variables
- Set up error sampling rate (10% for production)
- Configure release tracking
- Set up source maps upload
- **Effort:** 2 hours
- **Deliverable:** Sentry integrated in Web app

**T7. Crashlytics Integration (iOS)**
- Add Firebase/Crashlytics via Swift Package Manager
- Configure GoogleService-Info.plist for production
- Enable Crashlytics in Xcode build phases
- Test crash reporting with test crash
- Configure crash-free user percentage tracking
- **Effort:** 3 hours
- **Deliverable:** Crashlytics integrated in iOS app

**T8. Crashlytics Integration (Android)**
- Add Firebase Crashlytics via Gradle
- Configure google-services.json for production
- Enable Crashlytics in Firebase console
- Test crash reporting
- **Effort:** 3 hours
- **Deliverable:** Crashlytics integrated in Android app

**T9. Error Monitoring Dashboard**
- Create centralized error monitoring document
- Document Sentry project URLs (Web)
- Document Crashlytics dashboard URLs (iOS, Android)
- Define severity levels and response procedures
- **Effort:** 1 hour
- **Deliverable:** Error monitoring runbook

### Wave 4: Performance Monitoring (Day 4) — Parallel with Wave 3

**T10. Performance Metrics Setup (All Platforms)**
- Define key performance indicators:
  - App launch time (<3s)
  - Translation API latency (<2s p95)
  - UI responsiveness (no frame drops)
  - Memory usage (no growth over time)
- Set up measurement points in code
- Configure analytics events for performance
- **Effort:** 3 hours
- **Deliverable:** Performance metrics defined and instrumented

**T11. Uptime Monitoring**
- Set up uptime monitoring for Web app (e.g., Pingdom, UptimeRobot)
- Configure health check endpoint on Web app
- Set up Supabase API uptime monitoring
- Configure RevenueCat API uptime check
- Set up alerts for downtime >5 minutes
- **Effort:** 2 hours
- **Deliverable:** Uptime monitoring active with alerts

### Wave 5: Documentation & Verification (Day 5)

**T12. Monitoring Documentation**
- Create monitoring runbook with all dashboard URLs
- Document alert thresholds and who receives notifications
- Create incident response procedure
- Document how to access logs and metrics
- **Effort:** 2 hours
- **Deliverable:** Monitoring runbook complete

**T13. Verification & Testing**
- Trigger test alerts to verify notification channels
- Verify error tracking captures test errors
- Check performance metrics are being recorded
- Confirm uptime monitors are active
- **Effort:** 2 hours
- **Deliverable:** All monitoring systems verified

---

## Dependency Graph

```
Wave 1:  T1 ─┬─ T2 ─┬─ T3
             │       │
             └───────┘ (T1, T2, T3 sequential)

Wave 2:  T4 ─┬─ T5
             └── (T4, T5 parallel, can run with Wave 1)

Wave 3:  T6 ─┬─ T7 ─┬─ T8 ─┬─ T9
             │       │       │
             └───────┴───────┘ (T6, T7, T8, T9 parallel after Wave 1 & 2)

Wave 4:  T10 ─┬─ T11
              └── (T10, T11 parallel after Wave 3)

Wave 5:  T12 ─┬─ T13
              └── (T12, T13 after Wave 4)
```

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Supabase monitoring dashboard configured | T1 — access dashboard, verify metrics visible |
| 2 | RevenueCat analytics enabled | T4 — access dashboard, verify subscription data |
| 3 | Error tracking integrated | T6, T7, T8 — trigger test errors, verify capture |
| 4 | Performance monitoring active | T10 — check metrics being recorded |
| 5 | Uptime alerts configured | T11, T13 — verify monitors active, test alerts |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Sentry/Crashlytics SDK increases app size | Low | Low | Monitor bundle size, use lazy loading |
| Alert fatigue from too many notifications | Medium | Medium | Start with critical alerts only, tune thresholds |
| RevenueCat webhook failures | Low | High | Set up dead letter queue, monitor webhook logs |
| Performance monitoring impacts app speed | Low | Medium | Use sampling, async reporting |
