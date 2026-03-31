"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { fetchTranslations } from "@/lib/supabase";
import { supabase } from "@/lib/supabase";

export default function HistoryPage() {
  const [translations, setTranslations] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadTranslations();
  }, []);

  async function loadTranslations() {
    setIsLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data } = await fetchTranslations(user.id);
      if (data) setTranslations(data);
    }
    setIsLoading(false);
  }

  const filtered = translations.filter(t =>
    searchQuery === "" ||
    (t.human_text || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
    (t.animal_text || "").toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/history" className="text-primary font-medium">History</Link>
            <Link href="/settings" className="text-muted-foreground hover:text-foreground">Settings</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-2xl">
        <h1 className="text-2xl font-bold mb-6">Translation History</h1>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search translations..."
          className="w-full p-3 border rounded-lg mb-6 focus:outline-none focus:ring-2 focus:ring-primary"
        />

        {isLoading ? (
          <div className="text-center py-8">Loading...</div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">No translations found</div>
        ) : (
          <div className="space-y-3">
            {filtered.map((t, i) => (
              <div key={i} className="p-4 bg-card rounded-lg border">
                <p className="text-sm">{t.human_text}</p>
                <p className="text-sm text-primary mt-1">{t.animal_text}</p>
                <div className="flex gap-4 mt-2 text-xs text-muted-foreground">
                  <span>{t.source_language} → {t.target_language}</span>
                  <span>{t.confidence ? Math.round(t.confidence * 100) : 0}%</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
