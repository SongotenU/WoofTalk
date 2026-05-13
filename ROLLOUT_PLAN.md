# WoofTalk Staged Rollout Plan — v1.0.0

## Overview
Staged rollout strategy for WoofTalk v1.0.0 across iOS, Android, and Web platforms.

## iOS App Store Rollout

### Rollout Schedule
| Stage | Percentage | Duration | Date | Monitoring Check |
|-------|-------------|----------|------|------------------|
| 1 | 5% | 48 hours | 2026-05-06 | Crash-free <95% → halt |
| 2 | 20% | 48 hours | 2026-05-08 | Crash-free <95% → halt |
| 3 | 50% | 48 hours | 2026-05-10 | Crash-free <95% → halt |
| 4 | 100% | — | 2026-05-12 | Full release |

### Halt Criteria (Stop Rollout)
- Crash-free users <95% (Sentry/Crashlytics)
- App Store rating <3.0 in first 24h
- Critical bug reports >10 in 24h
- API error rate >5% (Supabase dashboard)

### Monitoring
- **Sentry**: Check errors/session ratio every 12h
- **App Store Connect**: Monitor reviews, crash reports
- **Supabase**: API latency, error rate

---

## Android Play Store Rollout

### Rollout Schedule
| Stage | Percentage | Duration | Date | Monitoring Check |
|-------|-------------|----------|------|------------------|
| 1 | 10% | 24 hours | 2026-05-06 | Crash-free <95% → halt |
| 2 | 25% | 24 hours | 2026-05-07 | Crash-free <95% → halt |
| 3 | 50% | 48 hours | 2026-05-08 | Crash-free <95% → halt |
| 4 | 100% | — | 2026-05-10 | Full release |

### Halt Criteria (Stop Rollout)
- Crash rate >1% (Firebase Crashlytics)
- ANR rate >0.5%
- Play Console warning flags
- Critical bug reports >10 in 24h

### Monitoring
- **Firebase Console**: Crashlytics, Performance
- **Play Console**: Pre-launch report, Vitals
- **Supabase**: API health

---

## Web Deployment Strategy

### Deployment Type
Blue-Green deployment via Vercel/Netlify

### Rollout Schedule
| Stage | Scope | Duration | Date |
|-------|--------|----------|------|
| 1 | Staging → Production (internal) | 1 hour | 2026-05-06 |
| 2 | Production (10% traffic via feature flag) | 24 hours | 2026-05-06 |
| 3 | Production (100% traffic) | — | 2026-05-07 |

### Feature Flag (if applicable)
```
NEXT_PUBLIC_ENABLE_NEW_TRANSLATION_UI=false
```

### Rollback Method
- Vercel: `git revert` + push → auto-redeploy
- Netlify: `git revert` + push → auto-redeploy
- Supabase: Rollback migration if DB changes

---

## Cross-Platform Rollout Timeline

```
2026-05-06: iOS 5%, Android 10%, Web Staging→10%
2026-05-07: Android 25%
2026-05-08: iOS 20%, Android 50%
2026-05-10: Android 100%, iOS 50%
2026-05-12: iOS 100%
```

## Emergency Contacts
- **On-call**: Team Lead (see team-contacts.md)
- **Escalation**: Stakeholder email list
- **Slack**: `#wooftalk-alerts`

## Success Metrics (7 days post-100%)
- Crash-free sessions >98%
- App Store rating >4.0
- Play Store rating >4.0
- API uptime >99.9%
