'use client';

const languageEmojis: Record<string, string> = {
  dog: '🐕',
  cat: '🐈',
  bird: '🐦',
};

interface PhraseCardProps {
  phrase: {
    id: string;
    human_phrase: string;
    animal_response: string;
    language: string;
    upvotes: number;
    downvotes: number;
    user_id: string;
    created_at: string;
  };
  onVote: (phraseId: string, voteType: 'up' | 'down') => void;
}

export function PhraseCard({ phrase, onVote }: PhraseCardProps) {
  const emoji = languageEmojis[phrase.language] || '🐾';
  const timeAgo = getTimeAgo(phrase.created_at);

  return (
    <div className="p-4 bg-card rounded-lg border hover:shadow-md transition-shadow">
      <div className="flex items-center gap-2 mb-2">
        <span className="text-lg">{emoji}</span>
        <span className="text-xs text-muted-foreground capitalize">{phrase.language}</span>
        <span className="text-xs text-muted-foreground ml-auto">{timeAgo}</span>
      </div>

      <div className="mb-3">
        <p className="text-sm font-medium">"{phrase.human_phrase}"</p>
        <p className="text-sm text-primary mt-1">→ "{phrase.animal_response}"</p>
      </div>

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => onVote(phrase.id, 'up')}
            className="flex items-center gap-1 text-xs text-muted-foreground hover:text-primary transition-colors"
            aria-label="Upvote"
          >
            ▲ {phrase.upvotes}
          </button>
          <button
            onClick={() => onVote(phrase.id, 'down')}
            className="flex items-center gap-1 text-xs text-muted-foreground hover:text-destructive transition-colors"
            aria-label="Downvote"
          >
            ▼ {phrase.downvotes}
          </button>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => navigator.clipboard?.writeText(`${phrase.human_phrase} → ${phrase.animal_response}`)}
            className="text-xs text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Copy to clipboard"
          >
            📋
          </button>
        </div>
      </div>
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
