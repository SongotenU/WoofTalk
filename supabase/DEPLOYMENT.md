# Supabase Deployment Guide

## Prerequisites
- Supabase CLI installed (`npm install -g supabase`)
- Supabase project created and URL available
- Upstash Redis provisioned (for rate limiting)

## Step 1: Set Environment Variables
```bash
supabase secrets set \
  SUPABASE_URL="https://your-project.supabase.co" \
  SUPABASE_SERVICE_ROLE_KEY="eyJ..." \
  UPSTASH_REDIS_REST_URL="https://xxx.upstash.io" \
  UPSTASH_REDIS_TOKEN="xxx"
```

## Step 2: Deploy Migrations
```bash
supabase db push
```

Migrations applied in order:
- 0001: Organization tables (organizations, org_members, teams, team_members)
- 0002: API key tables (api_keys, api_key_usage)
- 0003: API key validation function
- 0004: org_id columns on existing tables
- 0005: RLS policy migration (30+ policies)
- 0006: Role function migration
- 0007: Seed data (dev only)
- 0008: Admin audit log
- 0009: Integration helper functions
- 0010: API IP allowlist

## Step 3: Deploy Edge Functions
```bash
supabase functions deploy api-gateway
supabase functions deploy api-key-manage
```

## Step 4: Run E2E Tests
```bash
SUPABASE_FUNCTIONS_URL=https://xxx.functions.supabase.co/functions/v1 \
ADMIN_ACCESS_TOKEN=xxx \
bash e2e-enterprise-test.sh
```

## Step 5: Verify Consumer Clients
```bash
SUPABASE_FUNCTIONS_URL=https://xxx.functions.supabase.co/functions/v1 \
SUPABASE_ACCESS_TOKEN=xxx \
bash e2e-consumer-regression.sh
```

## Rollback
If migrations fail, run: `supabase db reset` (development only)
For production, restore from pg_dump backup before applying.
