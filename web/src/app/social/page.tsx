'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { supabase, getActivityFeed, getLeaderboard, subscribeToActivity } from '@/lib/supabase';
import { ActivityFeed } from '@/components/ActivityFeed';
import { Leaderboard } from '@/components/Leaderboard';

type Tab = 'activity' | 'leaderboard';

export default function SocialPage() {
  const [activeTab, setActiveTab] = useState<Tab>('activity');
  const [userId, setUserId] = useState<string | null>(null);
  const [activities, setActivities] = useState<Array<{
    id: string;
    event_type: string;
    user_id: string;
    username?: string;
    description: string;
    created_at: string;
  }>>([]);
  const [leaderboard, setLeaderboard] = useState<Array<{
    id: string;
    username: string;
    avatar_url?: string;
    phrase_count: number;
    total_upvotes: number;
  }>>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUserId(user?.id ?? null);
    });
  }, []);

  const loadData = useCallback(async () => {
    setLoading(true);

    const [activityRes, leaderboardRes] = await Promise.all([
      getActivityFeed(),
      getLeaderboard(),
    ]);

    if (activityRes.data) {
      setActivities(activityRes.data);
    }
    if (leaderboardRes.data) {
      setLeaderboard(leaderboardRes.data);
    }

    setLoading(false);
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    const channel = subscribeToActivity(() => {
      loadData();
    });
    return () => {
      supabase.removeChannel(channel);
    };
  }, [loadData]);

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">History</Link>
            <Link href="/community" className="text-muted-foreground hover:text-foreground">Community</Link>
            <Link href="/social" className="text-primary font-medium">Social</Link>
            <Link href="/settings" className="text-muted-foreground hover:text-foreground">Settings</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-3xl">
        <h1 className="text-2xl font-bold mb-6">Social</h1>

        <div className="flex gap-2 mb-6 border-b">
          {([
            { key: 'activity' as Tab, label: 'Activity Feed' },
            { key: 'leaderboard' as Tab, label: 'Leaderboard' },
          ]).map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab.key
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {activeTab === 'activity' && (
          <ActivityFeed activities={activities} loading={loading} />
        )}

        {activeTab === 'leaderboard' && (
          <Leaderboard users={leaderboard} loading={loading} />
        )}
      </main>
    </div>
  );
}
