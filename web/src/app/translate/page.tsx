"use client";

import { useState } from "react";
import Link from "next/link";
import { translate, detectLanguage } from "@/lib/translation/engine";
import { translationCache } from "@/lib/translation/cache";
import type { TranslationDirection, TranslationResult } from "@/lib/translation/types";
import { supabase, fetchTranslations, saveTranslation } from "@/lib/supabase";
import { VoiceInput } from "@/components/VoiceInput";
import { VoiceOutput } from "@/components/VoiceOutput";

export default function TranslatePage() {
  const [inputText, setInputText] = useState("");
  const [result, setResult] = useState<TranslationResult | null>(null);
  const [selectedLang, setSelectedLang] = useState<"dog" | "cat" | "bird">("dog");
  const [isTranslating, setIsTranslating] = useState(false);
  const [history, setHistory] = useState<TranslationResult[]>([]);

  const handleVoiceResult = (transcript: string) => {
    setInputText(transcript);
  };

  const handleTranslate = async () => {
    if (!inputText.trim()) return;
    setIsTranslating(true);

    const direction = `human_to_${selectedLang}` as TranslationDirection;

    const cached = translationCache.get(inputText, direction);
    if (cached) {
      setResult(cached);
      setHistory(prev => [cached, ...prev].slice(0, 20));
      setIsTranslating(false);
      return;
    }

    const translationResult = translate(inputText, direction);
    translationCache.put(inputText, direction, translationResult);
    setResult(translationResult);
    setHistory(prev => [translationResult, ...prev].slice(0, 20));
    setIsTranslating(false);

    // Save to Supabase if authenticated
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await saveTranslation({
        human_text: translationResult.inputText,
        animal_text: translationResult.outputText,
        source_language: "human",
        target_language: selectedLang,
        confidence: translationResult.confidence,
        quality_score: translationResult.qualityScore,
        user_id: user.id,
      });
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-primary font-medium">Translate</Link>
            <Link href="/history" className="text-muted-foreground">History</Link>
            <Link href="/settings" className="text-muted-foreground">Settings</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-2xl">
        <div className="relative">
          <textarea
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="Enter text to translate..."
            className="w-full min-h-[120px] p-4 pr-16 border rounded-lg text-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary"
          />
          <div className="absolute right-3 top-3">
            <VoiceInput onResult={handleVoiceResult} />
          </div>
        </div>

        <div className="flex items-center justify-between mt-4">
          <div className="flex gap-2">
            {(["dog", "cat", "bird"] as const).map(lang => (
              <button
                key={lang}
                onClick={() => setSelectedLang(lang)}
                className={`px-4 py-2 rounded-full capitalize transition-colors ${
                  selectedLang === lang
                    ? "bg-primary text-primary-foreground"
                    : "bg-secondary text-secondary-foreground hover:bg-secondary/80"
                }`}
              >
                {lang}
              </button>
            ))}
          </div>

          <button
            onClick={handleTranslate}
            disabled={!inputText.trim() || isTranslating}
            className="px-6 py-2 bg-primary text-primary-foreground rounded-lg font-medium disabled:opacity-50 hover:bg-primary/90 transition-colors"
          >
            {isTranslating ? "Translating..." : "Translate"}
          </button>
        </div>

        {result && (
          <div className="mt-8 p-6 bg-card rounded-lg border">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <p className="text-sm text-muted-foreground mb-2">Translation:</p>
                <p className="text-2xl font-medium text-primary">{result.outputText}</p>
                <div className="flex gap-4 mt-4 text-sm text-muted-foreground">
                  <span>Confidence: {(result.confidence * 100).toFixed(0)}%</span>
                  <span>Source: {result.source}</span>
                </div>
              </div>
              <VoiceOutput text={result.outputText} />
            </div>
          </div>
        )}

        {history.length > 0 && (
          <div className="mt-8">
            <h2 className="text-lg font-semibold mb-4">Recent Translations</h2>
            <div className="space-y-2">
              {history.map((item, i) => (
                <div key={i} className="p-3 bg-card rounded border flex justify-between items-center">
                  <div>
                    <p className="text-sm">{item.inputText}</p>
                    <p className="text-sm text-primary">{item.outputText}</p>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {(item.confidence * 100).toFixed(0)}%
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
