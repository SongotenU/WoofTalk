-- Migration 008: Admin Audit Log
-- Tracks admin actions: who did what, when, and on what target.

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    action text NOT NULL,             -- e.g., 'USER_BAN', 'CONTENT_APPROVE', 'ROLE_CHANGE', 'BULK_DELETE'
    target_type text,                  -- e.g., 'user', 'community_phrase', 'api_key'
    target_id uuid,                    -- ID of the affected resource
    details jsonb DEFAULT '{}',        -- Context-specific details (old_value, new_value, count, etc.)
    ip_address text,                   -- Admin's IP (from request)
    created_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admins can read audit log
CREATE POLICY "Admins can read audit log"
    ON public.admin_audit_log
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
        )
    );

-- Service role can write (inserted from Edge Functions / server actions)
-- No explicit INSERT policy for user-level RLS — service role bypasses RLS

-- Indexes for querying
CREATE INDEX idx_admin_audit_admin ON public.admin_audit_log(admin_user_id);
CREATE INDEX idx_admin_audit_action ON public.admin_audit_log(action);
CREATE INDEX idx_admin_audit_created ON public.admin_audit_log(created_at DESC);
CREATE INDEX idx_admin_audit_target ON public.admin_audit_log(target_type, target_id);
