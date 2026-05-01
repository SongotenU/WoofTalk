# Admin/Analytics Feature Gaps

## Current State

### iOS App (WoofTalk/Analytics/)
- **AnalyticsViewController.swift**: Local dashboard showing translation count, quality score, avg latency, success rate. Uses `UserDefaults` storage (device-local only). Manual refresh, CSV/JSON export.
- **TranslationAnalyticsService.swift**: Orchestrator wiring: storage, event store, quality collector, usage tracker, performance monitor, aggregator, report generator.
- **AnalyticsAggregator.swift**: Aggregates quality, performance, usage data into dashboard summaries and reports.
- **QualityMetricsCollector.swift**: Records translation quality (confidence, accuracy, model version). Tracks High/Medium/Low/Very Low tiers.
- **PerformanceMonitor.swift**: Records latency per translation (success/failure, type, language direction). Computes p50/p95/p99.
- **UsageAnalyticsTracker.swift**: Tracks feature usage, language pair usage, session analytics. Local to device only.
- **AnalyticsReportGenerator.swift**: Generates JSON/CSV reports for daily/weekly/monthly/all periods.
- **TranslationAnalyticsModels.swift**: Data models for events, quality metrics, performance stats, usage stats, sessions, dashboard summary.
- **AnalyticsStorage.swift / AnalyticsEventStore.swift**: UserDefaults-backed storage, event logging.

### Web App (web/src/app/admin/)
- **/admin/page.tsx**: Dashboard with 7 metric cards (translations, org members, community phrases, API calls 24h, active subscribers, trial, premium). Quick action links.
- **/admin/analytics/page.tsx**: Time-series charts for translations/day, active users/day, API calls/day. Top API endpoints. Period selector (7d/30d/90d). Client-side fetching from `/api/admin/analytics`.
- **/api/admin/analytics/route.ts**: Queries Supabase `translations`, `api_key_usage`, `organization_members` tables. Computes daily breakdowns and top endpoints.
- **/admin/audit/page.tsx**: Audit log viewer with action filter, pagination. Queries `admin_audit_log` table.
- **/api/admin/audit/route.ts**: Returns audit log entries with filtering by action.
- **/admin/moderation/page.tsx**: Community phrase moderation queue with approve/reject/takedown actions, bulk operations, flag indicators.
- **/api/admin/moderation/***: API routes for phrase moderation (list, update, bulk).
- **/admin/users/page.tsx**: User management with role/status filters, suspend/reactivate/change role actions.
- **/api/admin/users/***: API routes for user listing and role management.
- **/admin/subscriptions/page.tsx**: RevenueCat subscriber list with search, status filter, pagination. Shows entitlement, trial end, cancel-at-period-end.
- **/api/admin/subscriptions/route.ts**: Proxies RevenueCat API for subscriber data.

### Infrastructure
- **supabase/functions/_shared/rate-limit.ts**: Upstash Redis-backed rate limiting for Supabase Edge Functions (`@upstash/ratelimit`). Fixed window, per-key limits.
- **WoofTalk/NotificationManager.swift**: Push notification support exists on iOS.
- **WoofTalk/EntitlementManager.swift + web/src/providers/EntitlementProvider.tsx**: Feature gating via RevenueCat entitlements (basic feature flag system).
- **WoofTalk/Performance/PerformanceAlertManager.swift**: iOS performance alerting (local).
- **WoofTalk/ErrorReporting/CrashReportingService.swift**: iOS crash reporting (local).

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact | Notes |
|---|---------|----------|--------|--------|-------|
| 1 | Error rate tracking and alerting dashboard | High | Medium | High | CrashReportingService exists (iOS only). No centralized error tracking in admin. No alerting. |
| 2 | Performance dashboards (latency, throughput) | High | Medium | High | PerformanceMonitor exists (iOS local). Web has no perf dashboard. No centralized view. |
| 3 | API usage monitoring and rate limiting dashboard | High | Low | High | Rate limiting exists (Upstash). `api_key_usage` table exists. No admin UI to view rate limit status, abuse patterns, or adjust limits. |
| 4 | Translation accuracy metrics and tracking | High | Low | High | iOS tracks quality tiers locally. No admin dashboard to view accuracy trends, per-model performance, or per-language-pair accuracy. |
| 5 | Revenue/MRR tracking and forecasting | High | Medium | High | RevenueCat subscriber list exists. No MRR calculation, no churn tracking, no forecasting, no revenue charts over time. |
| 6 | Content moderation queue | **Done** | — | — | Fully implemented in web admin (moderation page with approve/reject/bulk). |
| 7 | User segmentation (by breed, location, usage) | Medium | Medium | Medium | `organization_members` table exists. No segmentation UI or targeted actions. |
| 8 | Push notification campaign management | Medium | Medium | Medium | NotificationManager.swift exists. No admin UI for creating/scheduling campaigns. |
| 9 | Real-time dashboard with WebSocket updates | Medium | High | Medium | Supabase Realtime SDK available. Admin dashboard is polling-only (manual refresh). |
| 10 | Churn analysis and prediction | Medium | High | High | RevenueCat data available. No churn rate calculation, no prediction models, no cohort retention. |
| 11 | Cohort analysis (user retention by signup month) | Medium | Medium | High | User signup dates available. No cohort table or retention curve visualization. |
| 12 | A/B testing framework for features | Low | High | Medium | EntitlementManager provides basic feature gating. No A/B test assignment, no experiment UI, no results tracking. |
| 13 | Feature flag management system | Low | Medium | Medium | Entitlement-based gating exists. No UI to create/manage flags, no gradual rollout controls. |
| 14 | Fraud detection dashboard | Low | High | Medium | `api_key_usage` and `admin_audit_log` exist. No anomaly detection, no suspicious pattern alerts. |
| 15 | GDPR/CCPA data export tools and compliance dashboard | High | Medium | **Critical** | No data export endpoint, no compliance dashboard, no "right to be forgotten" tooling. Legal risk. |

## Recommendations

### 1. Add centralized error rate tracking + alerting (Priority #1)
The iOS `CrashReportingService` is local-only. Build a Supabase `error_logs` table + edge function to collect errors from all platforms (iOS, Android, Web, Edge Functions). Add an admin page showing error rates over time, error breakdown by platform/type, and configurable alert thresholds (email/Slack webhook). This directly impacts reliability visibility.

### 2. Build MRR/revenue dashboard with churn and cohort analysis (Priority #5 + #10 + #11)
Extend the existing RevenueCat integration. Store historical subscriber snapshots daily (new table `subscription_snapshots`). Calculate MRR, churn rate, retention cohorts, and signup-month cohort tables. Add charts to `/admin/analytics` or a new `/admin/revenue` page. This is critical for business health monitoring.

### 3. Add GDPR/CCPA compliance tools (Priority #15)
Legal requirement. Build a Supabase Edge Function for user data export (aggregate data from `organization_members`, `translations`, `community_phrases`, `api_key_usage`). Add a "Compliance" section in the admin panel with: data export button per user, account deletion ("right to be forgotten"), and audit trail of compliance actions. This is a must-have before any EU/CA launch.
