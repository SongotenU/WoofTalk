---
phase: 36
plan: 36
name: email-invites
type: execution
objective: Complete organization invitation flow with email delivery via Resend and invite acceptance page
status: complete
requires: phase-31 (invites in DB, invite_token column)
key: Resend integration, /invite/accept page, email delivery
---

# Phase 36 Plan 36: Email & Invites Summary

**One-liner:** Integrate Resend for org invite emails, create `/invite/accept/:token` acceptance page, and update invite API route to send email on creation.

## Tasks Completed

| Task | Description | Done |
|---|---|---|
| Wave 1: Email Setup | Add Resend integration, create invite email template | Yes |
| Wave 1: API Route | Modify `POST /api/org/invite` to send email via Resend | Yes |
| Wave 2: Accept Page | Create `/invite/accept/:token` page with token validation, org join, redirect | Yes |
| Wave 2: Error Handling | Handle expired/invalid tokens with clear error messages | Yes |

## Commit

```
2f1f695 Phase 36: email invites and invite acceptance page
```

## What Changed

### 1. `web/src/lib/email/invite.ts` — Email Template (new)

Resend email helper specifically for org invitations:
- Uses `@/lib/email/template` base layout
- Includes organization name, inviter email, invite token, expiry date (7 days)
- Accept link: `${FRONTEND_URL}/invite/accept/${token}`
- 64 lines with proper HTML structure and responsive design

### 2. `web/src/app/invite/accept/page.tsx` — Acceptance Page (new)

Server component that validates invite token and joins user to org:
- Extracts `token` from route params
- Queries `org_invites` table with `token`, checks `expires_at`, status
- If valid: inserts into `organization_members` (role=member), updates invite status to accepted
- Redirects to `/org` on success
- Shows error message for expired/invalid tokens (with "Go Home" link)
- 120 lines with loading states and error handling

### 3. `web/src/app/api/org/invite/route.ts` — Modified

Updated POST handler to send email when creating new invite:
- After inserting invite record to DB
- Calls `sendInviteEmail(invite.email, org.name, invite.token, invite.expires_at)`
- Handles email send failures gracefully (logs but still returns success for invite creation)

**Invite Flow:**
1. Admin POSTs to `/api/org/invite` with `{ email, org_id, role }`
2. Server generates `invite_token` (UUID), calculates `expires_at` (7 days)
3. Inserts into `org_invites` table
4. Sends email via Resend
5. Returns `{ success: true, invite: {...} }`

**Acceptance Flow:**
1. User clicks link from email → `/invite/accept/:token`
2. Page loads, queries DB for valid invite
3. If valid: adds `organization_members` row, marks invite accepted
4. Redirects to `/org` dashboard
5. If invalid/expired: shows error with reason

### 4. Database Schema (from Phase 31)

This phase depends on existing invite infrastructure:
- `org_invites` table: `id, org_id, email, invite_token, role, status, expires_at, created_at`
- `organization_members` table: `id, org_id, user_id, role, joined_at`

### 5. Environment Variables

- `RESEND_API_KEY` — Resend service key (added to `.env.example`)
- `FRONTEND_URL` — Used in invite email link

## Deviations from Plan

**None** — Plan called for email integration and invite acceptance page. Both delivered as specified.

## Known Stubs

**None** — Email flow is complete. The `sendInviteEmail` function uses Resend API. The acceptance page properly validates tokens and handles edge cases (expired, already used, invalid token).

## Files Changed

- `web/src/lib/email/invite.ts` (new, 64 lines)
- `web/src/app/invite/accept/page.tsx` (new, 120 lines)
- `web/src/app/api/org/invite/route.ts` (modified — added email send)
- `web/.env.example` (modified — added `RESEND_API_KEY`, `FRONTEND_URL`)
