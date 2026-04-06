# Phase 47: CI/CD + Production Deployment - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning
**Mode:** Auto-generated

<domain>
## Phase Boundary

- GitHub Actions pipeline for Supabase migrations and edge functions
- Vercel deployment for Next.js web app
- RLS audit in CI
- Environment management (.env.example)
- Live push deployment workflow

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices at Claude's discretion — infrastructure phase.

### Decisions
- Two workflows: supabase.yml (DB + edge functions) and web-deploy.yml (Next.js build + deploy + RLS audit)
- Environment variables via GitHub Secrets (SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_ID, VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID)
- .env.example checked in as reference template
- RLS audit: grep for overly permissive policies WITH CHECK (true) / USING (true)