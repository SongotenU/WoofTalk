import { LanguageAdapter, TranslationDirection, TranslationResult, TranslationSource } from "./types";
import { dogAdapter } from "./dogAdapter";
import { catAdapter } from "./catAdapter";
import { birdAdapter } from "./birdAdapter";

const ADAPTERS: Record<string, LanguageAdapter> = {
  dog: dogAdapter,
  cat: catAdapter,
  bird: birdAdapter,
};

export function translate(text: string, direction: TranslationDirection): TranslationResult {
  const [sourceLang, targetLang] = direction.split("_to_");
  const adapter = ADAPTERS[targetLang];
  if (!adapter) throw new Error(`No adapter for language: ${targetLang}`);

  const [outputText, confidence] = direction.startsWith("human_")
    ? adapter.translateToAnimal(text)
    : adapter.translateToHuman(text);

  return {
    inputText: text,
    outputText,
    direction,
    confidence,
    qualityScore: null,
    source: confidence >= 0.5 ? "vocabulary" : "simple",
    timestamp: Date.now(),
  };
}

export function detectLanguage(text: string): string {
  const normalized = text.toLowerCase().trim();
  let bestMatch: [string, number] | null = null;

  for (const adapter of Object.values(ADAPTERS)) {
    const score = adapter.simpleSounds.filter(s => normalized.includes(s)).length / adapter.simpleSounds.length;
    if (score > 0 && (!bestMatch || score > bestMatch[1])) {
      bestMatch = [adapter.languageName, score];
    }
  }

  return (bestMatch?.[1] ?? 0) >= 0.3 ? bestMatch![0] : "human";
}

export function getSupportedLanguages(): string[] {
  return Object.keys(ADAPTERS);
}
