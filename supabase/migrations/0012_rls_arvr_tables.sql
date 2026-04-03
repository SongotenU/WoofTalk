-- Migration 012: RLS Policies for AR/VR Tables (Phase 42, Plan 02)
-- Enables RLS on dog_avatars and user_devices with user-ownership policies.
-- Original plan named this 0010, but 0010 already exists -- using 0012.

-- ============================================================
-- 1. dog_avatars RLS
-- ============================================================
ALTER TABLE public.dog_avatars ENABLE ROW LEVEL SECURITY;

-- Users can manage their own dog avatars
CREATE POLICY "users_own_dog_avatars"
    ON public.dog_avatars
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 2. user_devices RLS
-- ============================================================
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Users can manage their own device records
CREATE POLICY "users_own_devices"
    ON public.user_devices
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 3. Update translations RLS to account for new columns
-- ============================================================
-- The existing RLS policies on translations (migration 0005) already
-- scope by user_id and org_id. The new platform and spatial_position
-- columns are simply additional data on existing rows -- no policy
-- changes needed. The new columns automatically inherit the existing
-- row-level access controls.
