-- Migration 006: Migrate Role Functions
-- Replace raw_user_meta_data->>'role' checks with organization_members join table.

-- ============================================================
-- is_admin(): Returns true if user is owner or admin in any active org
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.organization_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    );
$$;

-- ============================================================
-- is_moderator(): Returns true if user is owner, admin, or designated moderator
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.organization_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    );
$$;

-- ============================================================
-- get_user_orgs(): Returns all organizations the user belongs to
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_orgs()
RETURNS TABLE (
    org_id uuid,
    org_name text,
    org_slug text,
    plan_type text,
    member_role text,
    member_status text
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        o.id,
        o.name,
        o.slug,
        o.plan_type,
        om.role,
        om.status
    FROM public.organization_members om
    JOIN public.organizations o ON o.id = om.org_id
    WHERE om.user_id = auth.uid();
$$;

-- ============================================================
-- get_user_org_role(): Returns the user's highest role across orgs
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_org_role(target_org_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT role FROM public.organization_members
    WHERE user_id = auth.uid() AND org_id = target_org_id AND status = 'active'
    LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO service_role;

REVOKE EXECUTE ON FUNCTION public.is_moderator() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_moderator() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_moderator() TO service_role;

REVOKE EXECUTE ON FUNCTION public.get_user_orgs() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_orgs() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_orgs() TO service_role;

REVOKE EXECUTE ON FUNCTION public.get_user_org_role(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_org_role(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_org_role(uuid) TO service_role;
