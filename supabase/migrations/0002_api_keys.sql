-- Migration 002: API Key Tables
-- Creates api_keys, api_key_usage

-- ============================================================
-- api_keys
-- ============================================================
CREATE TABLE IF NOT EXISTS public.api_keys (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL,
    name text NOT NULL,
    key_prefix text NOT NULL,
    key_hash text NOT NULL,
    scope text NOT NULL DEFAULT 'translate:full' CHECK (scope IN ('translate:read', 'translate:write', 'translate:full')),
    rate_limit int NOT NULL DEFAULT 60,
    is_revoked boolean NOT NULL DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    revoked_at timestamptz
);

ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- Users can read their own keys (without hash for security, but RLS allows read)
CREATE POLICY "Users can read own api keys"
    ON public.api_keys
    FOR SELECT
    USING (
        auth.uid() = user_id
        OR (
            org_id IS NOT NULL AND auth.uid() IN (
                SELECT om.user_id FROM public.organization_members om
                WHERE om.org_id = api_keys.org_id
                AND om.role IN ('owner', 'admin')
                AND om.status = 'active'
            )
        )
    );

-- Users can create keys (via the API key management function)
CREATE POLICY "Users can create api keys"
    ON public.api_keys
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can revoke their own keys
CREATE POLICY "Users can update own api keys"
    ON public.api_keys
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Service role can manage all keys (no RLS policy needed for service role,
-- but this ensures consistency if ever switched to anon key for internal use)

CREATE INDEX idx_api_keys_prefix ON public.api_keys(key_prefix);
CREATE INDEX idx_api_keys_user ON public.api_keys(user_id);
CREATE INDEX idx_api_keys_org ON public.api_keys(org_id);

-- ============================================================
-- api_key_usage
-- ============================================================
CREATE TABLE IF NOT EXISTS public.api_key_usage (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    api_key_id uuid REFERENCES public.api_keys(id) ON DELETE CASCADE NOT NULL,
    endpoint text NOT NULL,
    status_code int NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.api_key_usage ENABLE ROW LEVEL SECURITY;

-- Key owners can query their own usage
CREATE POLICY "Users can read own api key usage"
    ON public.api_key_usage
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT ak.user_id FROM public.api_keys ak WHERE ak.id = api_key_usage.api_key_id
        )
    );

-- Service role can write usage (handled in Edge Functions with service role key)
-- No explicit INSERT policy needed for RLS since service role bypasses RLS

CREATE INDEX idx_api_key_usage_key_created ON public.api_key_usage(api_key_id, created_at);
CREATE INDEX idx_api_key_usage_created ON public.api_key_usage(created_at);
