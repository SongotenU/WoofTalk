---
phase: 36
plan: 36
name: email-invites
type: execution
status: complete

---

# Phase 36: Email & Invites — Summary

## Tasks Completed

- Resend integration for org invites (`web/src/lib/email/invite.ts`)
- Invite acceptance page at `/invite/accept/:token` (validates token, handles expired/invalid)
- `POST /api/org/invite/route.ts` updated to send email via Resend on create
- 7-day expiry with invite_token tracking

## Files Changed
- `web/src/lib/email/invite.ts` (new, 64 lines)
- `web/src/app/invite/accept/page.tsx` (new, 120 lines)
- `web/src/app/api/org/invite/route.ts` (modified)
