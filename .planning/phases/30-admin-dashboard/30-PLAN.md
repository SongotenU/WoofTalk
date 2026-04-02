# Phase 30: Admin Dashboard - Execution Plan

**Goal**: Platform admins can manage users, moderate content, view usage analytics, query audit logs, and execute bulk actions from a single Next.js dashboard.

**Depends on**: Phase 29 (org tables, role functions, api_key_usage table)

**Requirements**: ADMIN-01 through ADMIN-06 (6 total)

## Execution Strategy

**3 waves**: audit log table → dashboard layout + pages → hardening

### Wave 1: Audit Log Table + Admin Supabase Client
- Migration 0008: `admin_audit_log` table (tracks who did what, when)
- Admin Supabase client at `lib/supabase/server-admin.ts`
- Admin auth middleware at `middleware/admin-auth.ts`

### Wave 2: Admin Pages (Next.js App Router)
- Layout: admin sidebar + auth check (`/app/admin/layout.tsx`)
- Dashboard overview (`/app/admin/page.tsx`) — key metrics cards
- Users page (`/app/admin/users/page.tsx`) — search, filter, ban/suspend
- Moderation page (`/app/admin/moderation/page.tsx`) — review queue, approve/reject/takedown
- Analytics page (`/app/admin/analytics/page.tsx`) — translations/day, active users, API usage
- Audit page (`/app/admin/audit/page.tsx`) — filterable, paginated log
- Bulk actions component (`/app/admin/moderation/bulk-actions.tsx`)

### Wave 3: Integration + Verification
- Wire up is_admin() gate on all admin routes
- Verify RLS: non-admins cannot access admin routes
- Verify all 6 requirements
