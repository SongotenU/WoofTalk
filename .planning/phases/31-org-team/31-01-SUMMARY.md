# Phase 31: Organization & Team Management — Summary

## What Was Built

### Admin/Org Pages (4 pages)
- `web/src/app/org/page.tsx` — Organization overview: create org, invite members, pending invites list
- `web/src/app/org/members/page.tsx` — Members table: role management (inline select), remove member
- `web/src/app/org/teams/page.tsx` — Teams: create/delete teams with member count
- `web/src/app/org/layout.tsx` — Sidebar layout with org nav

### Admin API Routes (6 routes)
- `/api/org/me/route.ts` — GET current user's org
- `/api/org/create/route.ts` — POST create organization (with slug uniqueness check)
- `/api/org/invite/route.ts` — POST invite by email (7-day expiry, invite token)
- `/api/org/members/route.ts` — GET list, PATCH role change, DELETE remove member
- `/api/org/teams/route.ts` — GET list, POST create team
- `/api/org/teams/[id]/route.ts` — DELETE team

## Requirements Delivered

| Req | Status | How |
|-----|--------|-----|
| ORG-01 | Done | Create org with name, slug, plan_type via POST /api/org/create |
| ORG-02 | Done | Invite by email with 7-day expiry and invite_token tracking |
| ORG-03 | Done | Role hierarchy: owner/admin/member/viewer enforced in DB + UI dropdown |
| ORG-04 | Done | Remove member (DELETE /api/org/members), transfer ownership via role dropdown |
| ORG-05 | Done | API keys scoped to org_id (from Phase 29), visible in admin dashboard |
| ORG-06 | Done | Teams table and team_members with create/delete and membership management |
