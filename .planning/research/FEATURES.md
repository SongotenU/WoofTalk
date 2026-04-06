# Feature Research: Monitoring, Alerting, Observability & Incident Response

**Domain:** Production monitoring/alerting for WoofTalk (multi-platform Supabase-backed app)
**Researched:** 2026-04-04
**Confidence:** MEDIUM (based on official docs for Vercel Observability, Supabase Log Drains, Sentry SDK capabilities, and Upstash dashboard)

---

## Table Stakes (Must Have)

These are baseline expectations for any production deployment. Missing these means you are flying blind when incidents occur.

### Core Observability

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Edge Function error tracking** | 6 Edge Functions are the backend API layer for all 6 clients | LOW | Supabase Log Drains -> Sentry (Sentry destination built into Log Drains). Pro/Team plan required. |
| **Client-side error capture (all platforms)** | iOS, Android, Web, Watch, AR, VR each have independent crash/Error surfaces | LOW for Web, LOW-MED for native | Sentry SDK exists for every platform: `@sentry/nextjs` (Web), `@sentry/react-native` (iOS+Android+Watch), `sentry-cocoa` (AR/visionOS + Watch), `sentry-java` (Android/Kotlin), `@sentry/unity` (VR/Quest). |
| **Database query monitoring** | PostgreSQL with 8 tables, 30+ RLS policies — slow queries or RLS denials silently break features | LOW | Supabase dashboard shows database metrics (CPU, connections, storage, query time). Log Drains expose Postgres logs on Pro plan. |
| **API latency monitoring** | Every translation request goes through Supabase Edge Functions — latency directly impacts UX | LOW | Vercel Observability tracks edge request duration and error rate at both team and project level out of the box. |
| **Redis health visibility** | Upstash Redis handles cross-platform sync — if it degrades, clients become stale | LOW | Upstash provides a managed dashboard per database with connection count, memory, command latency, and ops/s metrics. No custom infra needed. |
| **SLA/status page monitoring** | Supabase has had platform outages; users expect uptime transparency | LOW | Use Supabase status page (https://supabase.statuspage.io/) with RSS/Slack alerts. This is external monitoring of the platform, not your app. |
| **Build/deploy failure alerts** | Vercel builds and Edge Function deploys can fail silently (especially Edge Function TypeScript errors) | LOW | Vercel sends deploy notifications natively via email/Slack. Webhooks available. |
| **Error rate alerting** | Need to know when error rates spike, not just that errors exist | LOW | Sentry alert rules trigger on error rate thresholds. Can route to Slack, Discord, PagerDuty. |
| **Uptime/availability monitoring** | Confirm Edge Functions, Supabase API, and Vercel hosting are actually responding to real requests | MEDIUM | External synthetic monitoring (Pingdom, UptimeRobot, Vercel Speed Insights) pinging key endpoints every 1-5 min. Required because Supabase and Vercel only monitor their own platforms, not your app logic. |

### Incident Response

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Centralized error dashboard** | Errors from 6 clients, Edge Functions, and Redis need one place to triage | LOW | Sentry provides unified issue grouping, stack traces, and breadcrumbs across all platforms. Single source of truth. |
| **Alert routing to communication channel** | Side project — no PagerDuty on-call rotation | LOW | Slack or Discord webhook from Vercel deploys, Supabase status page, Sentry alerts, and external uptime monitor. |
| **Incident postmortem template** | When something breaks, capture what happened so it doesn't recur | LOW | Lightweight runbook: what broke, impact, root cause, fix, prevention. Markdown in `.planning/incidents/` is sufficient. |
| **RLS policy denial logging** | 30+ RLS policies — misconfigured policies silently deny access (data shows as empty, not error) | MEDIUM | Postgres logs via Supabase Log Drains show RLS deny events. Requires Pro plan. Alternative: add client-side logging when queries return 0 unexpected rows. |
| **Edge Function timeout monitoring** | Deno Edge Functions have 400s timeout — translation with ML models could time out under load | LOW | Vercel Observability tracks function duration. Supabase Dashboard shows Edge Function execution times. |

---

## Differentiator Features (Set You Apart)

These go beyond standard observability and provide competitive advantages for reliability at the side-project scale.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Distributed tracing across client->Edge Function->Database** | Full request lifecycle visibility: see if latency is in audio upload, bark detection, Edge Function processing, or DB write | MEDIUM | Sentry distributed tracing + Supabase OTLP Log Drain endpoint. Trace ID passed from client header through Edge Function to Postgres `SET LOCAL`. |
| **Client session replay** | Reproduce user-reported bugs by watching what they did | MEDIUM | Sentry Session Replay available for Web (`@sentry/nextjs`) and mobile (Cocoa SDK with replay). Not available for React Native SDK as of current. Watch/AR/VR platforms lack replay support. |
| **Real user monitoring (RUM) for Web** | See actual performance from real users, not synthetic tests | LOW | Vercel Observability provides Web Vitals (LCP, FID, CLS) and Insights at no additional cost. No SDK needed. |
| **Custom business metrics dashboard** | Track translations-per-minute, active platforms, language pair distribution, bark detection accuracy | MEDIUM | Supabase OTLP drain to Grafana, or Sentry Custom Metrics. Track as custom Sentry transactions or push to external metrics backend. |
| **Cross-platform client health matrix** | Single view showing which platforms are healthy vs degraded | MEDIUM | Aggregate Sentry release health by platform. Use Sentry release health API to query crash-free session rates per platform. |
| **Bark detection accuracy monitoring** | Track false positives (non-bark classified as bark) and false negatives (bark not detected) | MEDIUM | Add user feedback mechanism ("Was this translation correct?") + log accuracy metrics to separate Supabase table or Sentry custom metrics. |
| **Edge Function cold start monitoring** | Deno functions cold start on first invocation after idle | LOW | Vercel Observability breakdown by function shows cold vs warm start duration. |
| **Database connection pool monitoring** | Supabase uses PgBouncer — connection exhaustion kills all clients | LOW | Supabase dashboard shows connection pool (PgBouncer) stats. Alert when connections approach limit. |
| **Rate limit monitoring** | Supabase Edge Functions and API have rate limits; Upstash has request limits per plan | MEDIUM | Track 429 responses from Supabase. Log Upstash `maxclients` warnings. External synthetic monitoring at 90% of rate limit thresholds. |
| **Watch app-specific battery impact monitoring** | AR and Watch apps can kill battery quickly; users will uninstall | MEDIUM | Sentry mobile vitals include `app_start` and display freeze rates. Battery impact tracking requires custom instrumentation. |

---

## Anti-Features (Skip These)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Self-hosted monitoring stack** (Grafana + Prometheus + Loki on a VPS) | Side project —运维 overhead kills side projects. Supabase Pro Log Drains + Sentry free tier handles this. | Use managed services: Sentry (captures errors from all platforms), Vercel Observability (functions/edge), Supabase Dashboard (DB health). |
| **Real-time log streaming to custom Elasticsearch** | Overkill for 8 tables and 6 edge functions. Supabase Log Drains to Loki/Sentry is sufficient when you need log search. | Start with Sentry issue grouping. Add Supabase Log Drain -> Loki only when you need to search raw Postgres/Audit logs. |
| **PagerDuty or complex on-call rotation** | Side project with solo developer. PagerDuty adds complexity without benefit when there is no rotation. | Slack/Discord alerts via Sentry and Vercel webhooks. Page yourself (you get notified once, not in a rotation). |
| **APM with always-on profiling** (Datadog APM, New Relic) | Datadog APM per-host pricing, continuous profiling costs. Overkill for serverless Edge Functions. | Sentry Performance Monitoring provides transaction tracing + profiling without per-host pricing. Vercel Observability covers the rest. |
| **Synthetic monitoring of every API endpoint** | 6 Edge Functions * 6 platforms * multiple languages = hundreds of synthetic endpoints. Noise overwhelms signal. | Monitor the 2 most critical paths: (1) translate endpoint health, (2) Supabase API connectivity. Alert on these two. |
| **Custom metrics collection via Supabase tables** (INSERT every metric row) | Write-heavy metrics in PostgreSQL wastes storage, competes with real data, and requires manual cleanup. | Use Sentry Custom Metrics, Vercel Observability, or Upstash Redis for volatile counter storage (auto-expire with TTL). |
| **Log-level alerting** (alert on every WARN/ERROR log) | Log volume creates alert fatigue. Edge Functions with verbose logging will trigger constant noise. | Alert on error rate thresholds (Sentry alerts) and business SLO breaches, not individual log lines. |
| **In-app monitoring dashboard for users** | WoofTalk is a dog translation app, not a monitoring product. Users don't care about your infrastructure. | Keep monitoring internal. Show user-friendly error messages, not dashboard links. |
| **Distributed tracing on every single request** | Tracing every bark detection + translation adds overhead, especially on Watch/AR/VR with constrained battery. | Sample distributed traces at 10-25% rate. Always trace errors, sample healthy requests. |
| **Monitoring native AR/VR rendering performance** | Vision Pro and Quest have their own developer tools. Sentry cannot capture RealityKit/Unity GPU frame times meaningfully. | Use platform dev tools (Instruments for Vision Pro, Meta Quest Developer Hub for Quest) during development. Log user-reported lag only. |

---

## Complexity Notes

### Platform-Specific Monitoring Complexity

| Platform | Error Tracking | Performance Tracing | Session Replay | Crash Symbolication |
|----------|---------------|--------------------|----------------|--------------------|
| **Web (Next.js)** | LOW - `@sentry/nextjs` single SDK install | LOW - Auto-instrumented | LOW - Built into SDK | Automatic |
| **iOS (Swift)** | LOW - `sentry-cocoa` via SPM | LOW | LOW | Automatic via build script |
| **Android (Kotlin)** | LOW-MED - `sentry-android` Gradle plugin | LOW-MED | LOW | Automatic via Gradle plugin |
| **Watch (WatchOS)** | LOW - uses `sentry-cocoa` (same as iOS) | LOW | Not supported | Automatic |
| **AR (visionOS)** | LOW - `sentry-cocoa` (visionOS supported) | LOW | MEDIUM - needs explicit opt-in | Automatic via build script |
| **VR (Meta Quest/Unity)** | LOW-MED - `@sentry/unity` package | MEDIUM | Not available | Requires dSYM upload |

### Backend Monitoring Complexity

| Component | Monitoring Available | Alerting Available | Setup Effort |
|-----------|---------------------|-------------------|-------------|
| **Supabase Postgres** | Built-in dashboard (CPU, connections, storage, query time) | No native alerts (monitor externally or use Log Drains) | LOW — dashboard always on |
| **Supabase Edge Functions** | Supabase Dashboard (CPU, memory, exec time) + Vercel Observability | Vercel alert rules + Sentry Log Drain | LOW — enable Log Drains |
| **Supabase Auth** | Dashboard (active users, sign-ins) | No native alerts | LOW — dashboard always on |
| **Upstash Redis** | Managed dashboard (connections, memory, ops, latency) | No native alerts (Upstash has no webhook alerting) | LOW — dashboard always on |
| **Vercel hosting** | Observability (edge reqs, functions, external APIs, middleware) | Deploy notifications, external API tracking | LOW — built in |

### Plan-Dependent Features

| Feature | Plan Required | Note |
|---------|--------------|------|
| Supabase Log Drains (to Sentry/Loki/Datadog/OTLP/S3) | Pro, Team, or Enterprise | Free/Hobby plan does NOT include Log Drains. This is the single biggest blocker to proper monitoring. |
| Supabase database query metrics | Pro, Team, or Enterprise | Free plan has limited dashboard metrics. |
| Sentry free tier | Free | 5K errors/month, 1K session replays, 10K transactions. Sufficient for side-project MVP. |
| Vercel Observability | All plans | Free for all projects. Plus tier adds longer retention. |
| Upstash Redis monitoring dashboard | All plans (free tier included) | Dashboard available regardless of plan. |

---

## Dependencies on Existing Capabilities

### Must Exist First

1. **Sentry project and DSNs** -> All platforms need their Sentry DSN configured. Create one Sentry project with per-platform DSNs (or single project with environment tags).
2. **Supabase Pro plan** -> Log Drains require Pro. Without this, you get zero server-side visibility beyond the Supabase dashboard's basic metrics. This is the primary prerequisite.
3. **Structured logging in Edge Functions** -> Edge Functions must log with consistent JSON structure (timestamp, level, userId, platform, requestId) for Log Drain ingestion to be useful. If Edge Functions use `console.log` without structure, the drained logs are grep fodder, not queryable data.
4. **Request ID propagation** -> For distributed tracing, a unique request ID must flow: client -> Edge Function -> Postgres query tags. Without this, correlating client errors with backend issues requires manual timestamp matching.

### Nice to Have First

5. **Centralized config for Sentry DSNs** -> Each of 6 clients needs the DSN. Use Supabase Config or environment variable system so all clients pull the same DSN source.
6. **Error boundary in Next.js** -> Wrap Next.js app in Sentry error boundary to catch React rendering errors.
7. **Release tracking in Sentry** -> All platforms should report release versions to Sentry so you know which version introduced a regression. Requires CI/CD integration for all 6 platforms.

### Can Build in Parallel

8. External uptime monitoring (independent of everything else)
9. Slack/Discord alert webhooks (independent of Sentry setup)
10. Incident postmortem templates (independent of all tooling)
11. Supabase status page subscriptions (independent)

---

## Recommended Monitoring Stack

For a side project at this scale, the minimal viable monitoring stack:

```
┌─────────────────────────────────────────────────────────┐
│                    Error Tracking                       │
│                      Sentry (Free)                      │
│   [Web] [iOS] [Android] [Watch] [AR] [VR] [Edge Funcs] │
├─────────────────────────────────────────────────────────┤
│                 Infrastructure Monitoring               │
│  Supabase Dashboard (DB metrics) + Log Drains (errors) │
│  Upstash Dashboard (Redis metrics)                      │
│  Vercel Observability (functions, edge, middleware)     │
├─────────────────────────────────────────────────────────┤
│                   External Verification                 │
│           UptimeRobot/Pingdom (health checks)           │
│         Supabase Status Page (RSS -> Slack)            │
├─────────────────────────────────────────────────────────┤
│                 Alerting & Response                     │
│         Slack Webhook <- Sentry + Vercel + Uptime      │
│         Incident runbooks in .planning/incidents/      │
└─────────────────────────────────────────────────────────┘
```

**Total estimated setup time:** 2-4 hours for Sentry across all platforms + 1 hour for Log Drains + 1 hour for external monitoring.

**Monthly cost:** Sentry free tier ($0) + Supabase Pro plan ($25/mo required for Log Drains) + UptimeRobot free ($0) + Vercel Observability (included).

---

## Sources

- Vercel Observability documentation: https://vercel.com/docs/observability (HIGH confidence — official docs)
- Supabase Log Drains documentation: https://supabase.com/docs/guides/platform/log-drains (HIGH confidence — official docs, verified destinations include HTTP, Datadog, Loki, Sentry, S3, OTLP)
- Supabase Status Page: https://supabase.com/docs/reference/project-health/project-health-and-outages (HIGH confidence — official docs)
- Sentry Apple platforms (iOS, watchOS, macOS, visionOS): https://docs.sentry.io/platforms/apple/ (HIGH confidence — official docs, confirmed watchOS and visionOS support)
- Upstash Redis dashboard features: https://upstash.com/docs/redis/features/dashboard (MEDIUM confidence — verified via Upstash docs, monitoring available on all plans)
- Sentry platform SDKs catalog (MEDIUM confidence — SDK-specific pages verified for Cocoa and Next.js; Unity and React Native from established public knowledge, verify current compatibility before implementation)
