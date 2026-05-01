-- Migration 0014: Subscription Enhancements (Phase 33)
-- Cancellation survey, referrals, promo codes, subscription pause

-- ============================================================
-- 1. Extend subscription_status for cancellation survey
-- ============================================================
ALTER TABLE public.subscription_status
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS cancellation_feedback TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS paused_until TIMESTAMPTZ;

COMMENT ON COLUMN public.subscription_status.cancellation_reason IS
  'Reason user cancelled subscription. Collected via in-app survey.';
COMMENT ON COLUMN public.subscription_status.cancellation_feedback IS
  'Free-text feedback provided during cancellation survey.';
COMMENT ON COLUMN public.subscription_status.cancelled_at IS
  'Timestamp when subscription was cancelled.';
COMMENT ON COLUMN public.subscription_status.paused_until IS
  'If subscription is paused (vacation mode), date when it resumes.';

-- ============================================================
-- 2. referral_codes table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.referral_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  code TEXT UNIQUE NOT NULL,
  uses_remaining INT DEFAULT 10,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '365 days')
);

CREATE INDEX IF NOT EXISTS idx_referral_codes_referrer ON public.referral_codes(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON public.referral_codes(code);

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own referral codes"
  ON public.referral_codes FOR SELECT
  USING (auth.uid() = referrer_id);

CREATE POLICY "Users can create own referral codes"
  ON public.referral_codes FOR INSERT
  WITH CHECK (auth.uid() = referrer_id);

-- ============================================================
-- 3. referral_tracking table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.referral_tracking (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referral_code TEXT REFERENCES public.referral_codes(code) ON DELETE CASCADE NOT NULL,
  referred_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  referred_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  converted_at TIMESTAMPTZ,
  reward_granted BOOLEAN DEFAULT FALSE,
  UNIQUE(referred_user_id)
);

CREATE INDEX IF NOT EXISTS idx_referral_tracking_code ON public.referral_tracking(referral_code);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_user ON public.referral_tracking(referred_user_id);

ALTER TABLE public.referral_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read referrals they made"
  ON public.referral_tracking FOR SELECT
  USING (
    auth.uid() = referred_user_id
    OR auth.uid() IN (SELECT referrer_id FROM public.referral_codes WHERE code = referral_code)
  );

-- ============================================================
-- 4. cancellation_surveys table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cancellation_surveys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  reason TEXT NOT NULL,
  feedback TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cancellation_surveys_user ON public.cancellation_surveys(user_id);

ALTER TABLE public.cancellation_surveys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own cancellation survey"
  ON public.cancellation_surveys FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own cancellation survey"
  ON public.cancellation_surveys FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================
-- Function: generate_referral_code
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_referral_code(user_id UUID)
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
BEGIN
  new_code := upper(substring(md5(user_id::text || now()::text) from 1 for 8));
  INSERT INTO public.referral_codes (referrer_id, code) VALUES (user_id, new_code);
  RETURN new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: apply_referral_code
-- ============================================================
CREATE OR REPLACE FUNCTION public.apply_referral_code(
  p_user_id UUID,
  p_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_referrer_id UUID;
BEGIN
  SELECT referrer_id INTO v_referrer_id
  FROM public.referral_codes
  WHERE code = p_code AND is_active = TRUE AND (uses_remaining > 0 OR uses_remaining IS NULL)
    AND (expires_at IS NULL OR expires_at > now());

  IF v_referrer_id IS NULL OR v_referrer_id = p_user_id THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.referral_tracking (referral_code, referred_user_id)
  VALUES (p_code, p_user_id)
  ON CONFLICT (referred_user_id) DO NOTHING;

  UPDATE public.referral_codes
  SET uses_remaining = uses_remaining - 1
  WHERE code = p_code AND uses_remaining > 0;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
