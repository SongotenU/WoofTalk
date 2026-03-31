'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { fetchCommunityPhrasesPaginated, supabase, subscribeToCommunityPhrases } from '@/lib/supabase';
import { PhraseCard } from '@/components/PhraseCard';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { ContributePhraseModal } from '@/components/ContributePhraseModal';

interface CommunityPhrase {
  id: string;
  human_phrase: string;
  animal_response: string;
  language: string;
  approval_status: string;
  upvotes: number;
  downvotes: number;
  user_id: string;
  created_at: string;
}

export default function CommunityPage() {
  const [phrases, setPhrases] = useState<CommunityPhrase[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [language, setLanguage] = useState<string | undefined>();
  const [sort, setSort] = useState<'upvotes' | 'newest' | 'trending'>('upvotes');
  const [showModal, setShowModal] = useState(false);
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUserId(user?.id ?? null);
    });
  }, []);

  const loadPhrases = useCallback(async () => {
    setLoading(true);
    const { data, error } = await fetchCommunityPhrasesPaginated({
      language,
      search: search || undefined,
      sort,
      limit: 30,
      offset: 0,
    });
    if (data && !error) {
      setPhrases(data as CommunityPhrase[]);
    }
    setLoading(false);
  }, [language, search, sort]);

  useEffect(() => {
    loadPhrases();
  }, [loadPhrases]);

  useEffect(() => {
    const channel = subscribeToCommunityPhrases(() => {
      loadPhrases();
    });
    return () => {
      supabase.removeChannel(channel);
    };
  }, [loadPhrases]);

  const handleSearch = (value: string) => {
    setSearch(value);
  };

  const handleFilter = (lang?: string) => {
    setLanguage(lang);
  };

  const handleSort = (value: 'upvotes' | 'newest' | 'trending') => {
    setSort(value);
  };

  const handleSubmit = () => {
    setShowModal(true);
  };

  const handlePhraseSubmitted = () => {
    setShowModal(false);
    loadPhrases();
  };

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">History</Link>
            <Link href="/community" className="text-primary font-medium">Community</Link>
            <Link href="/social" className="text-muted-foreground hover:text-foreground">Social</Link>
            <Link href="/settings" className="text-muted-foreground hover:text-foreground">Settings</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-5xl">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">Community Phrases</h1>
          <button
            onClick={handleSubmit}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-lg font-medium hover:bg-primary/90 transition-colors"
          >
            Contribute Phrase
          </button>
        </div>

        <SearchFilterBar
          search={search}
          language={language}
          sort={sort}
          onSearch={handleSearch}
          onFilter={handleFilter}
          onSort={handleSort}
        />

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="p-4 bg-card rounded-lg border animate-pulse">
                <div className="h-4 bg-muted rounded w-3/4 mb-2" />
                <div className="h-3 bg-muted rounded w-1/2 mb-4" />
                <div className="h-3 bg-muted rounded w-2/3" />
              </div>
            ))}
          </div>
        ) : phrases.length === 0 ? (
          <div className="text-center py-16">
            <p className="text-lg text-muted-foreground mb-4">
              No phrases found — be the first to contribute!
            </p>
            <button
              onClick={handleSubmit}
              className="px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
            >
              Contribute Phrase
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
            {phrases.map((phrase) => (
              <PhraseCard
                key={phrase.id}
                phrase={phrase}
                onVote={() => {}}
              />
            ))}
          </div>
        )}
      </main>

      {showModal && userId && (
        <ContributePhraseModal
          userId={userId}
          onClose={() => setShowModal(false)}
          onSubmitted={handlePhraseSubmitted}
        />
      )}
    </div>
  );
}
