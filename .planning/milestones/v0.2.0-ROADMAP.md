# Project Roadmap

## Milestone M008: Production Hardening

**Goal:** Ship WoofTalk to production with reliable infrastructure, observability, and zero known tech debt.

### Phase 43: Memory Leak Elimination
Fix all NotificationCenter and Timer leaks, add proper deinit observers, verify memory stability under Instruments

### Phase 44: Structural Cleanup
Remove duplicate audio_processing directory, consolidate duplicate enums, replace print() with os_log, fix legacy references

### Phase 45: Performance Hot Paths
Connect TranslationCache, fix O(n^2) LanguageDetectionManager, optimize string ops, implement queue execution, async cache

### Phase 46: Resilience Infrastructure
Circuit breaker pattern, retry with exponential backoff, activate retry error handler, timeout on AI calls, failure threshold

### Phase 47: CI/CD + Production Deployment
GitHub Actions for Supabase, Edge Functions pipeline, Vercel deployment, RLS audit, environment management, live push

### Phase 48: Observability + Monitoring
Edge Function error tracking, client-side error capture across 6 platforms, uptime monitoring, alert routing, distributed tracing

### Phase 49: Scale Testing
Load test Edge Functions with k6, concurrent RLS verification, memory stability test, rate limit validation, cache hit rate test
