-- Migration 003: Database Functions & Triggers
-- Phase 19: Backend Infrastructure
-- Created: 2026-03-31
-- Description: Functions, triggers, and auth integration
-- Prerequisites: 001_initial_schema.sql, 002_rls_policies.sql
-- Run: supabase db push OR paste into Supabase SQL Editor

BEGIN;

-- ============================================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE TRIGGER update_community_phrases_updated_at
    BEFORE UPDATE ON public.community_phrases
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE TRIGGER update_leaderboard_entries_updated_at
    BEFORE UPDATE ON public.leaderboard_entries
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- AUTH USER CREATION TRIGGER
-- Creates a user profile when a new auth user signs up
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, platform, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'platform', 'unknown'),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- PHRASE VOTE FUNCTION
-- Handles upvote/downvote with atomic increment
-- ============================================================================

CREATE OR REPLACE FUNCTION public.increment_phrase_votes(
    p_phrase_id UUID,
    p_is_upvote BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    IF p_is_upvote THEN
        UPDATE public.community_phrases
        SET upvotes = upvotes + 1, updated_at = NOW()
        WHERE id = p_phrase_id;
    ELSE
        UPDATE public.community_phrases
        SET downvotes = downvotes + 1, updated_at = NOW()
        WHERE id = p_phrase_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- LEADERBOARD CALCULATION FUNCTION
-- Computes leaderboard scores based on user activity
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_leaderboard(
    p_period TEXT DEFAULT 'all_time'
)
RETURNS VOID AS $$
DECLARE
    v_start_date TIMESTAMPTZ;
BEGIN
    -- Calculate start date based on period
    CASE p_period
        WHEN 'daily' THEN v_start_date := DATE_TRUNC('day', NOW());
        WHEN 'weekly' THEN v_start_date := DATE_TRUNC('week', NOW());
        WHEN 'monthly' THEN v_start_date := DATE_TRUNC('month', NOW());
        ELSE v_start_date := '2000-01-01'::TIMESTAMPTZ;
    END CASE;

    -- Delete old entries for this period
    DELETE FROM public.leaderboard_entries WHERE period = p_period;

    -- Calculate scores and insert new entries
    -- Score = (approved_phrases * 10) + (translations * 1) + (upvotes * 2) - (downvotes * 1)
    INSERT INTO public.leaderboard_entries (user_id, score, period, rank, updated_at)
    SELECT
        u.id AS user_id,
        (
            COALESCE(ph.approved_count, 0) * 10 +
            COALESCE(tr.translation_count, 0) * 1 +
            COALESCE(ph.total_upvotes, 0) * 2 -
            COALESCE(ph.total_downvotes, 0) * 1
        ) AS score,
        p_period AS period,
        0 AS rank,
        NOW() AS updated_at
    FROM public.users u
    LEFT JOIN (
        SELECT
            submitted_by AS user_id,
            COUNT(*) FILTER (WHERE approval_status = 'approved') AS approved_count,
            SUM(upvotes) AS total_upvotes,
            SUM(downvotes) AS total_downvotes
        FROM public.community_phrases
        WHERE created_at >= v_start_date
        GROUP BY submitted_by
    ) ph ON u.id = ph.user_id
    LEFT JOIN (
        SELECT
            user_id,
            COUNT(*) AS translation_count
        FROM public.translations
        WHERE created_at >= v_start_date
        GROUP BY user_id
    ) tr ON u.id = tr.user_id
    WHERE ph.approved_count > 0 OR tr.translation_count > 0
    ORDER BY score DESC;

    -- Update ranks
    UPDATE public.leaderboard_entries e
    SET rank = sub.rank
    FROM (
        SELECT id, ROW_NUMBER() OVER (ORDER BY score DESC) AS rank
        FROM public.leaderboard_entries
        WHERE period = p_period
    ) sub
    WHERE e.id = sub.id AND e.period = p_period;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.calculate_leaderboard IS 'Computes leaderboard scores for a given period';

-- ============================================================================
-- ACTIVITY EVENT NOTIFICATION TRIGGER
-- Sends Realtime notification when activity events are created
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_new_activity()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'activity_events',
        json_build_object(
            'operation', TG_OP,
            'record', row_to_json(NEW)
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER activity_events_realtime
    AFTER INSERT ON public.activity_events
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_activity();

-- ============================================================================
-- PHRASE SEARCH FUNCTION
-- Full-text search with trigram similarity for fuzzy matching
-- ============================================================================

CREATE OR REPLACE FUNCTION public.search_phrases(
    p_query TEXT,
    p_language TEXT DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    phrase_text TEXT,
    language TEXT,
    similarity FLOAT,
    upvotes INT,
    downvotes INT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cp.id,
        cp.phrase_text,
        cp.language,
        similarity(cp.phrase_text, p_query) AS similarity,
        cp.upvotes,
        cp.downvotes,
        cp.created_at
    FROM public.community_phrases cp
    WHERE cp.approval_status = 'approved'
        AND (p_language IS NULL OR cp.language = p_language)
        AND cp.phrase_text % p_query
    ORDER BY similarity DESC, (cp.upvotes - cp.downvotes) DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.search_phrases IS 'Full-text phrase search with fuzzy matching';

-- ============================================================================
-- ACTIVITY EVENT CREATION HELPERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_activity_event(
    p_user_id UUID,
    p_event_type TEXT,
    p_event_data JSONB DEFAULT '{}',
    p_visibility TEXT DEFAULT 'public'
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO public.activity_events (user_id, event_type, event_data, visibility)
    VALUES (p_user_id, p_event_type, p_event_data, p_visibility)
    RETURNING id INTO v_event_id;
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BLOCK CHECK FUNCTION
-- Returns true if blocker has blocked blocked_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_blocked(
    p_blocker_id UUID,
    p_blocked_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.block_relationships
        WHERE blocker_id = p_blocker_id AND blocked_id = p_blocked_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FOLLOW CHECK FUNCTION
-- Returns true if follower is following followee
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_following(
    p_follower_id UUID,
    p_followee_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.follow_relationships
        WHERE follower_id = p_follower_id AND following_id = p_followee_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
