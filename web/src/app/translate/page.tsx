"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { translate, detectLanguage } from "@/lib/translation/engine";
import type { TranslationDirection, TranslationResult } from "@/lib/translation/types";
import { supabase, fetchTranslations, saveTranslation } from "@/lib/supabase";
import { VoiceInput } from "@/components/VoiceInput";
import { VoiceOutput } from "@/components/VoiceOutput";
import ShareButton from "@/components/ShareButton";
import { useKeyboardShortcuts } from "@/hooks/useKeyboardShortcuts";
import { subscribeToPush } from "@/lib/push";
import { getCachedTranslation, saveTranslationHistory, getTranslationHistory } from "@/lib/translation/indexeddb-history";
import { Bell } from "lucide-react";

export default function TranslatePage() {
  const [inputText, setInputText] = useState("");
  const [result, setResult] = useState<TranslationResult | null>(null);
  const [selectedLang, setSelectedLang] = useState<"dog" | "cat" | "bird">("dog");
  const [isTranslating, setIsTranslating] = useState(false);
  const [history, setHistory] = useState<TranslationResult[]>([]);
  const [notificationPerm, setNotificationPerm] = useState<NotificationPermission>("default");

  useKeyboardShortcuts();

  useEffect(() => {
    if ("Notification" in window) {
      setNotificationPerm(Notification.permission);
    }
    // Load history from IndexedDB
    getTranslationHistory(20).then(entries => {
      setHistory(entries.map(e => e.result));
    });
  }, []);

  const requestNotificationPermission = async () => {
    if (!("Notification" in window)) return;
    const permission = await Notification.requestPermission();
    setNotificationPerm(permission);
    if (permission === "granted") {
      await subscribeToPush();
    }
  };

  const handleVoiceResult = (transcript: string) => {
    setInputText(transcript);
  };

  const handleTranslate = async () => {
    if (!inputText.trim()) return;
    setIsTranslating(true);

    const direction = `human_to_${selectedLang}` as TranslationDirection;

    const cached = await getCachedTranslation(inputText, direction);
    if (cached) {
      setResult(cached);
      setHistory(prev => [cached, ...prev].slice(0, 20));
      setIsTranslating(false);
      return;
    }

    const translationResult = translate(inputText, direction);
    await saveTranslationHistory(inputText, direction, translationResult);
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
          <Link href="/" className="text-2xl font-bold text-primary">WoofTalk</Link>
          <div className="flex items-center gap-4">
            <Link href="/translate" className="text-primary font-medium">Translate</Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">History</Link>
            <Link href="/settings" className="text-muted-foreground hover:text-foreground">Settings</Link>
            {notificationPerm !== "granted" && "Notification" in window && (
              <button onClick={requestNotificationPermission} title="Enable notifications" className="text-muted-foreground hover:text-foreground">
                <Bell className="w-5 h-5" />
              </button>
            )}
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
            data-action="translate"
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
              <div className="flex items-center gap-2 ml-3">
                <ShareButton text={result.outputText} sourceLang="human" targetLang={selectedLang} />
                <VoiceOutput text={result.outputText} />
              </div>
            </div>
          </div>
        )}

        {history.length > 0 && (
          <div className="mt-8">
            <h2 className="text-lg font-semibold mb-4">Recent Translations</h2>
            <div className="space-y-2">
              {history.map((item, i) => (
                <div key={i} className="p-3 bg-card rounded border flex justify-between items-center">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm truncate">{item.inputText}</p>
                    <p className="text-sm text-primary truncate">{item.outputText}</p>
                  </div>
                  <div className="flex items-center gap-2 ml-2 shrink-0">
                    <span className="text-xs text-muted-foreground">
                      {(item.confidence * 100).toFixed(0)}%
                    </span>
                    <ShareButton text={item.outputText} targetLang={selectedLang} />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
