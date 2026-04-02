-- Migration 007: Seed Test Data (Development Only)
-- Run this locally to test org and API key flows. Skip in production.

-- ============================================================
-- Test Organization
-- ============================================================
-- Note: Replace the UUID below with an actual user ID from auth.users

-- INSERT INTO public.organizations (id, name, slug, plan_type, owner_id)
-- VALUES (gen_random_uuid(), 'Test Org', 'test-org', 'free', '<REPLACE_WITH_USER_ID>');

-- ============================================================
-- Test API Key (for manual curl testing)
-- Raw key: wt_live_test1234567890abcdef1234567890abcdef
-- Hash this with bcrypt(cost=10) and insert
-- ============================================================

-- Example (after bcrypt hashing):
-- INSERT INTO public.api_keys (
--   user_id, name, key_prefix, key_hash, scope, rate_limit, is_revoked
-- ) VALUES (
--   '<REPLACE_WITH_USER_ID>',
--   'test-key',
--   'wt_live_test12',
--   '$2a$10$<BCRYPT_HASH_HERE>',
--   'translate:full',
--   60,
--   false
-- );
