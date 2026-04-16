-- Migration 0013: Subscription Backend (Phase 51)

-- ============================================================
-- PostgreSQL ENUM types (D-05, D-06)
-- ============================================================
CREATE TYPE public.subscription_tier AS ENUM ('free', 'trial', 'pro');
CREATE TYPE public.purchase_platform AS ENUM ('ios', 'android', 'web', 'none');

-- ============================================================
-- subscription_status table (SUB-01)
-- ============================================================
CREATE TABLE public.subscription_status (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  revenuecat_id TEXT NOT NULL UNIQUE,
  entitlements JSONB DEFAULT '{}'::jsonb,
  subscription_tier public.subscription_tier DEFAULT 'free',
  trial_ends_at TIMESTAMPTZ,
  purchase_platform public.purchase_platform DEFAULT 'none',
  cancellation_reason TEXT,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX idx_subscription_status_updated_at ON public.subscription_status(updated_at);

CREATE TRIGGER update_subscription_status_updated_at
  BEFORE UPDATE ON public.subscription_status
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- RLS on subscription_status
-- ============================================================
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription status"
  ON public.subscription_status FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================
-- user_profiles table (SUB-02)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  revenuecat_id TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================
-- Replace translations INSERT policy with tier-aware version
-- (SUB-08, SUB-09, D-03, D-04)
-- ============================================================
DROP POLICY IF EXISTS "Users can insert own translations" ON public.translations;

CREATE POLICY "Users can insert own translations with tier limit"
  ON public.translations FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      (SELECT subscription_tier FROM public.subscription_status
       WHERE user_id = auth.uid()) IN ('pro', 'trial')
      OR
      (
        COALESCE(
          (SELECT subscription_tier FROM public.subscription_status
           WHERE user_id = auth.uid()), 'free'::public.subscription_tier
        ) = 'free'::public.subscription_tier
        AND (
          SELECT COUNT(*) FROM public.translations
          WHERE user_id = auth.uid()
          AND created_at >= CURRENT_DATE
        ) < 3
      )
    )
  );

-- ============================================================
-- webhook_events table for idempotency (SUB-04)
-- ============================================================
CREATE TABLE public.webhook_events (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  app_user_id TEXT NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX idx_webhook_events_app_user_id ON public.webhook_events(app_user_id);
