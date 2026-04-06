# Phase 48: Observability + Monitoring - Plan

## Plans

### Plan 1: ErrorReporter Client-Side Error Capture
**Type:** New client infrastructure
**Description:** Centralized ErrorReporter singleton with configure(), report(), addBreadcrumb() API. Reports to Sentry in production, os_log in debug.

### Plan 2: Uptime Monitoring via GitHub Actions
**Type:** Infrastructure
**Description:** Scheduled workflow (*/5 * * * *) that pings Supabase, web app, and edge function endpoints. Alerts via Slack webhook on failures.

### Plan 3: Alert Routing
**Type:** Infrastructure
**Description:** Slack webhook alerts for edge function and Supabase downtime. Email alerts for critical severity issues (future: PagerDuty integration).

## Success Criteria

1. ErrorReporter.swift exists with report(), configure(), addBreadcrumb() methods
2. uptime-monitor.yml workflow created with scheduled checks
3. Slack webhook alerting configured in uptime workflow
