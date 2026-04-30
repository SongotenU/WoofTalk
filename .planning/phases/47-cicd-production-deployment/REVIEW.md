# Code Review Report - Phase 47: cicd-production-deployment
**Date**: 2026-04-30
**Depth**: standard

## Summary
Phase 47 implemented CI/CD pipelines: GitHub Actions for Supabase (migrations + edge functions) and Next.js web app (lint/test → RLS audit → Vercel deploy). The workflows are functional but have security and reliability concerns: no Supabase CLI version pinning, RLS audit uses `grep` which can produce false positives, Vercel deployment lacks error handling and idempotency checks, and .env.example contains placeholder secrets that could confuse developers.

## Findings

### [WARNING] WR-01: supabase.yml passes --project-ref as CLI arg and env var simultaneously
**File**: `.github/workflows/supabase.yml:10-11,22,33-36`
**Severity**: WARNING
**Category**: Bug
**Description**: The workflow sets `SUPABASE_PROJECT_ID` as an env var (line 11) AND passes `--project-ref $SUPABASE_PROJECT_ID` as a CLI argument (lines 22, 35). The Supabase CLI uses env vars (`SUPABASE_PROJECT_ID` or `--project-ref`), so this is redundant and could cause conflicts if they differ. More critically, the `supabase db push` command applies migrations without a `--dry-run` check or confirmation step.
**Recommendation**: Use only one method for project identification. Also add a preview/dry-run step before applying migrations.

### [WARNING] WR-02: RLS audit grep pattern too broad — false positives likely
**File**: `.github/workflows/web-deploy.yml:31-32`
**Severity**: WARNING
**Category**: Bug
**Description**: The RLS audit uses `grep -rl 'WITH CHECK (true)\|USING (true)'` which will match these strings ANYWHERE in migration files — including comments, SQL strings, and documentation. A comment like `-- Note: WITH CHECK (true) is insecure` would fail the audit. The pattern also doesn't account for formatted SQL (newlines between keywords).
**Recommendation**: Use a more precise pattern or a dedicated SQL parser. Example improvement:
```bash
# Check for actual policy definitions with open checks
if grep -Pz 'WITH\s+CHECK\s*\(\s*true\s*\)|USING\s*\(\s*true\s*\)' supabase/migrations/*.sql | grep -v '^\s*--'; then
  echo "Found insecure RLS policies"
  exit 1
fi
```

### [INFO] IN-01: Vercel deployment not idempotent — runs on every push to main
**File**: `.github/workflows/web-deploy.yml:39-53`
**Severity**: INFO
**Category**: Quality
**Description**: The Vercel deployment runs on every push to main that touches `web/`. If multiple commits are pushed rapidly, multiple deployments may queue. There's no check for whether the deployment is necessary (e.g., check if web/ files actually changed).
**Recommendation**: Add a diff check or use Vercel's built-in deduplication.

### [INFO] IN-02: .env.example has placeholder secrets that look real
**File**: `.env.example:6-7`
**Severity**: INFO
**Category**: Quality
**Description**: The placeholders `eyJ...` for `SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_ANON_KEY` look like real JWT tokens. Developers might accidentally commit a file with these values, thinking they're just placeholders. Use clearly fake values like `replace-with-your-service-role-key`.
**Recommendation**: Use obviously fake placeholders:
```
SUPABASE_SERVICE_ROLE_KEY=replace-with-your-service-role-key
SUPABASE_ANON_KEY=replace-with-your-anon-key
```

## Findings by Severity
- CRITICAL: 0
- WARNING: 2
- INFO: 2
