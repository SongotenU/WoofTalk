---
status: all_fixed
findings_in_scope: 3
fixed: 3
skipped: 0
iteration: 1
---

# Fix Report - Phase 54: cross-platform-sync-admin

## Summary
Fixed 3/3 WARNING-level findings. (Skipped 1 INFO-level finding per instructions.)

## Fixes Applied

### [FIXED] WR-01: Admin subscriptions API has NO auth check — exposed to unauthenticated users
**File**: `web/src/app/api/admin/subscriptions/route.ts`
**Fix**: Added admin authentication and authorization check at the start of the GET handler. Now verifies the JWT from `Authorization` header using `adminClient.auth.getUser()`, then checks admin role using existing `isAdminOrAdminStatus()` function from `@/lib/supabase/server-admin`. Returns 401 for unauthenticated and 403 for non-admin users.

### [FIXED] WR-02: Supabase real-time subscription listens to ALL subscription_status changes
**File**: `web/src/hooks/useEntitlementSync.ts`
**Fix**: Added `filter: user_id=eq.${userId}` to the Supabase real-time subscription so it only listens to the current user's subscription changes. Gets `userId` from the current session.

### [FIXED] WR-03: useEntitlementSync doesn't unsubscribe from Supabase on unmount in all code paths
**File**: `web/src/hooks/useEntitlementSync.ts`
**Fix**: Added `isMounted` flag to handle async session check properly. Now sets `isMounted = false` in cleanup function and checks it before setting up the channel. Also sets `channelRef.current = null` after removing channel.

## Skipped Issues

### [SKIPPED] IN-01: Admin subscriptions API returns full RevenueCat response
**Reason**: INFO-level finding, skipped per instructions (only fixing WARNING/CRITICAL).

---
_Fixed: 2026-04-30_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
