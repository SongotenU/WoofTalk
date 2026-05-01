-- Migration 0016: Create subscription_snapshots table
-- Daily MRR/revenue tracking and cohort analysis support

CREATE TABLE IF NOT EXISTS public.subscription_snapshots (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    snapshot_date date DEFAULT CURRENT_DATE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    revenuecat_uid text NOT NULL,
    status text NOT NULL CHECK (status IN ('trial', 'active', 'cancelled', 'expired', 'past_due')),
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

CREATE POLICY "Service role can manage subscription snapshots"
    ON public.subscription_snapshots FOR ALL
    USING (auth.role() = 'service_role');

CREATE INDEX idx_sub_snapshots_date ON public.subscription_snapshots(snapshot_date DESC);
CREATE INDEX idx_sub_snapshots_user ON public.subscription_snapshots(user_id);
CREATE INDEX idx_sub_snapshots_status ON public.subscription_snapshots(status);
