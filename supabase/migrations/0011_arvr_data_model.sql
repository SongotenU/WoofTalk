-- Migration 011: AR/VR Data Model Extensions (Phase 42, Plan 02)
-- Platform column, spatial positions, dog avatars, user devices
-- Original plan named this 0009, but 0009 already exists -- using 0011.

-- ============================================================
-- 1. Extend translations table with platform and spatial_position
-- ============================================================

ALTER TABLE public.translations
    ADD COLUMN IF NOT EXISTS platform text DEFAULT 'mobile';

COMMENT ON COLUMN public.translations.platform IS
    'Platform where translation was recorded: ios, android, web, watch, ar_vision, vr_quest. Default mobile for backward compatibility.';

ALTER TABLE public.translations
    ADD COLUMN IF NOT EXISTS spatial_position jsonb;

COMMENT ON COLUMN public.translations.spatial_position IS
    '3D spatial position for AR/VR contexts. Format: {"x": float, "y": float, "z": float}. NULL for non-AR/VR.';

-- Backfill existing records to platform='mobile'
UPDATE public.translations
    SET platform = 'mobile'
    WHERE platform IS NULL;

-- Make platform NOT NULL after backfill (optional safety)
ALTER TABLE public.translations
    ALTER COLUMN platform SET NOT NULL;

-- ============================================================
-- 2. dog_avatars table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.dog_avatars (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    breed text NOT NULL DEFAULT 'golden',
    color text NOT NULL DEFAULT 'golden',
    accessories jsonb DEFAULT '[]'::jsonb,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.dog_avatars IS
    'User-configurable dog avatars for VR/AR modes. accessories is a JSONB array of equipped items.';

-- Index for user lookup
CREATE INDEX IF NOT EXISTS idx_dog_avatars_user ON public.dog_avatars(user_id);

-- Updated-at trigger
CREATE TRIGGER update_dog_avatars_updated_at
    BEFORE UPDATE ON public.dog_avatars
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 3. user_devices table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_devices (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    platform text NOT NULL,
    device_model text,
    os_version text,
    app_version text,
    first_seen timestamptz DEFAULT now() NOT NULL,
    last_seen timestamptz DEFAULT now() NOT NULL,
    UNIQUE(user_id, platform)
);

COMMENT ON TABLE public.user_devices IS
    'Tracks user devices across platforms for cross-platform sync analytics.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_devices_user ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_platform ON public.user_devices(platform);

-- Updated-at equivalent (last_seen) trigger
CREATE OR REPLACE FUNCTION public.update_last_seen_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_seen = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_devices_last_seen
    BEFORE UPDATE ON public.user_devices
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_seen_column();
