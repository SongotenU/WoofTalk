'use client';

interface LeaderboardProps {
  users: Array<{
    id: string;
    username: string;
    avatar_url?: string;
    phrase_count: number;
    total_upvotes: number;
  }>;
  loading: boolean;
}

const medals = ['🥇', '🥈', '🥉'];

export function Leaderboard({ users, loading }: LeaderboardProps) {
  if (loading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="p-4 bg-card rounded-lg border animate-pulse flex items-center gap-4">
            <div className="h-8 w-8 bg-muted rounded-full" />
            <div className="flex-1">
              <div className="h-4 bg-muted rounded w-1/3 mb-2" />
              <div className="h-3 bg-muted rounded w-1/4" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (users.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">No contributors yet</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {users.map((user, index) => (
        <div
          key={user.id}
          className={`p-4 bg-card rounded-lg border flex items-center gap-4 ${
            index < 3 ? 'bg-primary/5 border-primary/20' : ''
          }`}
        >
          <div className="w-8 text-center text-lg">
            {index < 3 ? medals[index] : <span className="text-muted-foreground text-sm">#{index + 1}</span>}
          </div>

          <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center font-medium text-primary">
            {user.username[0].toUpperCase()}
          </div>

          <div className="flex-1">
            <p className="font-medium">{user.username}</p>
            <p className="text-xs text-muted-foreground">
              {user.phrase_count ?? 0} phrases
            </p>
          </div>

          <div className="text-right">
            <p className="font-medium text-primary">{user.total_upvotes ?? 0}</p>
            <p className="text-xs text-muted-foreground">upvotes</p>
          </div>
        </div>
      ))}
    </div>
  );
}
