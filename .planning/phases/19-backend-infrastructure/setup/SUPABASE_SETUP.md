# Supabase Setup Guide

**Phase:** 19 — Backend Infrastructure
**Date:** 2026-03-31

---

## 1. Create Supabase Project

### Production Project
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Select your organization
4. Project name: `wooftalk-prod`
5. Database password: Generate a strong password (save in password manager)
6. Region: Choose closest to your primary user base
7. Pricing plan: Start with Free tier (upgrade when needed)
8. Click "Create new project" (takes ~2 minutes)

### Staging Project
Repeat steps above with:
- Project name: `wooftalk-staging`
- Use same region as production
- Can use same database password or generate a new one

---

## 2. Environment Variables

Create `.env` in project root (add to `.gitignore`):

```bash
# Supabase Production
SUPABASE_PROD_URL=https://your-project-id.supabase.co
SUPABASE_PROD_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_PROD_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Supabase Staging
SUPABASE_STAGING_URL=https://your-staging-id.supabase.co
SUPABASE_STAGING_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_STAGING_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Firebase Cloud Messaging
FCM_SERVER_KEY=AAAA... (from Firebase Console)

# Supabase CLI (for migrations)
SUPABASE_ACCESS_TOKEN=your-personal-access-token
```

Get keys from Supabase Dashboard → Project Settings → API:
- **Project URL**: API URL
- **anon/public key**: Safe for client-side (restricted by RLS)
- **service_role key**: Server-only (bypasses RLS) — NEVER expose to clients

---

## 3. CORS Configuration

Supabase handles CORS automatically for the API. For Edge Functions:

1. Go to Dashboard → Edge Functions
2. CORS is enabled by default for `OPTIONS` preflight
3. For custom origins, add to function headers:
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
```

---

## 4. Organization & Team Setup

1. Go to https://supabase.com/dashboard/org/_/settings/general
2. Add team members with appropriate roles:
   - **Owner**: Full access
   - **Developer**: Can manage projects, run migrations
   - **Billing**: Can manage subscription
3. Set up SSO if using enterprise plan

---

## 5. Supabase CLI Setup

```bash
# Install CLI
brew install supabase/tap/supabase

# Login
supabase login

# Link project
supabase link --project-ref your-project-id

# Push migrations
supabase db push

# Test locally
supabase start
```

---

## 6. Migration Order

Run migrations in this order:
1. `001_initial_schema.sql` — Tables, indexes, FKs, seed data
2. `002_rls_policies.sql` — Row-level security
3. `003_functions_triggers.sql` — Database functions and triggers

```bash
# Via CLI (recommended)
supabase db push

# Or manually via SQL Editor in Dashboard
# Copy/paste each migration file in order
```

---

## 7. Verification Checklist

After setup, verify:
- [ ] Project is accessible at `https://<project-id>.supabase.co`
- [ ] All 8 tables exist in Table Editor
- [ ] RLS is enabled on all tables
- [ ] Auth providers are configured (email, Google, Apple)
- [ ] Environment variables are set correctly
- [ ] Migrations ran without errors
- [ ] Seed data is visible in tables
