# Code Review Report - Phase 54: cross-platform-sync-admin
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 54 implemented cross-platform sync (iOS Watch Connectivity, Web real-time + focus polling) and admin dashboard (subscriptions page, user metrics). WatchSyncManager uses WCSession to sync entitlements to Watch. Web uses Supabase real-time subscription to subscription_status table + window focus polling. Admin route fetches RevenueCat subscribers via REST API. Critical issues found: admin/subscriptions/route.ts has NO authentication/authorization check (any unauthenticated user can fetch all subscriber data), Supabase real-time subscription listens to ALL subscription_status changes (not filtered by user), and useEntitlementSync doesn't unsubscribe from Supabase on unmount in all code paths.

## Findings

### [WARNING] WR-01: Admin subscriptions API has NO auth check — exposed to unauthenticated users
**File**: `web/src/app/api/admin/subscriptions/route.ts:6-62`
**Severity**: WARNING
**Category**: Security
**Description**: The GET handler fetches RevenueCat subscribers and returns them. There is NO check that the requesting user is an admin. Any unauthenticated or regular user can call `/api/admin/subscriptions` and get a list of ALL subscribers with emails, subscription status, and expiration dates. This is a data breach waiting to happen.
**Recommendation**: Add admin auth check at the start of the handler:
```typescript
export async function GET(req: NextRequest) {
  // Verify admin authentication
  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  // Check admin role (assuming user_profiles has a role column)
  const { data: profile } = await adminClient
    .from('user_profiles')
    .select('role')
    .eq('user_id', session.user.id)
    .single();
    
  if (profile?.role !== 'admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }
  
  // ... proceed with RC fetch
}
```

### [WARNING] WR-02: Supabase real-time subscription not filtered by user_id
**File**: `web/src/hooks/useEntitlementSync.ts:19-41`
**Severity**: WARNING
**Category**: Security
**Description**: The Supabase channel subscribes to ALL changes on `subscription_status` table (`event: '*'`, no filter). This means the web client receives real-time events for EVERY user's subscription changes, not just the current user's. While the client-side code only uses it to trigger a refresh (not displaying the data directly), it's still unnecessary data exposure and wastes bandwidth.
**Recommendation**: Filter the subscription to current user only:
```typescript
const channel = supabase
  .channel('entitlement-sync')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'subscription_status',
    filter: `user_id=eq.${userId}`  // Get current user ID from auth store
  }, async () => {
    // ...
  })
```

### [INFO] IN-01: WatchSyncManager doesn't verify session activation state
**File**: `WoofTalk/WatchSyncManager.swift:37-38`
**Severity**: INFO
**Category**: Quality
**Description**: `sendEntitlementContext` guards on `session` being non-nil and `isPaired`/`isWatchAppInstalled`, but doesn't check `session.activationState == .activated`. If the session is in `.inactive` or `.notActivated` state, the `updateApplicationContext` call will fail silently.
**Recommendation**: Add activation state check:
```swift
guard let session, 
      session.activationState == .activated,
      session.isPaired, 
      session.isWatchAppInstalled else { return }
```

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 1
