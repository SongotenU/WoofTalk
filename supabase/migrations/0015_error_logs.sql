-- Migration 0015: Create error_logs table
-- Error tracking for all platforms (iOS, Android, Web, Edge Functions)

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

CREATE POLICY "Service role can insert error logs"
    ON public.error_logs FOR INSERT
    WITH CHECK (true);

CREATE INDEX idx_error_logs_created ON public.error_logs(created_at DESC);
CREATE INDEX idx_error_logs_platform ON public.error_logs(platform);
CREATE INDEX idx_error_logs_type ON public.error_logs(error_type);
CREATE INDEX idx_error_logs_user ON public.error_logs(user_id);
