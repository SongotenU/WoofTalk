# Stack Research

**Domain:** M006 Enterprise — API Access, Admin Dashboard, Team/Org Management
**Researched:** 2026-04-02
**Confidence:** HIGH

## Recommended Stack

### API Gateway & Rate Limiting

| Technology | Purpose | Why Recommended |
|------------|---------|-----------------|
| Supabase Edge Functions (Deno) | API proxy + rate limiting | Already deployed, Deno has built-in rate limiting patterns, shares Supabase auth context |
| Redis (Upstash) | Distributed rate limiting cache | Serverless Redis, sub-ms latency, perfect for token bucket algorithm, no infra to manage |
| Cloudflare Workers (alternative) | Edge API gateway | If rate limiting needs to happen at CDN edge, but adds another platform |

**Decision: Deno Edge Functions + Upstash Redis** — stays within existing Supabase ecosystem, minimal new infrastructure.

### API Key Management

| Technology | Purpose | Notes |
|------------|---------|-------|
| PostgreSQL (existing) | API key storage with bcrypt hashing | Store hashes, not plaintext — same pattern as auth tokens |
| `@vercel/og` or SVG templates | API key QR code generation | Optional — for mobile-friendly key sharing |

### Admin Dashboard

| Technology | Purpose | Why Recommended |
|------------|---------|-----------------|
| Next.js App Router (existing web) | Admin UI host | Reuse existing Next.js web app with `/admin/*` routes |
| shadcn/ui (existing) | Admin components | Zero additional dependencies, matches existing web patterns |
| `@tanstack/react-table` | Data tables for moderation | Sorting, filtering, pagination for large datasets |
| Recharts | Usage analytics charts | Lightweight, works with Server Components via client wrappers |
| React Hook Form + Zod | Admin forms (user edit, key gen) | Validation, type-safety, integrates with existing web forms |

### Organization & RBAC

| Technology | Purpose | Notes |
|------------|---------|-------|
| PostgreSQL (existing) | Org/team tables | New tables: `organizations`, `organization_members`, `roles` |
| Supabase RLS (existing) | Authorization enforcement | Extend RLS policies to org context — `org_id` column on all scoped tables |
| JWT custom claims | Per-request org context | Avoid extra DB lookups for org membership |

### What NOT to Add

| Technology | Why Skip |
|------------|----------|
| Separate GraphQL layer | Supabase already provides auto-generated GraphQL; duplicate effort |
| Dedicated admin framework (Refine, AdminBro) | Heavy, doesn't match existing Next.js patterns, lock-in |
| External RBAC service (Permit.io, Oso) | Overkill for 4-role system; Supabase RLS is sufficient |
| Separate backend service | Supabase Edge Functions are adequate for API gateway needs |

## Integration Points

- **Existing Supabase project** — reuse auth, database, edge functions
- **Existing Next.js web app** — reuse app router, shadcn/ui, Supabase client
- **FCM push** — reuse for admin alerts (abuse reports, system issues)
