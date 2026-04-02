-- Migration 004: Add org_id Columns to Existing Tables
-- All columns added with DEFAULT NULL (fast, zero-lock in PG 11+)
-- Existing consumer users retain org_id = NULL; backward compatible.

ALTER TABLE public.translations
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.community_phrases
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.social_follows
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.social_likes
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.social_comments
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.user_settings
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.notification_preferences
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.activity_events
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.leaderboard_entries
    ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES public.organizations(id) ON DELETE SET NULL;

-- Indexes for org-scoped queries
CREATE INDEX IF NOT EXISTS idx_translations_org ON public.translations(org_id);
CREATE INDEX IF NOT EXISTS idx_community_phrases_org ON public.community_phrases(org_id);
CREATE INDEX IF NOT EXISTS idx_social_follows_org ON public.social_follows(org_id);
CREATE INDEX IF NOT EXISTS idx_social_likes_org ON public.social_likes(org_id);
CREATE INDEX IF NOT EXISTS idx_social_comments_org ON public.social_comments(org_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_org ON public.user_settings(org_id);
CREATE INDEX IF NOT EXISTS idx_notification_pref_org ON public.notification_preferences(org_id);
CREATE INDEX IF NOT EXISTS idx_activity_events_org ON public.activity_events(org_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_org ON public.leaderboard_entries(org_id);
