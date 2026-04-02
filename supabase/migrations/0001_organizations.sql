-- Migration 001: Organization Tables
-- Creates organizations, organization_members, teams, team_members

-- ============================================================
-- organizations
-- ============================================================
CREATE TABLE IF NOT EXISTS public.organizations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    slug text NOT NULL UNIQUE,
    plan_type text NOT NULL DEFAULT 'free' CHECK (plan_type IN ('free', 'pro', 'enterprise')),
    owner_id uuid REFERENCES auth.users(id) NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Owner can manage their organization
CREATE POLICY "Owners can manage their org"
    ON public.organizations
    FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Members can read organizations they belong to
CREATE POLICY "Members can read their org"
    ON public.organizations
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om WHERE om.org_id = id AND om.status = 'active'
        )
    );

CREATE INDEX idx_organizations_slug ON public.organizations(slug);
CREATE INDEX idx_organizations_owner ON public.organizations(owner_id);

-- ============================================================
-- organization_members
-- ============================================================
CREATE TABLE IF NOT EXISTS public.organization_members (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role text NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'invited', 'suspended')),
    invite_token text UNIQUE,
    invite_expires_at timestamptz,
    joined_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(org_id, user_id)
);

ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- Users can read their own membership
CREATE POLICY "Users can read own membership"
    ON public.organization_members
    FOR SELECT
    USING (auth.uid() = user_id);

-- Owners and admins can manage members in their org
CREATE POLICY "Org owners/admins can manage members"
    ON public.organization_members
    FOR ALL
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = organization_members.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    )
    WITH CHECK (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = organization_members.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    );

CREATE UNIQUE INDEX idx_org_members_org_user ON public.organization_members(org_id, user_id);
CREATE INDEX idx_org_members_user ON public.organization_members(user_id);

-- ============================================================
-- teams
-- ============================================================
CREATE TABLE IF NOT EXISTS public.teams (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    name text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Org members can read teams in their org
CREATE POLICY "Org members can read teams"
    ON public.teams
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = teams.org_id AND om.status = 'active'
        )
    );

-- Org owners/admins can manage teams
CREATE POLICY "Org owners/admins can manage teams"
    ON public.teams
    FOR ALL
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = teams.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    )
    WITH CHECK (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = teams.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    );

CREATE INDEX idx_teams_org ON public.teams(org_id);

-- ============================================================
-- team_members
-- ============================================================
CREATE TABLE IF NOT EXISTS public.team_members (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id uuid REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    joined_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(team_id, user_id)
);

ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- Team members can read team membership
CREATE POLICY "Team members can read membership"
    ON public.team_members
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT tm.user_id FROM public.team_members tm WHERE tm.team_id = team_members.team_id
        )
        OR auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = (SELECT org_id FROM public.teams WHERE id = team_members.team_id)
            AND om.status = 'active'
        )
    );

-- Org owners/admins can manage team membership
CREATE POLICY "Org owners/admins can manage team membership"
    ON public.team_members
    FOR ALL
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = (SELECT org_id FROM public.teams t WHERE t.id = team_members.team_id)
            AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    )
    WITH CHECK (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = (SELECT org_id FROM public.teams t WHERE t.id = team_members.team_id)
            AND om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    );

CREATE UNIQUE INDEX idx_team_members_team_user ON public.team_members(team_id, user_id);
CREATE INDEX idx_team_members_user ON public.team_members(user_id);

-- ============================================================
-- Updated-at trigger for organizations
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
