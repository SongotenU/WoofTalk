---
status: all_fixed
findings_in_scope: 2
fixed: 2
skipped: 0
iteration: 1
---

# Fix Report - Phase 47: cicd-production-deployment

## Summary
Fixed 2/2 WARNING-level findings.

## Fixes Applied

### [FIXED] WR-01: Supabase migrations redundantly pass `--project-ref` CLI arg
**File**: `.github/workflows/supabase.yml`
**Fix**: Removed redundant `--project-ref $SUPABASE_PROJECT_ID` from both `supabase db push` and `supabase functions deploy` commands since `SUPABASE_PROJECT_ID` is already set as an environment variable.

### [FIXED] WR-02: RLS audit pattern matches comments
**File**: `.github/workflows/web-deploy.yml`
**Fix**: Improved RLS audit in `rls-audit` job to properly exclude comment lines (using `grep -v '^\s*--'`) and report specific files/lines with insecure policies (`WITH CHECK (true)` or `USING (true)`).

## Skipped Issues
None.

---
_Fixed: 2026-04-30_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
