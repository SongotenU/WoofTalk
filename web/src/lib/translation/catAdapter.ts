import { LanguageAdapter } from "./types";

const HUMAN_TO_CAT: Record<string, string> = {
  "hello": "meow", "hi": "mew", "goodbye": "meow meow", "i love you": "purr purr",
  "love": "purr", "food": "meow meow meow", "hungry": "meow meow", "eat": "meow",
  "play": "mew mew", "good": "purr purr purr", "bad": "hiss", "stop": "hiss hiss",
  "come": "mrrp", "yes": "meow", "no": "hiss", "happy": "purr purr meow",
  "sad": "mew mew", "sleep": "purr", "friend": "mrrp mrrp", "water": "meow mew",
  "treat": "meow meow purr",
};

const CAT_TO_HUMAN: Record<string, string> = Object.fromEntries(
  Object.entries(HUMAN_TO_CAT).map(([k, v]) => [v, k])
);

const SIMPLE_SOUNDS = ["meow", "purr", "mew", "hiss", "mrrp"];

function generateSound(): string {
  return SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)];
}

export const catAdapter: LanguageAdapter = {
  languageName: "Cat",
  simpleSounds: SIMPLE_SOUNDS,
  translateToAnimal(humanText: string): [string, number] {
    const normalized = humanText.toLowerCase().trim();
    if (HUMAN_TO_CAT[normalized]) return [HUMAN_TO_CAT[normalized], 1.0];
    const words = normalized.split(" ");
    const translated = words.map(w => HUMAN_TO_CAT[w] || generateSound()).join(" ");
    const confidence = words.filter(w => HUMAN_TO_CAT[w]).length / words.length;
    return [translated, confidence];
  },
  translateToHuman(animalText: string): [string, number] {
    const normalized = animalText.toLowerCase().trim();
    if (CAT_TO_HUMAN[normalized]) return [CAT_TO_HUMAN[normalized], 1.0];
    const sounds = normalized.split(" ");
    const translated = sounds.map(s => CAT_TO_HUMAN[s] || "?").join(" ");
    const confidence = sounds.filter(s => CAT_TO_HUMAN[s]).length / sounds.length;
    return [translated, confidence];
  },
  generateSimpleTranslation(wordCount: number): string {
    return Array.from({ length: wordCount }, () => SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)]).join(" ");
  },
};
