# Code Review Report - Web Platform
**Date**: 2026-04-30
**Scope**: Web source files (web/)
**Depth**: standard

## Summary
The review of 30 web platform source files identified 5 critical security/bug issues, 4 high-severity bugs, 3 medium-severity quality issues, and 1 low-severity item. Critical issues include missing authentication on multiple API routes, a broken invite acceptance flow, and incorrect RevenueCat SDK usage. High-severity issues include unscoped real-time entitlement sync, incomplete subscription cancellation logic, and incorrect redirect behavior. Most critical issues must be addressed before shipping, as they pose security risks or functional failures.

## Findings

### [CRITICAL] Missing Authentication on /api/org/invite Route
**File**: `web/src/app/api/org/invite/route.ts:6-62`
**Severity**: CRITICAL
**Category**: Security
**Description**: The POST /api/org/invite route does not perform any authentication or authorization checks. Any unauthenticated user can send a request to create organization invites, as the route uses the Supabase service role key (bypassing RLS) without verifying the requesting user's identity.
**Evidence**:
```typescript
export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );
  try {
    const { email, role } = await req.json();
    // No auth check here
    const { data: userOrg, error: orgError } = await supabase
      .from('organization_members')
      .select('org_id, organizations(name)')
      .eq('status', 'active')
      .limit(1)
      .single();
```
**Recommendation**: Add authentication check using `requireAdmin` or similar middleware to ensure only authenticated, authorized users can create invites. Verify the requesting user's session before processing the request.

### [CRITICAL] Missing Authentication on DELETE /api/org/teams/[id] Route
**File**: `web/src/app/api/org/teams/[id]/route.ts:4-26`
**Severity**: CRITICAL
**Category**: Security
**Description**: The DELETE route for /api/org/teams/[id] does not perform any authentication or authorization checks. Any user can delete any team by providing the team ID, as the route uses the service role key without verifying the requester's identity.
**Evidence**:
```typescript
export async function DELETE(
  _req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );
  // No auth check here
  try {
    const { error } = await supabase.from('teams').delete().eq('id', id);
```
**Recommendation**: Add authentication and authorization checks to ensure only team admins or authorized users can delete teams. Use `requireAdmin` or similar middleware.

### [CRITICAL] Missing Authentication on POST /api/admin/errors Route
**File**: `web/src/app/api/admin/errors/route.ts:46-66`
**Severity**: CRITICAL
**Category**: Security
**Description**: The POST method of /api/admin/errors is designed for Edge Function use but does not validate that requests come from authorized sources. Any unauthenticated user can POST arbitrary error logs to the database, as there is no auth check or service role key verification in the request.
**Evidence**:
```typescript
export async function POST(req: NextRequest) {
  // Called by Edge Function collect-error (service role bypasses RLS)
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );
  // No auth check here
  try {
    const body = await req.json();
    const { data, error } = await supabase
      .from('error_logs')
      .insert(body)
      .select('id')
      .single();
```
**Recommendation**: Add authentication for Edge Function requests (e.g., verify a shared secret in the request header) or restrict the route to only accept requests from authorized Edge Functions.

### [CRITICAL] Invite Acceptance Not Linked to Accepting User
**File**: `web/src/app/invite/accept/page.tsx:48-57`
**Severity**: CRITICAL
**Category**: Bug
**Description**: When accepting an organization invite, the route updates the invite status to "active" but does not associate the invite with the currently authenticated user. The invite was created with a dummy user_id (`00000000-0000-0000-0000-000000000000`), and the acceptance flow does not update the user_id to the accepting user's ID. This leaves invites permanently linked to the dummy user, breaking organization membership.
**Evidence**:
```typescript
// Accept invite: update status to active
const { error: updateError } = await supabase
  .from("organization_members")
  .update({
    status: "active",
    joined_at: new Date().toISOString(),
    invite_token: null,
    invite_expires_at: null,
  })
  .eq("invite_token", token);
// No update to user_id here
```
**Recommendation**: Modify the invite acceptance flow to: (1) get the currently authenticated user's ID via `supabase.auth.getUser()`, (2) update the `user_id` field of the organization_members record to the accepting user's ID when accepting the invite.

### [CRITICAL] Incorrect RevenueCat Anonymous User ID Generation
**File**: `web/src/lib/revenuecat.ts:19`
**Severity**: CRITICAL
**Category**: Bug
**Description**: The code attempts to generate an anonymous RevenueCat user ID using `Purchases.generateRevenueCatAnonymousAppUserId()`, but this is not a static method on the `Purchases` class. In the RevenueCat JS SDK v7+, `generateRevenueCatAnonymousAppUserId` is a top-level exported function, not a method on `Purchases`. This will cause a runtime error during initialization, breaking RevenueCat functionality.
**Evidence**:
```typescript
const config: PurchasesConfig = {
  apiKey: API_KEY,
  appUserId: Purchases.generateRevenueCatAnonymousAppUserId(),
};
```
**Recommendation**: Import and use the top-level `generateRevenueCatAnonymousAppUserId` function instead:
```typescript
import { Purchases, generateRevenueCatAnonymousAppUserId } from '@revenuecat/purchases-js';
// ...
const config: PurchasesConfig = {
  apiKey: API_KEY,
  appUserId: generateRevenueCatAnonymousAppUserId(),
};
```

### [HIGH] Unscoped Real-Time Entitlement Sync
**File**: `web/src/hooks/useEntitlementSync.ts:19-41`
**Severity**: HIGH
**Category**: Bug
**Description**: The Supabase real-time subscription to `subscription_status` changes listens to all changes across the entire table, not just changes for the current user. This causes unnecessary entitlement refreshes for all users when any subscription status changes, and may lead to incorrect state updates if not properly scoped.
**Evidence**:
```typescript
const channel = supabase
  .channel('entitlement-sync')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'subscription_status' },
    async () => { /* refresh entitlements */ }
  )
  .subscribe();
```
**Recommendation**: Scope the real-time subscription to the current user's `user_id` by adding a filter, after retrieving the current user's ID:
```typescript
.on('postgres_changes', {
  event: '*',
  schema: 'public',
  table: 'subscription_status',
  filter: `user_id=eq.${currentUserId}`,
}, /* ... */)
```

### [HIGH] Subscription Cancellation Does Not Cancel with Payment Provider
**File**: `web/src/app/settings/cancel/page.tsx:49-59`
**Severity**: HIGH
**Category**: Bug
**Description**: The cancellation flow only updates the local `subscription_status` table but does not actually cancel the subscription with the payment provider (RevenueCat/Stripe). Users who cancel through this flow will still be charged, as the subscription remains active on the payment side.
**Evidence**:
```typescript
// Update subscription_status
const { error: statusError } = await supabase
  .from("subscription_status")
  .update({
    cancellation_reason: selectedReason,
    cancelled_at: new Date().toISOString(),
  })
  .eq("user_id", user.id);
// No call to RevenueCat/Stripe to cancel the subscription
```
**Recommendation**: Integrate with RevenueCat's API to cancel the subscription on the payment provider side. Use the RevenueCat JS SDK or a server-side route to initiate the cancellation.

### [HIGH] Sign-In Page Redirects Premium Users to Subscribe Page
**File**: `web/src/app/auth/signin/page.tsx:17-20`
**Severity**: HIGH
**Category**: Bug
**Description**: The sign-in page redirects users to `/subscribe` if `isReadyToAccessPaywall` is true (i.e., authenticated). This incorrectly redirects users who are already premium to the subscribe page instead of the translate page.
**Evidence**:
```typescript
// Redirect to subscribe page if already has access
if (isReadyToAccessPaywall) {
  router.push('/subscribe');
  return null;
}
```
**Recommendation**: Update the redirect logic to check if the user is premium first:
```typescript
if (isPremium) {
  router.push('/translate');
} else if (isReadyToAccessPaywall) {
  router.push('/subscribe');
}
```

### [HIGH] Entitlement Store Not Reset on Sign Out
**File**: `web/src/lib/entitlement-store.ts:54-56`
**Severity**: HIGH
**Category**: Bug
**Description**: The entitlement store's `reset` function is available but not called when the user signs out. This leaves `isPremium`, `isTrialActive`, and other state stale after sign out, leading to incorrect UI rendering.
**Evidence**:
```typescript
reset() { set(initialState); },
```
The sign-out flow in `settings/page.tsx` calls `signOut()` but does not reset the entitlement store.
**Recommendation**: Call `useEntitlementStore.getState().reset()` after signing out to clear the entitlement state.

### [MEDIUM] Duplicate High Contrast Check in ThemeInitializer
**File**: `web/src/components/ThemeInitializer.tsx:10-16`
**Severity**: MEDIUM
**Category**: Quality
**Description**: The ThemeInitializer component has two separate `useEffect` hooks that both check `localStorage.getItem('highContrast')` and update the `data-contrast` attribute, leading to duplicate code.
**Evidence**:
```typescript
useEffect(() => {
  const savedContrast = localStorage.getItem('highContrast');
  if (savedContrast === 'true') { /* set attribute */ }
}, []);
useEffect(() => {
  const savedContrast = localStorage.getItem('highContrast');
  if (savedContrast === 'true') { /* set attribute */ }
}, [theme]);
```
**Recommendation**: Combine the logic into a single function and call it from both effects to reduce duplication.

### [MEDIUM] No User Feedback on Admin Page Fetch Errors
**File**: `web/src/app/admin/ab/page.tsx:31-43`
**Severity**: MEDIUM
**Category**: Quality
**Description**: Admin pages catch fetch errors but only set the data to an empty array without providing user feedback. Users are not notified when data fails to load.
**Evidence**:
```typescript
const fetchExperiments = async () => {
  try {
    const res = await fetch('/api/admin/ab');
    if (!res.ok) throw new Error('Failed');
    const data = await res.json();
    setExperiments(data.experiments || []);
  } catch {
    setExperiments([]); // No error feedback to user
  }
};
```
**Recommendation**: Add error state to the component and display an error message to the user when data fetching fails.

### [MEDIUM] Unused isAuthenticated Variable in Settings Page
**File**: `web/src/app/settings/page.tsx:17`
**Severity**: MEDIUM
**Category**: Quality
**Description**: The settings page extracts `isAuthenticated` from the entitlement store but never uses it in the component, leading to unused code.
**Evidence**:
```typescript
const { isPremium, isTrialActive, isAuthenticated, setAuthenticated } = useEntitlementStore();
```
**Recommendation**: Remove unused variables from the destructuring to clean up code.

### [LOW] Compiled Service Worker Has Minor Code Smell
**File**: `web/public/sw.js:1`
**Severity**: LOW
**Category**: Quality
**Description**: The compiled service worker file has a variable shadowing issue in the module loader, but this is a build artifact from next-pwa and not source code. No action needed unless regenerating the service worker.
**Evidence**: N/A (compiled build artifact)
**Recommendation**: Ignore as this is a build artifact; follow best practices if adding custom service worker code.

## Findings by Severity
- CRITICAL: 5
- HIGH: 4
- MEDIUM: 3
- LOW: 1

## Findings by Category
- Bug: 6
- Security: 3
- Quality: 4
