import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});

export async function signIn(email: string, password: string) {
  return supabase.auth.signInWithPassword({ email, password });
}

export async function signUp(email: string, password: string) {
  return supabase.auth.signUp({
    email,
    password,
    options: { data: { platform: 'web' } },
  });
}

export async function signOut() {
  return supabase.auth.signOut();
}

export async function fetchTranslations(userId: string, limit = 50, offset = 0) {
  return supabase
    .from('translations')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);
}

export async function saveTranslation(translation: {
  human_text: string;
  animal_text: string;
  source_language: string;
  target_language: string;
  confidence: number;
  quality_score: number | null;
  user_id: string;
}) {
  return supabase.from('translations').insert(translation);
}

export async function fetchCommunityPhrases(language?: string, limit = 50) {
  let query = supabase
    .from('community_phrases')
    .select('*')
    .eq('approval_status', 'approved')
    .order('upvotes', { ascending: false })
    .limit(limit);

  if (language) {
    query = query.eq('language', language);
  }

  return query;
}

export async function fetchCommunityPhrasesPaginated({
  language,
  search,
  sort = 'upvotes',
  limit = 20,
  offset = 0,
}: {
  language?: string;
  search?: string;
  sort?: 'upvotes' | 'newest' | 'trending';
  limit?: number;
  offset?: number;
}) {
  let query = supabase
    .from('community_phrases')
    .select('*', { count: 'exact' })
    .eq('approval_status', 'approved');

  if (language) {
    query = query.eq('language', language);
  }

  if (search) {
    query = query.or(`human_phrase.ilike.%${search}%,animal_response.ilike.%${search}%`);
  }

  switch (sort) {
    case 'newest':
      query = query.order('created_at', { ascending: false });
      break;
    case 'trending':
      query = query.order('created_at', { ascending: false }).order('upvotes', { ascending: false });
      break;
    default:
      query = query.order('upvotes', { ascending: false });
  }

  return query.range(offset, offset + limit - 1);
}

export async function submitCommunityPhrase(phrase: {
  humanPhrase: string;
  animalLanguage: string;
  animalResponse: string;
  context?: string;
  userId: string;
}) {
  return supabase.from('community_phrases').insert({
    human_phrase: phrase.humanPhrase,
    animal_response: phrase.animalResponse,
    language: phrase.animalLanguage,
    context: phrase.context,
    user_id: phrase.userId,
    approval_status: 'pending',
    upvotes: 0,
    downvotes: 0,
  });
}

export async function votePhrase({ phraseId, voteType, userId }: {
  phraseId: string;
  voteType: 'up' | 'down';
  userId: string;
}) {
  const column = voteType === 'up' ? 'upvotes' : 'downvotes';
  return supabase.rpc('increment_vote', { phrase_id: phraseId, vote_column: column });
}

export async function followUser({ followerId, followingId }: {
  followerId: string;
  followingId: string;
}) {
  return supabase.from('follow_relationships').insert({
    follower_id: followerId,
    following_id: followingId,
  });
}

export async function unfollowUser({ followerId, followingId }: {
  followerId: string;
  followingId: string;
}) {
  return supabase
    .from('follow_relationships')
    .delete()
    .eq('follower_id', followerId)
    .eq('following_id', followingId);
}

export async function getFollowers(userId: string) {
  return supabase
    .from('follow_relationships')
    .select('follower_id, users!follower_id(id, username, avatar_url)')
    .eq('following_id', userId);
}

export async function getFollowing(userId: string) {
  return supabase
    .from('follow_relationships')
    .select('following_id, users!following_id(id, username, avatar_url)')
    .eq('follower_id', userId);
}

export async function getLeaderboard(limit = 20) {
  return supabase
    .from('users')
    .select('id, username, avatar_url, phrase_count, total_upvotes')
    .order('total_upvotes', { ascending: false })
    .limit(limit);
}

export async function getActivityFeed(limit = 50) {
  return supabase
    .from('activity_events')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
}

export function subscribeToActivity(callback: (payload: unknown) => void) {
  return supabase
    .channel('activity_feed')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'activity_events' },
      callback
    )
    .subscribe();
}

export function subscribeToCommunityPhrases(callback: (payload: unknown) => void) {
  return supabase
    .channel('community_phrases')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'community_phrases' },
      callback
    )
    .subscribe();
}

export function subscribeToTranslations(callback: (payload: unknown) => void) {
  return supabase
    .channel('translations')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'translations' },
      callback
    )
    .subscribe();
}
