-- Migration 003: API Key Validation SQL Function
-- Provides validate_api_key(raw_key) for bcrypt-based API key lookups

CREATE OR REPLACE FUNCTION public.validate_api_key(raw_key text)
RETURNS TABLE (
    id uuid,
    user_id uuid,
    org_id uuid,
    name text,
    scope text,
    rate_limit int,
    key_hash text,
    is_revoked boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    prefix text;
BEGIN
    -- Validate format: must start with 'wt_live_'
    IF raw_key IS NULL OR length(raw_key) < 16 THEN
        RETURN;
    END IF;

    prefix := substring(raw_key from 1 for 16);

    RETURN QUERY
    SELECT
        ak.id,
        ak.user_id,
        ak.org_id,
        ak.name,
        ak.scope,
        ak.rate_limit,
        ak.key_hash,
        ak.is_revoked
    FROM public.api_keys ak
    WHERE ak.key_prefix = prefix
    AND ak.is_revoked = false;
END;
$$;

-- Restrict execution to authenticated users (though primarily called from Edge Functions with service role)
REVOKE EXECUTE ON FUNCTION public.validate_api_key(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_api_key(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_api_key(text) TO service_role;
