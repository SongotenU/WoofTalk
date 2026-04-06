# Phase 30: Admin Dashboard - Context

**Gathered:** 2026-04-02
**Status:** Ready for execution

<domain>
## Phase Boundary

Build a Next.js admin dashboard for platform admins to manage users, moderate content, view usage analytics, query audit logs, and execute bulk moderation actions.

Narrow scope: Admin dashboard reads from existing Supabase tables + new Phase 29 tables. No new database schema needed (Phase 29 covered tables). Admin routes use Next.js App Router with server components where possible. Auth restricted via Phase 29's `is_admin()` function.

</domain>

<decisions>
## Implementation Decisions

### Tech Stack
- Next.js App Router (existing web app) — admin routes under `/admin/*`
- Server Components for data fetching (Supabase js via service role)
- Client Components for interactive UI (sort, filter, pagination, bulk actions)
- Tailwind CSS + shadcn/ui (existing design system)
- TanStack Table for data tables (filterable, paginated, multi-select)
- No separate admin SPA — reuse existing web app infrastructure

### Auth & Authorization
- Admin routes protected by `is_admin()` check from Phase 29
- Server-side role check via `supabase.rpc('is_admin')` or `organization_members` lookup
- Redirect to `/` with error message if not authorized

### Pages
- `/admin` — Dashboard overview (key metrics, recent activity)
- `/admin/users` — User list with search, filter, pagination, role management, ban/suspend
- `/admin/moderation` — Content moderation queue (reports, approve/reject, takedown)
- `/admin/analytics` — Usage analytics (translations/day, active users, API usage)
- `/admin/audit` — Audit log (who did what, when)
- `/admin/bulk` — Bulk moderation actions (multi-select from moderation queue)

### Data Sources
- Users: `auth.users` (via service role admin API) + `organization_members` join
- Content: `community_phrases` (flagged/approved/rejected status)
- Analytics: `api_key_usage`, `translations`, `activity_events` aggregation
- Audit log: NEW `admin_audit_log` table for tracking admin actions

### Deferred
- Automated spam detection with ML trust scores (deferred)
- User profile detail page (list view sufficient for v4.0)
- Export to CSV feature
- Email notification for moderation actions

</decisions>

<specifics>
## Specific Ideas

User wants to keep scope tight — admin tools exist for platform safety, not as a full CMS. Six requirements: user list/search/filter, role management, moderation queue, audit log, analytics, bulk actions.

</specifics>
</content>