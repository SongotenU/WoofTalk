# Phase 47: CI/CD + Production Deployment - Plan

## Plans

### Plan 1: GitHub Actions — Supabase Pipeline
**Type:** Infrastructure
**Description:** supabase.yml workflow: migrations deploy → edge functions deploy on push to supabase/ path. Uses supabase/setup-cli action.

### Plan 2: GitHub Actions — Web Deployment Pipeline
**Type:** Infrastructure
**Description:** web-deploy.yml workflow: npm ci + lint + test → RLS audit check → Vercel production deploy on push to web/ path on main.

### Plan 3: RLS Audit in CI
**Type:** Security gate
**Description:** RLS audit job checks for overly permissive WITH CHECK (true) / USING (true) patterns in migration SQL files.

### Plan 4: Environment Management
**Type:** Configuration
**Description:** .env.example template for Supabase + Vercel environment variables. Document required secrets in CI.

## Success Criteria

1. supabase.yml workflow file exists with migrations + edge functions jobs
2. web-deploy.yml workflow file exists with verify + rls-audit + deploy jobs
3. No unguarded RLS policies found in migrations (CI will reject)
4. .env.example documents all required variables
