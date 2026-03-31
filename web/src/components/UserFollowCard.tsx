'use client';

import { useState } from 'react';
import { followUser, unfollowUser } from '@/lib/supabase';

interface UserFollowCardProps {
  user: {
    id: string;
    username: string;
    avatar_url?: string;
  };
  currentUserId: string;
  isFollowing: boolean;
  onFollowChange?: (userId: string, following: boolean) => void;
}

export function UserFollowCard({ user, currentUserId, isFollowing, onFollowChange }: UserFollowCardProps) {
  const [following, setFollowing] = useState(isFollowing);
  const [loading, setLoading] = useState(false);

  const handleToggle = async () => {
    if (loading) return;
    setLoading(true);

    setFollowing((prev) => !prev);

    try {
      if (following) {
        await unfollowUser({ followerId: currentUserId, followingId: user.id });
      } else {
        await followUser({ followerId: currentUserId, followingId: user.id });
      }
      onFollowChange?.(user.id, !following);
    } catch {
      setFollowing(following);
    }

    setLoading(false);
  };

  return (
    <div className="p-3 bg-card rounded-lg border flex items-center gap-3">
      <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center font-medium text-primary shrink-0">
        {user.username[0].toUpperCase()}
      </div>

      <div className="flex-1 min-w-0">
        <p className="font-medium truncate">{user.username}</p>
      </div>

      <button
        onClick={handleToggle}
        disabled={loading}
        className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
          following
            ? 'border border-primary text-primary hover:bg-primary/10'
            : 'bg-primary text-primary-foreground hover:bg-primary/90'
        }`}
      >
        {loading ? '...' : following ? 'Following' : 'Follow'}
      </button>
    </div>
  );
}
