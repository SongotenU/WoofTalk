# Code Review Report - Phase 48: observability-monitoring
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 48 implemented observability: uptime monitoring via GitHub Actions (5-minute cron), health checks for Supabase and web app, and Slack webhook alerting. The uptime-monitor.yml has issues: no timeout on curl calls (could hang indefinitely), no retry logic for transient failures, Slack alerts sent even on non-500 errors (e.g., 404 would alert), and the workflow runs every 5 minutes even on weekends/holidays with no quiet-period support. The ErrorReporter.swift mentioned in PLAN.md was NOT created.

## Findings

### [WARNING] WR-01: curl calls have no timeout — workflow can hang
**File**: `.github/workflows/uptime-monitor.yml:14,25`
**Severity**: WARNING
**Category**: Bug
**Description**: The `curl` commands for health checks have no `--max-time` or `--connect-timeout` set. If an endpoint is unresponsive (TCP handshake hangs), the curl command will wait indefinitely (up to GitHub's 6-hour job timeout). This blocks the workflow runner and delays subsequent checks.
**Recommendation**: Add timeout to all curl calls:
```bash
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 --connect-timeout 5 "${{ secrets.SUPABASE_URL }}/rest/v1/" ...)
```

### [WARNING] WR-02: Supabase health check alerts on any >=500, but 503 might be intentional
**File**: `.github/workflows/uptime-monitor.yml:15-19`
**Severity**: WARNING
**Category**: Quality
**Description**: The Supabase check alerts on any status >= 500. However, 503 (Service Unavailable) could be a planned maintenance or brief restart. The check should distinguish between transient and persistent failures, or at least add a retry before alerting.
**Recommendation**: Add a retry with short delay before alerting:
```bash
STATUS=$(curl ...)
if [ "$STATUS" -ge 500 ]; then
  sleep 10
  STATUS=$(curl ...)  # Retry once
  if [ "$STATUS" -ge 500 ]; then
    # Alert
  fi
fi
```

### [INFO] IN-01: ErrorReporter.swift not implemented (promised in PLAN.md)
**File**: `WoofTalk/ErrorReporter.swift` (missing)
**Severity**: INFO
**Category**: Quality
**Description**: The PLAN.md lists "ErrorReporter Client-Side Error Capture" as Plan 1, stating it should have `configure()`, `report()`, `addBreadcrumb()` methods and report to Sentry in production. The SUMMARY.md says "Documented error tracking integration hooks (Sentry-ready)" but the actual ErrorReporter.swift file was never created. This is a gap between plan and implementation.
**Recommendation**: Create ErrorReporter.swift or update PLAN.md/SUMMARY.md to reflect what was actually done.

### [INFO] IN-02: No alert deduplication — same outage triggers multiple Slack messages
**File**: `.github/workflows/uptime-monitor.yml:16-19,27-30`
**Severity**: INFO
**Category**: Quality
**Description**: If an endpoint is down for 30 minutes, the 5-minute cron will fire 6 Slack alerts for the same issue. There's no state tracking to avoid duplicate alerts.
**Recommendation**: Consider using a persistent store (e.g., Supabase table, GitHub Actions cache) to track alert state and only send alerts on state transitions (healthy→down, down→healthy).

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 2
