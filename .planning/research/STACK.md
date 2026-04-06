# Production Deployment Stack: Supabase + Vercel

**Project:** WoofTalk
**Scope:** Production deployment for multi-platform app (iOS, Android, Web/Next.js, Watch, AR, VR)
**Researched:** 2026-04-04
**Backend:** Supabase (PostgreSQL, 8 tables, 30+ RLS policies, 6 Edge Functions) + Upstash Redis
**Frontend:** Next.js on Vercel

---

## Executive Summary

WoofTalk needs a production deployment pipeline that covers three distinct layers:

1. **Database layer** (Supabase PostgreSQL) — 8 tables with 30+ RLS policies requiring safe, versioned, reversible migrations
2. **Compute layer** (Supabase Edge Functions + Upstash Redis) — 6 Edge Functions deployed globally, Redis for caching/sessions
3. **Frontend layer** (Vercel/Next.js) — web client with automatic SSL, CDN, preview environments

The recommended approach: Supabase CLI in GitHub Actions for CI/CD, preview branch per Supabase project for staging, Vercel Git integration for web preview deployments, and Supabase project secrets + Vercel environment variables for env management. SSL and CDN are handled automatically by Vercel. Monitoring uses Vercel Observability + Supabase logs + custom Sentry/RUM tracking.

---

## 1. CI/CD Pipeline

### GitHub Actions — Supabase

| Item | Tool | Version | Purpose |
|------|------|---------|---------|
| **supabase/setup-cli** | GitHub Action | v1 | Install Supabase CLI in CI |
| **supabase db push** | CLI command | 2.x+ | Apply migrations to remote (CI/CD release command) |
| **supabase db push --dry-run** | CLI command | 2.x+ | Verify migrations before applying |
| **supabase functions deploy** | CLI command | 2.x+ | Deploy Edge Functions to remote |
| **supabase config push** | CLI command | 2.x+ | Push supabase/config.toml to remote project |
| **supabase branches create** | CLI command | 2.x+ | Create preview branch (staging environment) |

**Required environment variables for CI:**
- `SUPABASE_ACCESS_TOKEN` — personal access token from supabase.com/account/tokens, skip `supabase login` in CI
- `SUPABASE_DB_PASSWORD` — database password (avoid interactive prompts)
- `SUPABASE_PROJECT_REF` — project reference ID

**CI/CD Workflow structure (recommended):**
```
.github/workflows/
├── supabase-ci.yml          # Run on PR → db push --dry-run + lint
├── supabase-deploy.yml      # Run on main merge → db push + functions deploy
└── vercel-preview.yml       # Auto via Vercel GitHub integration
```

**supabase-ci.yml (PR validation):**
```yaml
jobs:
  test-migrations:
    runs-on: ubuntu-latest
    steps:
      - uses: supabase/setup-cli@v1
      - run: supabase db push --dry-run
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
```

**supabase-deploy.yml (production release):**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: supabase/setup-cli@v1
      - run: supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
      - run: supabase functions deploy --import-map ./deno.json
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

### Vercel — Next.js

| Feature | Mechanism | Notes |
|---------|-----------|-------|
| **Preview deployments** | Automatic via Vercel GitHub connection | One preview per PR branch |
| **Production deploy** | Merge to `main` / deploy via `vercel deploy --prod` | |
| **Rolling releases** | Vercel Rolling Releases | Gradual rollout to reduce blast radius |
| **Instant rollback** | One-click to previous deployment | Recovery from breaking changes |
| **Deployment protection** | Vercel WAF, Bot Management, RBAC | Production env only |

---

## 2. Database Migration Strategy

### Supabase Migration Workflow

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `supabase migration new <name>` | Create new migration file in `supabase/migrations/` | Every schema change |
| `supabase db diff -f <name>` | Diff local vs remote, save as migration | After local prototyping changes |
| `supabase db reset` | Reset local DB to clean state, reapply all migrations | When local state drifts |
| `supabase migration squash` | Squash many migrations into one | Before major version release, when migration count > 20 |
| `supabase migration repair` | Fix remote migration history table | When migration state is corrupted |
| `supabase db push --dry-run` | Preview what migrations will be applied | In CI/CD before actual deploy |
| `supabase db push` | Apply all pending migrations to remote | Production release step |

### Migration File Naming

```
supabase/migrations/
├── 20260401000000_create_users.sql
├── 20260401000001_create_translation_requests.sql
├── 20260401000002_rls_policies.sql
├── 20260402000000_create_language_pairs.sql
├── ...
└── 20260404000000_ar_vr_spatial_models.sql     # M007
```

**Format:** `YYYYMMDDHHMMSS_descriptive_name.sql`

### RLS Policy Migration Best Practices

With 30+ RLS policies, follow these rules:

1. **Group policies by table** — one migration per table's RLS setup
2. **Idempotent policies** — use `DROP POLICY IF EXISTS` before `CREATE POLICY` so re-running is safe
3. **Test on preview branch first** — use `supabase branches create test-branch` to validate policies affect expected rows
4. **Never disable RLS** — if a migration requires it, use row-level bypass roles, not `ALTER TABLE ... DISABLE ROW LEVEL SECURITY`

```sql
-- Recommended pattern for RLS policies
CREATE POLICY "Users can read own data"
  ON translation_requests
  FOR SELECT
  USING (auth.uid() = user_id);
```

### Environment Promotion

| Environment | Supabase Config | Purpose |
|-------------|-----------------|---------|
| **Local** | `supabase start` (Docker) | Development, zero cost |
| **Preview/Staging** | `supabase branches create <name>` | Per-PR testing, can pause/unpause |
| **Production** | Main Supabase project (project ref) | Live traffic |

**Promotion flow:**
```
Local → Preview Branch (validate) → Main Project (supabase db push)
```

---

## 3. Environment Management

### Supabase — Project Secrets

Supabase Edge Functions access secrets via `Deno.env.get()`:

| Secret | Set Via | Used By |
|--------|---------|---------|
| `OPENAI_API_KEY` | Supabase Dashboard or `npx supabase secrets set` | AI translation edge functions |
| `SUPABASE_URL` | Auto-injected | All edge functions |
| `SUPABASE_ANON_KEY` | Auto-injected | All edge functions (client ops via RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | Manual (never commit) | Admin operations only |
| `UPSTASH_REDIS_REST_URL` | Supabase Secrets | Redis caching in edge functions |
| `UPSTASH_REDIS_REST_TOKEN` | Supabase Secrets | Redis auth in edge functions |

Set secrets in CI:
```bash
npx supabase secrets set OPENAI_API_KEY=sk-... UPSTASH_REDIS_REST_TOKEN=...
```

**Never commit secrets** to migration files or edge function code.

### Vercel — Environment Variables

| Variable | Scope | Value | Notes |
|----------|-------|-------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | All envs | `https://<ref>.supabase.co` | Prefixed for client access |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | All envs | `eyJ...` | Prefixed for client access |
| `SUPABASE_SERVICE_ROLE_KEY` | Preview + Production only | Service role key | Server-side only |
| `UPSTASH_REDIS_REST_URL` | All envs | `https://...upstash.io` | |
| `UPSTASH_REDIS_REST_TOKEN` | All envs | Auth token | |
| `OPENAI_API_KEY` | Production only | OpenAI key | Serverless functions |
| `SENTRY_DSN` | All envs | Sentry DSN | Error monitoring |

**Set via Vercel CLI:**
```bash
vercel env add NEXT_PUBLIC_SUPABASE_URL --environment=preview,production
vercel env add SUPABASE_SERVICE_ROLE_KEY --environment=production
```

---

## 4. Edge Function Deployment

### Supabase Edge Functions Overview

WoofTalk currently has 6 Edge Functions (likely): translation, language detection, phrase management, audio processing, user profile, and AR/VR data.

### Deployment Process

```bash
# Deploy all functions
supabase functions deploy

# Deploy single function
supabase functions deploy translate-dog-sounds

# Deploy with specific import map
supabase functions deploy --import-map ./deno.json
```

### Edge Function Architecture

| Concern | Recommendation | Why |
|---------|---------------|-----|
| **Runtime** | Deno (required by Supabase) | Built-in, no Node.js runtime |
| **Cold starts** | Design as short-lived, idempotent operations | Edge functions can cold start; avoid stateful patterns |
| **Long-running tasks** | Move to background workers | Edge functions are not for batch processing |
| **Database connections** | Use connection pooling | Treat Postgres as remote; use `pg` with pooling or Supabase client |
| **External API calls** | Set timeouts, add retry logic | OpenAI and other APIs can timeout |
| **Logging** | Use `console.log` + Supabase log viewer | Functions stream logs to Supabase dashboard |
| **Imports** | Use import maps (`deno.json`) | Avoid bundler issues; Supabase Edge Runtime uses Deno |

### Edge Function Deno Configuration

```json
{
  "imports": {
    "@supabase/supabase-js": "https://esm.sh/@supabase/supabase-js@2",
    "openai": "https://esm.sh/openai@4",
  }
}
```

### Edge Function CI/CD

- Include `supabase/functions/` in Git
- Deploy via `supabase functions deploy` in `supabase-deploy.yml`
- Validate imports work with `deno check` or `supabase functions serve` locally
- Test with `supabase functions serve` before deploying (local runtime similar to production)

---

## 5. SSL/CDN

### SSL — Handled Automatically

| Layer | SSL Provider | Config Needed |
|-------|-------------|---------------|
| **Vercel (Next.js)** | Let's Encrypt via Vercel | None — automatic on `*.vercel.app` and custom domains |
| **Supabase** | Built-in | None — all Supabase projects have HTTPS |
| **Upstash Redis** | Built-in | None — HTTPS for REST API |

**Custom domain (if applicable):**
- Add custom domain in Vercel dashboard
- Vercel provisions SSL automatically
- Update DNS CNAME to `cname.vercel-dns.com`

### CDN — Vercel Delivery Network

| Feature | Default | Override |
|---------|---------|----------|
| **Static assets** | Cached globally at edge | `Cache-Control` headers in Next.js config |
| **ISR pages** | Stale-while-revalidate | `revalidate` in `getStaticProps` |
| **API routes** | Not cached by default | `res.setHeader('Cache-Control', ...)` |
| **Edge Middleware** | Executed closest to user | Vercel Edge Network regions |

**Next.js recommended caching:**
```js
// next.config.js
const nextConfig = {
  images: {
    remotePatterns: [{ hostname: '<ref>.supabase.co' }],
  },
  // Supabase Storage images cached for 1 day
}
```

---

## 6. Monitoring Hooks

### Vercel Observability

| Feature | What It Monitors | Setup |
|---------|-----------------|-------|
| **Vercel Speed Insights** | Core Web Vitals, page load | Enable in Vercel dashboard + add script |
| **Vercel Logs** | Runtime logs from serverless functions | Automatic, viewable in Vercel dashboard |
| **Vercel Errors** | Unhandled exceptions, 5xx errors | Automatic (Pro tier+) |
| **Vercel Analytics** | User journeys, page views | Enable in dashboard |

### Supabase Monitoring

| Feature | What It Monitors | Access |
|---------|-----------------|--------|
| **Database metrics** | CPU, memory, connections, query performance | Supabase Dashboard → Settings → Database |
| **Edge Function logs** | `console.log` output, errors | Supabase Dashboard → Edge Functions → Logs |
| **Realtime metrics** | Subscription counts, message throughput | Supabase Dashboard → Realtime |
| **Storage metrics** | Object count, bandwidth | Supabase Dashboard → Storage |
| **Audit logs** | Auth events, role changes (Pro+) | Supabase Dashboard → Settings → Audit |

### Recommended: Sentry Integration

| Component | Sentry Setup | Purpose |
|-----------|-------------|---------|
| **Next.js frontend** | `@sentry/nextjs` | Error tracking, performance monitoring |
| **iOS app** | `Sentry` pod | Crash reporting, ANR detection |
| **Android app** | `io.sentry:sentry-android-gradle-plugin` | Crash reporting, ANR detection |
| **AR/VR (VisionOS)** | `Sentry` via SPM | Spatial app crash reporting |
| **VR (Unity/C#)** | `Sentry Unity SDK` | Game crash reporting |
| **Supabase Edge Functions** | Custom Sentry SDK via Deno | Function error tracking |

**Sentry variables to add:**
- `SENTRY_DSN` (Vercel env + Supabase secrets)
- `SENTRY_AUTH_TOKEN` (CI/CD for source map upload)

---

## 7. Version Requirements

### Core Dependencies (Pin These Versions)

| Dependency | Min Version | Recommended | Why Pinned |
|------------|-------------|-------------|------------|
| **Supabase CLI** | 2.x | latest stable | Migration compatibility |
| **@supabase/supabase-js** | 2.39+ | 2.x latest | Deno compatibility for edge functions |
| **Next.js** | 14.0+ | 15.x (App Router) | Vercel optimization, AI SDK support |
| **Deno** | 2.0+ | latest stable (Edge Runtime) | Required by Supabase Edge Functions |
| **React** | 18.2+ | 19.x | Next.js 15 requirement |
| **Upstash Redis SDK** | 1.28+ | latest | Next.js and Edge Function compatibility |
| **Vercel CLI** | 34.x+ | latest | Environment management, deployment |
| **Node.js** | 18.x (LTS) | 20.x (LTS) | Vercel build runtime default |
| **Xcode** | 16.0+ | latest | iOS/visionOS/watchOS builds |
| **Android Studio** | Koala+ (2024.2.1+) | latest | Android builds |
| **Unity** | 2022.3 LTS | latest LTS | VR build stability |

### Supabase Extension Versions

| Extension | Purpose | Check Version |
|-----------|---------|---------------|
| **pgvector** | AI/vector embeddings | `SELECT * FROM pg_available_extensions WHERE name = 'vector'` |
| **pg_cron** | Scheduled jobs (if needed) | Available on Supabase |
| **pg_graphql** | GraphQL API (if used) | Supabase extension |
| **uuid-ossp** | UUID generation | Enabled by default |

---

## 8. What NOT to Add

| Item | Why Not |
|------|---------|
| **No self-hosted Supabase** | Managed Supabase handles backups, upgrades, scaling. Self-hosted adds operational burden for a side project |
| **No separate CDN provider (Cloudflare/Fastly)** | Vercel's Edge Network already provides global CDN. Adding another adds complexity without meaningful benefit |
| **No manual SSL certificate management** | Vercel and Supabase both handle SSL automatically. Let's encrypt is baked in |
| **No separate API Gateway** | Supabase Edge Functions + Vercel API Routes are sufficient. Adding Kong/AWS API Gateway is over-engineering |
| **No Kubernetes or container orchestration** | Serverless (Vercel + Supabase Edge) eliminates container management |
| **No external CI/CD (CircleCI, GitLab CI)** | GitHub Actions integrates natively with the repo. Vercel auto-deploys on push. Adding another system duplicates capability |
| **No pgBouncer proxy** | Supabase already provides connection pooling (Supavisor). Adding pgBouncer is redundant |
| **No separate logging infrastructure (ELK/Datadog)** | Vercel logs + Supabase logs + Sentry covers monitoring needs. Datadog adds cost without proportional value |
| **No traditional server (EC2/VPS)** | The serverless stack (Supabase + Vercel + Upstash) fully covers backend needs |
| **No WebSocket server** | Supabase Realtime subscription handles live data. Don't build custom WebSocket infrastructure |

---

## 9. Pre-Production Checklist

### Database
- [ ] All migrations versioned and tested with `supabase db push --dry-run`
- [ ] 30+ RLS policies reviewed for correctness (no overly permissive policies)
- [ ] `supabase migration squash` run if >20 migrations exist
- [ ] Database backups enabled (Supabase → Settings → Database → Backups)
- [ ] Point-in-time recovery enabled
- [ ] Preview branch created and tested (`supabase branches create production-test`)

### Edge Functions
- [ ] All 6 functions deployed and tested in preview environment
- [ ] Deno import maps (`deno.json`) are correct
- [ ] Cold start behavior measured for each function
- [ ] Retry logic added (especially for AI/LLM calls)
- [ ] Circuit breaker pattern implemented for AI translation
- [ ] Secrets set in Supabase Dashboard (`npx supabase secrets set`)

### Vercel / Next.js
- [ ] Environment variables configured for all environments (Preview + Production)
- [ ] `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` set
- [ ] Image remote patterns configured for Supabase Storage
- [ ] Preview deployments working (connect GitHub repo)
- [ ] Custom domain configured (if applicable) with automatic SSL

### CI/CD
- [ ] `SUPABASE_ACCESS_TOKEN` stored as GitHub secret
- [ ] `SUPABASE_DB_PASSWORD` stored as GitHub secret
- [ ] PR workflow: lint + type check + `supabase db push --dry-run`
- [ ] Merge-to-main workflow: `supabase db push` + `supabase functions deploy`
- [ ] Vercel GitHub integration connected for auto-deploy

### Monitoring
- [ ] Sentry configured with DSN for all environments
- [ ] Vercel Observability enabled (Speed Insights + Logs)
- [ ] Supabase Database metrics dashboard reviewed
- [ ] Edge Function log alerts configured

### Tech Debt to Address Before Production
These are not deployment blockers but should be prioritized:
- [ ] **LanguageDetectionManager O(n²) hot path** — Refactor to O(n) hash map lookup before production load
- [ ] **Missing retry/circuit breaker for AI** — Edge functions calling OpenAI need retry with exponential backoff
- [ ] **iOS audio_processing duplication** (~1600 lines) — Consolidate before it diverges further
- [ ] **TranslationCache disconnected from main flow** — Wire it up to actual translation pipeline
- [ ] **Memory leak investigation** — Profile iOS/AR (Vision Pro) and Android apps under sustained load

---

## 10. Installation

### Supabase CLI
```bash
# macOS
brew install supabase/tap/supabase

# Verify
supabase --version  # Should show 2.x+
```

### Node.js / Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Link project
vercel link --project wooftalk-web
```

### Next.js Dependencies (if not already installed)
```bash
# Core Supabase client
npm install @supabase/supabase-js

# Upstash Redis
npm install @upstash/redis

# Sentry (monitoring)
npm install @sentry/nextjs
```

### GitHub Actions
```yaml
# .github/workflows/supabase-deploy.yml (key steps)
- uses: supabase/setup-cli@v1
- run: supabase db push --dry-run  # PR validation
- run: supabase db push            # Production deployment
- run: supabase functions deploy   # Deploy Edge Functions
```

---

## Sources

- Supabase CLI Reference: https://supabase.com/docs/reference/cli/introduction (HIGH — official docs)
- Supabase Edge Functions: https://supabase.com/docs/guides/functions (HIGH — official docs)
- Supabase Platform: https://supabase.com/docs/guides/platform (HIGH — official docs)
- Vercel Documentation: https://vercel.com/docs (HIGH — official docs)
- Vercel Deployments & Environments: https://vercel.com/docs/deployments/environments (HIGH — official docs)
- Vercel CDN: https://vercel.com/docs/cdn (HIGH — official docs)
- Vercel Observability: https://vercel.com/docs/observability (HIGH — official docs)
- Vercel Rolling Releases: https://vercel.com/docs/rolling-releases (HIGH — official docs)
