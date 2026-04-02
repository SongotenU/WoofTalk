-- Migration 001: Initial Schema
-- Phase 19: Backend Infrastructure
-- Created: 2026-03-31
-- Description: Core tables for WoofTalk cross-platform backend
-- Run: supabase db push OR paste into Supabase SQL Editor

BEGIN;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- USERS TABLE
-- Maps to iOS Core Data User entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY,  -- Same as auth.users.id
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    platform TEXT NOT NULL DEFAULT 'unknown' CHECK (platform IN ('ios', 'android', 'web', 'unknown')),
    is_premium BOOLEAN NOT NULL DEFAULT false,
    subscription_expiry TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.users IS 'User profiles linked to auth.users';
COMMENT ON COLUMN public.users.id IS 'Same UUID as auth.users.id';
COMMENT ON COLUMN public.users.platform IS 'Primary platform: ios, android, web';

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_platform ON public.users(platform);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at DESC);

-- ============================================================================
-- TRANSLATIONS TABLE
-- Maps to iOS Core Data Translation entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    human_text TEXT NOT NULL,
    animal_text TEXT NOT NULL,
    source_language TEXT NOT NULL DEFAULT 'human',
    target_language TEXT NOT NULL DEFAULT 'dog',
    confidence FLOAT NOT NULL DEFAULT 0.0 CHECK (confidence >= 0 AND confidence <= 1),
    quality_score FLOAT CHECK (quality_score >= 0 AND quality_score <= 1),
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.translations IS 'User translation history';
COMMENT ON COLUMN public.translations.source_language IS 'Source: human, dog, cat, bird';
COMMENT ON COLUMN public.translations.target_language IS 'Target: human, dog, cat, bird';

CREATE INDEX IF NOT EXISTS idx_translations_user_id ON public.translations(user_id);
CREATE INDEX IF NOT EXISTS idx_translations_user_created ON public.translations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_translations_favorite ON public.translations(user_id) WHERE is_favorite = true;

-- ============================================================================
-- COMMUNITY PHRASES TABLE
-- Maps to iOS Core Data CommunityPhrase entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.community_phrases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phrase_text TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'dog',
    submitted_by UUID NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    upvotes INT NOT NULL DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INT NOT NULL DEFAULT 0 CHECK (downvotes >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.community_phrases IS 'Community-contributed translation phrases';
COMMENT ON COLUMN public.community_phrases.approval_status IS 'pending, approved, rejected';

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_phrases_search ON public.community_phrases USING GIN (phrase_text gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_phrases_language ON public.community_phrases(language);
CREATE INDEX IF NOT EXISTS idx_phrases_status ON public.community_phrases(approval_status);
CREATE INDEX IF NOT EXISTS idx_phrases_submitted_by ON public.community_phrases(submitted_by);
CREATE INDEX IF NOT EXISTS idx_phrases_popularity ON public.community_phrases((upvotes - downvotes) DESC);
CREATE INDEX IF NOT EXISTS idx_phrases_updated ON public.community_phrases(updated_at DESC);

-- ============================================================================
-- CONTRIBUTIONS TABLE
-- Maps to iOS Core Data Contribution entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    phrase_id UUID NOT NULL REFERENCES public.community_phrases(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'under_review')),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewer_id UUID REFERENCES public.users(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.contributions IS 'User phrase contribution submissions';

CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON public.contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_phrase_id ON public.contributions(phrase_id);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON public.contributions(status);
CREATE INDEX IF NOT EXISTS idx_contributions_submitted ON public.contributions(submitted_at DESC);

-- ============================================================================
-- FOLLOW RELATIONSHIPS TABLE
-- Maps to iOS Core Data FollowRelationship entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.follow_relationships (
    follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

COMMENT ON TABLE public.follow_relationships IS 'User follow relationships';

CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follow_relationships(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follow_relationships(following_id);

-- Prevent self-following
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_no_self_follow'
    ) THEN
        ALTER TABLE public.follow_relationships
            ADD CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id);
    END IF;
END $$;

-- ============================================================================
-- BLOCK RELATIONSHIPS TABLE
-- Maps to iOS Core Data BlockRelationship entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.block_relationships (
    blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

COMMENT ON TABLE public.block_relationships IS 'User block relationships (private)';

CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON public.block_relationships(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON public.block_relationships(blocked_id);

-- Prevent self-blocking
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_no_self_block'
    ) THEN
        ALTER TABLE public.block_relationships
            ADD CONSTRAINT chk_no_self_block CHECK (blocker_id != blocked_id);
    END IF;
END $$;

-- ============================================================================
-- ACTIVITY EVENTS TABLE
-- Maps to iOS Core Data ActivityEvent entity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.activity_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'phrase_submitted', 'phrase_approved', 'phrase_rejected',
        'follow', 'unfollow',
        'translation_created', 'translation_favorited',
        'leaderboard_achieved', 'contribution_made'
    )),
    event_data JSONB NOT NULL DEFAULT '{}',
    visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'followers_only', 'private')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.activity_events IS 'Social activity feed events';
COMMENT ON COLUMN public.activity_events.event_data IS 'Flexible JSON data for event details';

CREATE INDEX IF NOT EXISTS idx_activity_user ON public.activity_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_type ON public.activity_events(event_type);
CREATE INDEX IF NOT EXISTS idx_activity_visibility ON public.activity_events(visibility);
CREATE INDEX IF NOT EXISTS idx_activity_created ON public.activity_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_event_data ON public.activity_events USING GIN (event_data);

-- ============================================================================
-- LEADERBOARD ENTRIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    score INT NOT NULL DEFAULT 0,
    period TEXT NOT NULL DEFAULT 'all_time' CHECK (period IN ('daily', 'weekly', 'monthly', 'all_time')),
    rank INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.leaderboard_entries IS 'Computed leaderboard entries';
COMMENT ON COLUMN public.leaderboard_entries.score IS 'Score based on contributions, translations, etc.';

CREATE INDEX IF NOT EXISTS idx_leaderboard_period_rank ON public.leaderboard_entries(period, rank ASC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_user ON public.leaderboard_entries(user_id, period);
CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_user_period ON public.leaderboard_entries(user_id, period);

-- ============================================================================
-- PUSH NOTIFICATIONS TABLE (for FCM queue)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_at TIMESTAMPTZ
);

COMMENT ON TABLE public.push_notifications IS 'Push notification queue for FCM';

CREATE INDEX IF NOT EXISTS idx_push_status ON public.push_notifications(status);
CREATE INDEX IF NOT EXISTS idx_push_user ON public.push_notifications(user_id);

-- ============================================================================
-- SEED DATA (for testing)
-- ============================================================================

-- Note: These users will be created by the auth trigger in migration 003
-- For testing, create auth users first, then seed other data

-- Seed community phrases
INSERT INTO public.community_phrases (phrase_text, language, approval_status, upvotes, downvotes) VALUES
    ('woof woof', 'dog', 'approved', 42, 3),
    ('bark bark bark', 'dog', 'approved', 28, 5),
    ('meow', 'cat', 'approved', 35, 2),
    ('purr purr', 'cat', 'approved', 21, 1),
    ('chirp chirp', 'bird', 'approved', 15, 0),
    ('hello human', 'dog', 'approved', 56, 4),
    ('i love you', 'dog', 'approved', 89, 2),
    ('feed me', 'cat', 'approved', 67, 8),
    ('play with me', 'dog', 'approved', 45, 3),
    ('good boy', 'human', 'approved', 78, 1)
ON CONFLICT DO NOTHING;

COMMIT;
