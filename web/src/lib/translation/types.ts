export type TranslationDirection =
  | "human_to_dog" | "dog_to_human"
  | "human_to_cat" | "cat_to_human"
  | "human_to_bird" | "bird_to_human";

export type TranslationSource = "ai" | "vocabulary" | "simple";

export interface TranslationResult {
  inputText: string;
  outputText: string;
  direction: TranslationDirection;
  confidence: number;
  qualityScore: number | null;
  source: TranslationSource;
  timestamp: number;
}

export interface LanguageAdapter {
  languageName: string;
  simpleSounds: string[];
  translateToAnimal(humanText: string): [string, number];
  translateToHuman(animalText: string): [string, number];
  generateSimpleTranslation(wordCount: number): string;
}
