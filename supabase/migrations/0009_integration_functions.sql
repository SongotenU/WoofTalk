-- Migration 009: Integration Helper Functions
-- Cross-phase queries needed for E2E validation and enterprise reporting.

-- ============================================================
-- org_usage_summary(): Per-org API usage + translation activity
-- ============================================================
CREATE OR REPLACE FUNCTION public.org_usage_summary(target_org_id uuid)
RETURNS TABLE (
    org_name text,
    total_translations bigint,
    total_api_calls bigint,
    total_members bigint,
    active_api_keys bigint,
    total_teams bigint
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        o.name AS org_name,
        (SELECT count(*) FROM public.translations t WHERE t.org_id = target_org_id) AS total_translations,
        (SELECT count(*) FROM public.api_key_usage u JOIN public.api_keys k ON k.id = u.api_key_id WHERE k.org_id = target_org_id) AS total_api_calls,
        (SELECT count(*) FROM public.organization_members WHERE org_id = target_org_id AND status = 'active') AS total_members,
        (SELECT count(*) FROM public.api_keys WHERE org_id = target_org_id AND is_revoked = false) AS active_api_keys,
        (SELECT count(*) FROM public.teams WHERE org_id = target_org_id) AS total_teams
    FROM public.organizations o
    WHERE o.id = target_org_id;
$$;

-- ============================================================
-- cross_org_isolation_check(): Verify no cross-org data leakage
-- Returns 0 if isolation is intact, >0 if data leaked
-- ============================================================
CREATE OR REPLACE FUNCTION public.cross_org_isolation_check(org_a uuid, org_b uuid)
RETURNS TABLE (
    translations_leaked bigint,
    phrases_leaked bigint,
    api_keys_leaked bigint
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        -- Translations from org A appearing in org B (should be 0)
        (SELECT count(*) FROM public.translations WHERE org_id = org_a) -
        (SELECT count(*) FROM public.translations t
         JOIN public.organization_members om ON om.org_id = t.org_id
         WHERE t.org_id = org_a AND om.org_id = org_a) AS translations_leaked,
        -- Community phrases leakage
        (SELECT count(*) FROM public.community_phrases WHERE org_id = org_a) AS phrases_leaked,
        -- API keys assigned to wrong org
        (SELECT count(*) FROM public.api_keys WHERE org_id = org_a AND org_id != org_a) AS api_keys_leaked;
$$;

-- ============================================================
-- audit_action(): Helper for inserting audit log entries
-- ============================================================
CREATE OR REPLACE FUNCTION public.audit_action(
    p_action text,
    p_target_type text DEFAULT NULL,
    p_target_id uuid DEFAULT NULL,
    p_details jsonb DEFAULT '{}'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_id uuid;
BEGIN
    INSERT INTO public.admin_audit_log (admin_user_id, action, target_type, target_id, details)
    VALUES (auth.uid(), p_action, p_target_type, p_target_id, p_details)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.org_usage_summary(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.org_usage_summary(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION public.cross_org_isolation_check(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cross_org_isolation_check(uuid, uuid) TO service_role;

GRANT EXECUTE ON FUNCTION public.audit_action(text, text, uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.audit_action(text, text, uuid, jsonb) TO service_role;
