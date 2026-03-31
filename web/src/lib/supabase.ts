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
