-- Migration 005: Migrate RLS Policies to Org-Scoped Variants
-- Preserves backward compatibility for consumer users (org_id IS NULL)
-- by keeping auth.uid() = user_id as the primary check branch.

-- ============================================================
-- translations
-- ============================================================
DROP POLICY IF EXISTS "Users can view own translations" ON public.translations;
DROP POLICY IF EXISTS "Users can insert own translations" ON public.translations;
DROP POLICY IF EXISTS "Users can update own translations" ON public.translations;
DROP POLICY IF EXISTS "Users can delete own translations" ON public.translations;

CREATE POLICY "Users can view own translations"
    ON public.translations FOR SELECT
    USING (
        auth.uid() = user_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = translations.org_id AND om.status = 'active'
        ))
    );

CREATE POLICY "Users can insert own translations"
    ON public.translations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own translations"
    ON public.translations FOR UPDATE
    USING (
        auth.uid() = user_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = translations.org_id AND om.status = 'active'
        ))
    )
    WITH CHECK (
        auth.uid() = user_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = translations.org_id AND om.status = 'active'
        ))
    );

CREATE POLICY "Users can delete own translations"
    ON public.translations FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================
-- community_phrases
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view community phrases" ON public.community_phrases;
DROP POLICY IF EXISTS "Authenticated users can create phrases" ON public.community_phrases;
DROP POLICY IF EXISTS "Users can update own phrases" ON public.community_phrases;
DROP POLICY IF EXISTS "Users can delete own phrases" ON public.community_phrases;

CREATE POLICY "Anyone can view community phrases"
    ON public.community_phrases FOR SELECT
    USING (
        org_id IS NULL
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = community_phrases.org_id AND om.status = 'active'
        ))
        -- Phrases are always readable by their creator
        OR auth.uid() = author_id
    );

CREATE POLICY "Authenticated users can create phrases"
    ON public.community_phrases FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own phrases"
    ON public.community_phrases FOR UPDATE
    USING (
        auth.uid() = author_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = community_phrases.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        ))
    )
    WITH CHECK (
        auth.uid() = author_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = community_phrases.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        ))
    );

CREATE POLICY "Users can delete own phrases"
    ON public.community_phrases FOR DELETE
    USING (
        auth.uid() = author_id
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = community_phrases.org_id AND om.role IN ('owner', 'admin') AND om.status = 'active'
        ))
    );

-- ============================================================
-- activity_events
-- ============================================================
DROP POLICY IF EXISTS "Users can view activity events" ON public.activity_events;
DROP POLICY IF EXISTS "Users can insert activity events" ON public.activity_events;
DROP POLICY IF EXISTS "Service role can manage activity events" ON public.activity_events;

CREATE POLICY "Users can view activity events"
    ON public.activity_events FOR SELECT
    USING (
        org_id IS NULL AND visibility = 'public'
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = activity_events.org_id AND om.status = 'active'
        ))
        OR auth.uid() = user_id
    );

CREATE POLICY "Users can insert activity events"
    ON public.activity_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- social_follows
-- ============================================================
DROP POLICY IF EXISTS "Users can view follows" ON public.social_follows;
DROP POLICY IF EXISTS "Users can manage own follows" ON public.social_follows;

CREATE POLICY "Users can view follows"
    ON public.social_follows FOR SELECT
    USING (true); -- Follows are public social graph data

CREATE POLICY "Users can manage own follows"
    ON public.social_follows FOR ALL
    USING (auth.uid() = follower_id)
    WITH CHECK (auth.uid() = follower_id);

-- ============================================================
-- social_likes
-- ============================================================
DROP POLICY IF EXISTS "Users can view likes" ON public.social_likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON public.social_likes;

CREATE POLICY "Users can view likes"
    ON public.social_likes FOR SELECT
    USING (true); -- Likes are public

CREATE POLICY "Users can manage own likes"
    ON public.social_likes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- social_comments
-- ============================================================
DROP POLICY IF EXISTS "Users can view comments" ON public.social_comments;
DROP POLICY IF EXISTS "Users can create comments" ON public.social_comments;
DROP POLICY IF EXISTS "Users can update own comments" ON public.social_comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.social_comments;

CREATE POLICY "Users can view comments"
    ON public.social_comments FOR SELECT
    USING (
        org_id IS NULL OR auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = social_comments.org_id AND om.status = 'active'
        )
        OR auth.uid() = author_id
    );

CREATE POLICY "Users can create comments"
    ON public.social_comments FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own comments"
    ON public.social_comments FOR UPDATE
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own comments"
    ON public.social_comments FOR DELETE
    USING (auth.uid() = author_id);

-- ============================================================
-- user_settings
-- ============================================================
DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON public.user_settings;

CREATE POLICY "Users can view own settings"
    ON public.user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON public.user_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
    ON public.user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- notification_preferences
-- ============================================================
DROP POLICY IF EXISTS "Users can view own notification prefs" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can update own notification prefs" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can insert own notification prefs" ON public.notification_preferences;

CREATE POLICY "Users can view own notification prefs"
    ON public.notification_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification prefs"
    ON public.notification_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification prefs"
    ON public.notification_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- leaderboard_entries
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view leaderboard" ON public.leaderboard_entries;

CREATE POLICY "Anyone can view leaderboard"
    ON public.leaderboard_entries FOR SELECT
    USING (
        org_id IS NULL
        OR (org_id IS NOT NULL AND auth.uid() IN (
            SELECT om.user_id FROM public.organization_members om
            WHERE om.org_id = leaderboard_entries.org_id AND om.status = 'active'
        ))
    );
