-- Migration 002: Row-Level Security Policies
-- Phase 19: Backend Infrastructure
-- Created: 2026-03-31
-- Description: RLS policies for all tables
-- Prerequisites: 001_initial_schema.sql must be run first
-- Run: supabase db push OR paste into Supabase SQL Editor

BEGIN;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Check if current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user has admin role in user metadata
    RETURN COALESCE(
        (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin',
        false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_admin IS 'Returns true if current user has admin role';

-- Check if user is a moderator
CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN COALESCE(
        (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) IN ('admin', 'moderator'),
        false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_moderator IS 'Returns true if current user is admin or moderator';

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_phrases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follow_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.block_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- Users can read/update own profile; admins can read all
-- ============================================================================

-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON public.users
    FOR SELECT
    USING (public.is_admin());

-- System can insert users (via auth trigger)
CREATE POLICY "System can insert users" ON public.users
    FOR INSERT
    WITH CHECK (true);  -- Handled by auth trigger

-- ============================================================================
-- TRANSLATIONS TABLE POLICIES
-- Users can CRUD own translations; no public read
-- ============================================================================

-- Users can view their own translations
CREATE POLICY "Users can view own translations" ON public.translations
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own translations
CREATE POLICY "Users can insert own translations" ON public.translations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own translations
CREATE POLICY "Users can update own translations" ON public.translations
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own translations
CREATE POLICY "Users can delete own translations" ON public.translations
    FOR DELETE
    USING (auth.uid() = user_id);

-- Admins can view all translations
CREATE POLICY "Admins can view all translations" ON public.translations
    FOR SELECT
    USING (public.is_admin());

-- ============================================================================
-- COMMUNITY PHRASES TABLE POLICIES
-- Anyone can read approved; authenticated can create; moderators can approve/reject
-- ============================================================================

-- Anyone (including anon) can view approved phrases
CREATE POLICY "Anyone can view approved phrases" ON public.community_phrases
    FOR SELECT
    USING (approval_status = 'approved');

-- Authenticated users can view their own pending phrases
CREATE POLICY "Users can view own pending phrases" ON public.community_phrases
    FOR SELECT
    USING (auth.uid() = submitted_by);

-- Authenticated users can create phrases
CREATE POLICY "Authenticated users can create phrases" ON public.community_phrases
    FOR INSERT
    WITH CHECK (auth.uid() = submitted_by);

-- Users can update their own phrases (before approval)
CREATE POLICY "Users can update own phrases" ON public.community_phrases
    FOR UPDATE
    USING (auth.uid() = submitted_by AND approval_status = 'pending')
    WITH CHECK (auth.uid() = submitted_by);

-- Moderators can approve/reject phrases
CREATE POLICY "Moderators can update phrase status" ON public.community_phrases
    FOR UPDATE
    USING (public.is_moderator())
    WITH CHECK (public.is_moderator());

-- Admins can view all phrases
CREATE POLICY "Admins can view all phrases" ON public.community_phrases
    FOR SELECT
    USING (public.is_admin());

-- Admins can delete any phrase
CREATE POLICY "Admins can delete phrases" ON public.community_phrases
    FOR DELETE
    USING (public.is_admin());

-- ============================================================================
-- CONTRIBUTIONS TABLE POLICIES
-- Users can CRUD own; moderators can review
-- ============================================================================

-- Users can view their own contributions
CREATE POLICY "Users can view own contributions" ON public.contributions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own contributions
CREATE POLICY "Users can create contributions" ON public.contributions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Moderators can view all contributions
CREATE POLICY "Moderators can view all contributions" ON public.contributions
    FOR SELECT
    USING (public.is_moderator());

-- Moderators can update contribution status
CREATE POLICY "Moderators can update contributions" ON public.contributions
    FOR UPDATE
    USING (public.is_moderator())
    WITH CHECK (public.is_moderator());

-- ============================================================================
-- FOLLOW RELATIONSHIPS TABLE POLICIES
-- Users can manage own follows; anyone can read
-- ============================================================================

-- Anyone can view follow relationships (public social graph)
CREATE POLICY "Anyone can view follow relationships" ON public.follow_relationships
    FOR SELECT
    USING (true);

-- Users can create their own follows
CREATE POLICY "Users can create follows" ON public.follow_relationships
    FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

-- Users can delete their own follows
CREATE POLICY "Users can delete own follows" ON public.follow_relationships
    FOR DELETE
    USING (auth.uid() = follower_id);

-- ============================================================================
-- BLOCK RELATIONSHIPS TABLE POLICIES
-- Users can manage own blocks; private (no public read)
-- ============================================================================

-- Users can view their own blocks
CREATE POLICY "Users can view own blocks" ON public.block_relationships
    FOR SELECT
    USING (auth.uid() = blocker_id);

-- Users can create their own blocks
CREATE POLICY "Users can create blocks" ON public.block_relationships
    FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Users can delete their own blocks
CREATE POLICY "Users can delete own blocks" ON public.block_relationships
    FOR DELETE
    USING (auth.uid() = blocker_id);

-- ============================================================================
-- ACTIVITY EVENTS TABLE POLICIES
-- Users can read visible events; system can create
-- ============================================================================

-- Anyone can view public activity events
CREATE POLICY "Anyone can view public activity" ON public.activity_events
    FOR SELECT
    USING (visibility = 'public');

-- Followers can view followers-only activity
CREATE POLICY "Followers can view followers-only activity" ON public.activity_events
    FOR SELECT
    USING (
        visibility = 'followers_only'
        AND EXISTS (
            SELECT 1 FROM public.follow_relationships
            WHERE follow_relationships.following_id = activity_events.user_id
            AND follow_relationships.follower_id = auth.uid()
        )
    );

-- Users can view their own private activity
CREATE POLICY "Users can view own private activity" ON public.activity_events
    FOR SELECT
    USING (auth.uid() = user_id);

-- Authenticated users can create activity events
CREATE POLICY "Authenticated users can create activity" ON public.activity_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- System functions can create any activity event
CREATE POLICY "System can create activity" ON public.activity_events
    FOR INSERT
    WITH CHECK (true);  -- Used by database triggers

-- Admins can view all activity
CREATE POLICY "Admins can view all activity" ON public.activity_events
    FOR SELECT
    USING (public.is_admin());

-- ============================================================================
-- LEADERBOARD ENTRIES TABLE POLICIES
-- Anyone can read; system updates
-- ============================================================================

-- Anyone can view leaderboard
CREATE POLICY "Anyone can view leaderboard" ON public.leaderboard_entries
    FOR SELECT
    USING (true);

-- System functions can update leaderboard
CREATE POLICY "System can update leaderboard" ON public.leaderboard_entries
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "System can upsert leaderboard" ON public.leaderboard_entries
    FOR UPDATE
    USING (true);

-- ============================================================================
-- PUSH NOTIFICATIONS TABLE POLICIES
-- Users can view own; system creates and updates
-- ============================================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON public.push_notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can create notifications
CREATE POLICY "System can create notifications" ON public.push_notifications
    FOR INSERT
    WITH CHECK (true);

-- System can update notification status
CREATE POLICY "System can update notifications" ON public.push_notifications
    FOR UPDATE
    USING (true);

COMMIT;
