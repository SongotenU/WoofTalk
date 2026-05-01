---
status: all_fixed
findings_in_scope: 16
fixed: 16
skipped: 0
iteration: 1
---

# Code Fix Report - All Platforms

## Summary
Fixed 16/16 findings (all critical and warning issues from REVIEW-combined.md)

## Fixes Applied

### [FIXED] CR-01: Remove service role key from iOS ErrorTrackingService
**File**: `WoofTalk/Analytics/ErrorTrackingService.swift`
**Original Severity**: CRITICAL
**Commit**: a14994c
**Fix**: Replaced service role key usage with user JWT token from Supabase session (`SupabaseManager.shared.client?.auth.session?.accessToken`). If no user token is available, the error tracking is skipped.

### [FIXED] WR-02: Add auth check to org/invite/route.ts
**File**: `web/src/app/api/org/invite/route.ts`
**Original Severity**: WARNING
**Commit**: 892c446
**Fix**: Added `getAuthenticatedUser()` helper to verify the JWT token from the Authorization header. The route now checks that the user is authenticated and belongs to an active organization before allowing invite creation.

### [FIXED] WR-03: Add auth check to org/teams/[id]/route.ts
**File**: `web/src/app/api/org/teams/[id]/route.ts`
**Original Severity**: WARNING
**Commit**: f3482af
**Fix**: Added authentication check and authorization check to verify the user is an admin or owner of the organization that owns the team before allowing deletion.

### [FIXED] WR-04: Add auth check to admin/errors POST method
**File**: `web/src/app/api/admin/errors/route.ts`
**Original Severity**: WARNING
**Commit**: 0b087de
**Fix**: Added `requireAdmin()` auth check to the POST method (it was missing, though GET already had it). Now both GET and POST require admin authentication.

### [FIXED] CR-05: Enable RLS on ab_experiments table
**File**: `supabase/migrations/0017_enable_rls_ab_experiments.sql` (new migration)
**Original Severity**: CRITICAL
**Commit**: 56c8ed1
**Fix**: Created new migration 0017 to enable RLS on `ab_experiments` table with appropriate policies: admins can manage experiments, and all authenticated users can view active experiments.

### [FIXED] CR-06: Add auth check to ab-assign and fix race condition
**File**: `supabase/functions/ab-assign/index.ts`
**Original Severity**: CRITICAL
**Commit**: 26eb089
**Fix**: Added JWT authentication to verify the user before processing. Fixed race condition by using `upsert` with `onConflict: 'experiment_id,user_id'` to ensure idempotent assignment. Also made the variant assignment deterministic per user.

### [FIXED] CR-07: Add auth check to collect-error function
**File**: `supabase/functions/collect-error/index.ts`
**Original Severity**: CRITICAL
**Commit**: 002a4cf
**Fix**: Added JWT authentication to verify the user before accepting error reports. The `user_id` is now taken from the authenticated user rather than from the request body.

### [FIXED] CR-08: Add auth check to push-campaign-send function
**File**: `supabase/functions/push-campaign-send/index.ts`
**Original Severity**: CRITICAL
**Commit**: c90ca59
**Fix**: Added JWT authentication and admin role check to ensure only organization owners/admins can send push campaigns.

### [FIXED] CR-09: Add auth check to error-collector function
**File**: `supabase/functions/error-collector/index.ts`
**Original Severity**: CRITICAL
**Commit**: 7487139
**Fix**: Added JWT authentication to verify the user before accepting error reports. The `user_id` is now taken from the authenticated user.

### [FIXED] CR-10: Fix Core Data viewContext on background thread
**File**: `WoofTalk/TranslationFeedbackManager.swift`
**Original Severity**: CRITICAL
**Commit**: c93253a
**Fix**: Replaced `persistence.container.viewContext` (main thread only) with `persistence.container.newBackgroundContext()` in the `storeCorrection` method which runs on a background queue.

### [FIXED] CR-11: Remove Purchases.shared.cancel() crash from CancellationSurveyView
**File**: `WoofTalk/CancellationSurveyView.swift`
**Original Severity**: CRITICAL
**Commit**: bcc576a
**Fix**: Removed `Purchases.shared.cancel()` call which doesn't exist in RevenueCat's API and causes a crash. Added a "Manage Subscription in Settings" button to guide users to manage their subscription through iOS Settings.

### [FIXED] CR-12: Fix duplicate element IDs in WatchKit storyboard
**File**: `WoofTalk/WatchKitExtension/Interface.storyboard`
**Original Severity**: CRITICAL
**Commit**: 9e9e499
**Fix**: Renamed all duplicate element IDs in the storyboard to be unique across all scenes (Interface Controller, Translation View Controller, History Interface Controller).

### [FIXED] WR-13: Replace TODO() with real EntitlementManager implementation
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/ui/navigation/AppNavigation.kt`
**Original Severity**: WARNING
**Commit**: 8dac6ab
**Fix**: Replaced `TODO()` calls with proper implementation using Hilt's `EntryPointAccessors` to get `EntitlementManager` instance. Added `EntitlementManagerEntryPoint` interface for Hilt dependency injection.

### [FIXED] WR-14: Implement sendTokenToServer() in FirebaseMessagingService
**File**: `android/WoofTalk/app/src/main/java/com/wooftalk/push/FirebaseMessagingService.kt`
**Original Severity**: WARNING
**Commit**: df16c56
**Fix**: Implemented `sendTokenToServer()` to send the FCM token to Supabase backend. The token is stored in `push_tokens` table with proper authentication. If user is not logged in, the token is queued for later sending.

### [FIXED] WR-15: Link invite to accepting user in invite/accept
**File**: `web/src/app/invite/accept/page.tsx`
**Original Severity**: WARNING
**Commit**: a885c87
**Fix**: Modified the invite acceptance flow to update `user_id` to the accepting user's ID and set status to `active`. Added proper auth check to ensure only logged-in users can accept invites.

### [FIXED] WR-16: Fix generateRevenueCatAnonymousAppUserId usage in revenuecat.ts
**File**: `web/src/lib/revenuecat.ts`
**Original Severity**: WARNING
**Commit**: 993ff2c
**Fix**: Removed `generateRevenueCatAnonymousAppUserId()` call which is not needed. RevenueCat JS SDK automatically generates an anonymous ID on `configure()`. The user identification is handled via `identifyUser()` when the user logs in.

### [FIXED] WR-17: Fix churn calculation in mrr-calculator
**File**: `supabase/functions/mrr-calculator/index.ts`
**Original Severity**: WARNING
**Commit**: 652888a
**Fix**: Fixed the churn calculation to properly compare "active at end of last month" with "active this month". The calculation now correctly uses the latest snapshot before the start of this month vs the latest snapshot up to today.

### [FIXED] WR-18: Fix CHECK constraint in subscription_snapshots
**File**: `supabase/migrations/0018_fix_subscription_snapshots_check_constraint.sql` (new migration)
**Original Severity**: WARNING
**Commit**: 6b85629
**Fix**: Created new migration 0018 to fix the CHECK constraint on `subscription_snapshots.status` column: changed `'cancelled'` (British English) to `'canceled'` (American English) to match the code, and added missing `'paused'` status.

## Remaining Issues
None - all critical and warning issues have been fixed.

## Notes
- All fixes were committed atomically with `fix(all):` prefix
- The fixes were applied in the worktree at `/tmp/wooftalk-reviewfix` on branch `feature/33-security-hardening-reviewfix`
- To merge these fixes to the main branch, run: `git checkout feature/33-security-hardening && git merge feature/33-security-hardening-reviewfix`
