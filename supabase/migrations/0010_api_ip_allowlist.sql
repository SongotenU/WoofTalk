-- Migration 0010: API Key IP Allowlisting (API-09)
-- Empty array = no restriction (backward compatible with existing keys)
ALTER TABLE public.api_keys
    ADD COLUMN IF NOT EXISTS ip_allowlist text[] DEFAULT '{}';

COMMENT ON COLUMN public.api_keys.ip_allowlist IS
    'IP addresses allowed to use this key. Empty = any IP.';
