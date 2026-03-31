import { supabase } from './supabase';

export function setupRealtimeSync(callbacks: {
  onTranslation?: (payload: unknown) => void;
  onCommunityPhrase?: (payload: unknown) => void;
  onActivity?: (payload: unknown) => void;
}) {
  const channels: ReturnType<typeof supabase.channel>[] = [];

  if (callbacks.onTranslation) {
    const channel = supabase
      .channel('translations')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'translations' },
        callbacks.onTranslation
      )
      .subscribe();
    channels.push(channel);
  }

  if (callbacks.onCommunityPhrase) {
    const channel = supabase
      .channel('community_phrases')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'community_phrases' },
        callbacks.onCommunityPhrase
      )
      .subscribe();
    channels.push(channel);
  }

  if (callbacks.onActivity) {
    const channel = supabase
      .channel('activity_events')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'activity_events' },
        callbacks.onActivity
      )
      .subscribe();
    channels.push(channel);
  }

  return {
    unsubscribe: () => {
      channels.forEach((channel) => supabase.removeChannel(channel));
    },
  };
}
