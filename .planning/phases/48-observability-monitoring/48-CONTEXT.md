# Phase 48: Observability + Monitoring - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated

<domain>
## Phase Boundary

Edge Function error tracking, client-side error capture across 6 platforms, uptime monitoring, alert routing, distributed tracing.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices at Claude's discretion — infrastructure phase.

### Observability Architecture
- Use Sentry for client-side and edge function error tracking (widest iOS/visionOS/watchOS support via sentry-cocoa)
- Distributed tracing via X-Request-Id header propagated from client → edge function → Supabase
- Client error capture: centralized ErrorReporter singleton called from catch blocks
- Uptime monitoring: GitHub Actions scheduled workflow pings production endpoints every 5 min
- Alert routing: GitHub → Slack webhook for edge function alerting, email for critical outages