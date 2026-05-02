# Phase 51 UAT Testing - Local Setup Guide

## Overview
Phase 51 (Subscription Backend) requires live Supabase deployment for UAT testing. This guide provides local Docker-based setup for testing when cloud deployment is not available.

## Prerequisites

### Required
- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Node.js 18+ with npm
- Git

### Environment Configuration
Create `.env.local` in `web/` directory:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=http://localhost:5432
NEXT_PUBLIC_SUPABASE_ANON_KEY=ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=postgres

# Database (for migrations)
PGHOST=localhost
PGPORT=5432
PGDATABASE=postgres
PGUSER=postgres
PGPASSWORD=postgres
```

## Local Setup with Docker

### Step 1: Start Docker Services

```bash
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/supabase
docker-compose -f docker-compose-dev.yml up -d
```

This starts:
- **PostgreSQL 15** (port 5432) - Main database with auth tables
- **Kong Gateway** (port 8000) - API gateway for edge functions
- **Inbucket** (port 9000) - Email testing service

### Step 2: Wait for Services

```bash
# Check database health
docker exec supabase_db pg_isready -U postgres

# Expected output: /var/run/postgresql:5432 - accepting connections
```

Wait 15-30 seconds for PostgreSQL to fully initialize.

### Step 3: Apply Migrations

```bash
# Apply all migrations (0013-0016)
./scripts/run-migrations.sh

# Or apply specific migration
./scripts/run-migrations.sh 13
```

Migrations include:
- `0013_subscription_status.sql` - subscription_status enum and tables
- `0014_subscription_enhancements.sql` - webhook handling and triggers
- `0015_error_logs.sql` - error logging tables
- `0016_subscription_snapshots.sql` - subscription history snapshots

### Step 4: Deploy Edge Functions

Edge functions need to be deployed to Supabase:

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to project
supabase link --project-ref <your-project-ref>

# Deploy functions
supabase functions deploy entitlement-check --project-ref <your-project-ref>
supabase functions deploy api-gateway --project-ref <your-project-ref>
```

For local development, functions can be tested via curl:

```bash
# Test entitlement check
curl -X POST http://localhost:8000/functions/v1/entitlement-check \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"feature": "premium-chat"}'
```

### Step 5: Start Web Application

```bash
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/web
npm install
npm run dev
```

Access at: http://localhost:3000

### Step 6: Configure RevenueCat Webhooks

For production testing, configure RevenueCat webhook:

1. Log in to RevenueCat dashboard
2. Navigate to Settings → Webhooks
3. Add webhook URL: `https://<your-domain>/entitlement-webhook`
4. Test webhook with sample event

For local testing, use ngrok:

```bash
ngrok http 3000
```

Webhook URL: `https://<ngrok-id>.ngrok.io/entitlement-webhook`

## UAT Test Cases

### Test 1: Subscription Purchase Flow
- Navigate to /subscribe
- Select a premium plan
- Complete purchase (mock/sandbox)
- Verify entitlement in app
- Check database subscription record

### Test 2: Entitlement Verification
- After purchase, verify user can access premium features
- Toggle feature gating on/off
- Test revoked access after cancellation

### Test 3: Webhook Processing
- Send test webhook from RevenueCat
- Verify webhook handler processes correctly
- Check subscription_status updates
- Verify snapshot created in subscription_snapshots

### Test 4: Admin Panel Access
- Log in as admin user
- Access /admin/subscriptions
- View all subscriptions
- Check status updates

### Test 5: Error Handling
- Test with invalid JWT
- Test expired subscription
- Test canceled subscription
- Verify error logging in error_logs table

## Database Queries for Verification

### Check Subscriptions
```sql
SELECT 
  id,
  user_id,
  status,
  stripe_subscription_id,
  current_period_end,
  cancel_at_period_end,
  created_at
FROM subscriptions
ORDER BY created_at DESC;
```

### Check Entitlement Logs
```sql
SELECT 
  id,
  user_id,
  feature_name,
  has_access,
  granted_at,
  revoked_at
FROM entitlement_logs
ORDER BY granted_at DESC;
```

### Check Webhook Processing
```sql
SELECT 
  id,
  event_type,
  processed,
  created_at
FROM webhook_events
WHERE processed = false
ORDER BY created_at DESC;
```

### Check Error Logs
```sql
SELECT 
  id,
  error_type,
  message,
  metadata,
  created_at
FROM error_logs
ORDER BY created_at DESC;
LIMIT 10;
```

## Troubleshooting

### Database Connection Failed
```bash
# Reset password
ALTER USER postgres WITH PASSWORD 'postgres';

# Restart database
docker-compose restart db
```

### Migrations Not Applying
```bash
# Check migration status
ls supabase/migrations/

# Clear and re-apply
docker-compose down -v
docker-compose up -d
sleep 10
./scripts/run-migrations.sh
```

### Edge Functions Not Deploying
```bash
# Check function status
supabase functions list

# Redeploy
supabase functions deploy <function-name> --no-verify-jwt
```

### Webhook Events Not Processing
```bash
# Check webhook_events table
SELECT * FROM webhook_events WHERE processed = false;

# Check logs
docker logs supabase_db
```

## Stopping Services

```bash
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/supabase
docker-compose -f docker-compose-dev.yml down

# Remove data completely
docker-compose -f docker-compose-dev.yml down -v
```

## Cleanup

```bash
# Remove all containers and volumes
docker-compose -f docker-compose-dev.yml down -v

# Remove unused volumes
docker volume prune

# Remove unused images
docker image prune -a
```

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [RevenueCat Integration Guide](https://docs.revenuecat.com/docs)
- [Next.js + Supabase Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-nextjs)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
