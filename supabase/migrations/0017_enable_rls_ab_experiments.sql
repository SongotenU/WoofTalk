-- Enable RLS on ab_experiments table (was missing from migration 0013)
ALTER TABLE public.ab_experiments ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can manage experiments
CREATE POLICY "Admins can manage ab_experiments"
    ON public.ab_experiments
    FOR ALL
    USING (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ))
    WITH CHECK (auth.uid() IN (
        SELECT om.user_id FROM public.organization_members om
        WHERE om.role IN ('owner', 'admin') AND om.status = 'active'
    ));

-- Policy: All authenticated users can view active experiments (for assignment)
CREATE POLICY "Users can view active experiments"
    ON public.ab_experiments
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = true);
