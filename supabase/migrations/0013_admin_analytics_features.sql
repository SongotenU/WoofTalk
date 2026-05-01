-- Migration 0013: Admin/Analytics features
-- Error logs, subscription snapshots, A/B testing, feature flags, user segments, push campaigns

-- 1. Error Logs table
CREATE TABLE IF NOT EXISTS public.error_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    platform text NOT NULL CHECK (platform IN ('ios', 'android', 'web', 'edge_function')),
    error_type text NOT NULL,
    message text NOT NULL,
    stack_trace text,
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    endpoint text,
    status_code integer,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.error_logs ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can read error logs"
    ON public.error_logs FOR SELECT
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

CREATE INDEX idx_error_logs_created ON public.error_logs(created_at DESC);
CREATE INDEX idx_error_logs_platform ON public.error_logs(platform);
CREATE INDEX idx_error_logs_type ON public.error_logs(error_type);

-- 2. Subscription snapshots
CREATE TABLE IF NOT EXISTS public.subscription_snapshots (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    snapshot_date date DEFAULT CURRENT_DATE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    revenuecat_uid text NOT NULL,
    status text NOT NULL,
    entitlement text,
    price_usd numeric(10,2) DEFAULT 0,
    currency text DEFAULT 'USD',
    trial_end timestamptz,
    cancel_at_period_end boolean DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(snapshot_date, revenuecat_uid)
);

ALTER TABLE public.subscription_snapshots ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can read subscription snapshots"
    ON public.subscription_snapshots FOR SELECT
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

CREATE INDEX idx_sub_snapshots_date ON public.subscription_snapshots(snapshot_date DESC);
CREATE INDEX idx_sub_snapshots_user ON public.subscription_snapshots(user_id);

-- 3. A/B Experiments table
CREATE TABLE IF NOT EXISTS public.ab_experiments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    is_active boolean DEFAULT false,
    variants jsonb NOT NULL DEFAULT '[]',
    start_date timestamptz,
    end_date timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

-- 4. Feature Flags table
CREATE TABLE IF NOT EXISTS public.feature_flags (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    key text NOT NULL UNIQUE,
    name text NOT NULL,
    description text,
    is_enabled boolean DEFAULT false,
    rollout_percentage integer DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
    value jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.feature_flags ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can manage feature flags"
    ON public.feature_flags FOR ALL
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

CREATE INDEX idx_feature_flags_key ON public.feature_flags(key);

-- 5. User Segments table
CREATE TABLE IF NOT EXISTS public.user_segments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    filters jsonb NOT NULL DEFAULT '{}',
    user_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.user_segments ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can manage user segments"
    ON public.user_segments FOR ALL
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

-- 6. Push Campaigns table
CREATE TABLE IF NOT EXISTS public.push_campaigns (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}',
    segment_id uuid REFERENCES public.user_segments(id) ON DELETE SET NULL,
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled')),
    scheduled_for timestamptz,
    sent_at timestamptz,
    recipient_count integer DEFAULT 0,
    success_count integer DEFAULT 0,
    failure_count integer DEFAULT 0,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.push_campaigns ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can manage push campaigns"
    ON public.push_campaigns FOR ALL
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

-- 7. Experiment assignments
CREATE TABLE IF NOT EXISTS public.experiment_assignments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    experiment_id uuid REFERENCES public.ab_experiments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    variant text NOT NULL,
    assigned_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(experiment_id, user_id)
);

ALTER TABLE public.experiment_assignments ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Admins can read experiment assignments"
    ON public.experiment_assignments FOR SELECT
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

-- 8. Push Tokens table
CREATE TABLE IF NOT EXISTS public.push_tokens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token text NOT NULL,
    platform text DEFAULT 'ios' CHECK (platform IN ('ios', 'android', 'web')),
    breed text,
    location text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(fcm_token)
);

ALTER TABLE public.push_tokens ENABLE ROW_LEVEL_SECURITY;

CREATE POLICY "Users can manage their own push tokens"
    ON public.push_tokens FOR ALL
    USING (auth.uid() = user_id);

CREATE INDEX idx_push_tokens_user ON public.push_tokens(user_id);
CREATE INDEX idx_push_tokens_platform ON public.push_tokens(platform);

-- Seed default feature flags
INSERT INTO public.feature_flags (key, name, description, is_enabled, rollout_percentage)
VALUES
    ('ios_background_audio', 'iOS Background Audio', 'Enable background audio translation on iOS', false, 0),
    ('android_material_you', 'Android Material You', 'Enable Material You styling on Android', false, 0),
    ('watch_standalone', 'Watch Standalone Mode', 'Enable standalone translation on Watch', false, 0),
    ('ai_streaming', 'AI Streaming Translations', 'Enable streaming responses from AI', false, 0),
    ('pwa_offline', 'PWA Offline Mode', 'Enable offline mode in PWA', false, 0)
ON CONFLICT (key) DO NOTHING;