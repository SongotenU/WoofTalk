# WoofTalk Rollback Procedure — v1.0.0

## Overview
Step-by-step procedures to rollback WoofTalk releases if critical issues are discovered.

---

## iOS App Store Rollback

### Method 1: Pause/Stop Rollout (App Store Connect)
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **WoofTalk** → **App Store** tab
3. Click **Activity** → Find v1.0.0 release
4. Click **Pause Rollout** (if <100%) or **Remove from Sale** (if critical)
5. Monitor crash reports for 24h after pausing

### Method 2: Release Previous Version
1. App Store Connect → **App Store** tab → **iOS App**
2. Select previous version (if available)
3. Click **Submit for Review** (expedited review for critical fixes)
4. Notify users via in-app message

### Method 3: App Store Rejection (if not yet 100%)
- Contact Apple Developer Support for expedited removal

---

## Android Play Store Rollout

### Pause Rollout
1. Log in to [Google Play Console](https://play.google.com/console)
2. Navigate to **WoofTalk** → **Release Management** → **Production**
3. Click **Pause Rollout** (stops at current percentage)
4. Monitor Firebase Crashlytics for 24h

### Revert to Previous Release
1. Play Console → **Release Management** → **Production**
2. Click **Create New Release**
3. Upload previous APK/AAB (from artifacts)
4. Set rollout to 100% of previous version
5. Submit (usually no review needed for revert)

### Emergency Unpublish
1. Play Console → **Store Presence** → **Pricing & Distribution**
2. Click **Unpublish App** (last resort, removes from store)

---

## Web Rollback

### Vercel (Primary)
```bash
# Option 1: Git revert
git revert <production-commit-hash>
git push origin main
# Vercel auto-deploys previous working version

# Option 2: Vercel Dashboard
# Go to Vercel project → Deployments → Select previous deployment → Promote to Production
```

### Netlify (Alternative)
```bash
# Option 1: Git revert
git revert <production-commit-hash>
git push origin main
# Netlify auto-deploys previous working version

# Option 2: Netlify Dashboard
# Go to Netlify project → Deploys → Select previous deploy → Publish deploy
```

### Supabase Database Rollback (if schema changes)
```bash
# Check Supabase migrations
supabase migration list

# Rollback to previous migration
supabase db reset --version <previous-migration-id>

# Or manually revert SQL changes via Supabase Dashboard
# → Project → SQL Editor → Run reversal script
```

---

## Supabase Backend Rollout

### Database Migration Rollback
1. Supabase Dashboard → **Project** → **SQL Editor**
2. Run reversal script for problematic migration
3. Verify data integrity

### API/Function Rollback
1. Supabase Dashboard → **Edge Functions** → Select function
2. Redeploy previous version from Git history
3. Verify function logs

---

## RevenueCat Rollback

### Entitlement/Rule Changes
1. RevenueCat Dashboard → **Projects** → **WoofTalk**
2. Navigate to **Entitlements** or **Offerings**
3. Revert to previous configuration
4. Verify webhook delivery

---

## Communication Plan (Post-Rollback)

### Internal Notification (within 1 hour)
```
Subject: [ACTION REQUIRED] WoofTalk v1.0.0 Rollback Initiated

Team,
We have initiated a rollback of WoofTalk v1.0.0 due to [issue description].

Rollback Scope:
- iOS: [paused/removed]
- Android: [paused/reverted]
- Web: [reverted to previous version]

Next Steps:
1. Fix identified in [Jira/GitHub issue #]
2. Testing in progress
3. Re-release expected by [date]

Monitoring: [link to Sentry/Crashlytics dashboards]
```

### User Notification (if widespread issue)
- In-app message (if app still functional)
- Email to active users (if critical)
- App Store/Play Store update note

---

## Verification Checklist (Post-Rollback)

- [ ] Previous version confirmed live on all platforms
- [ ] No new error reports from rolled-back version
- [ ] Monitoring dashboards show stable metrics
- [ ] Internal team notified
- [ ] Users notified (if applicable)
- [ ] Root cause documented
- [ ] Fix timeline established

---

## Prevention (Post-Mortem)

After rollback and fix:
1. Conduct post-mortem meeting
2. Document root cause and timeline
3. Update test cases to catch similar issues
4. Improve staging/QA process
5. Share learnings with team
