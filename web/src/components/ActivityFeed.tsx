'use client';

interface ActivityFeedProps {
  activities: Array<{
    id: string;
    event_type: string;
    user_id: string;
    username?: string;
    description: string;
    created_at: string;
  }>;
  loading: boolean;
}

export function ActivityFeed({ activities, loading }: ActivityFeedProps) {
  if (loading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="p-4 bg-card rounded-lg border animate-pulse">
            <div className="h-4 bg-muted rounded w-3/4 mb-2" />
            <div className="h-3 bg-muted rounded w-1/4" />
          </div>
        ))}
      </div>
    );
  }

  if (activities.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">No activity yet</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {activities.map((activity) => (
        <div key={activity.id} className="p-4 bg-card rounded-lg border">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-sm font-medium text-primary shrink-0">
              {(activity.username ?? 'U')[0].toUpperCase()}
            </div>
            <div className="flex-1">
              <p className="text-sm">
                <span className="font-medium">{activity.username ?? 'User'}</span>{' '}
                {activity.description}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                {getTimeAgo(activity.created_at)}
              </p>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function getTimeAgo(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (seconds < 60) return 'just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}
