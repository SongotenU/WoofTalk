import { LanguageAdapter } from "./types";

const HUMAN_TO_DOG: Record<string, string> = {
  "hello": "woof woof", "hi": "woof", "goodbye": "arf arf arf", "bye": "arf arf",
  "i love you": "woof woof woof", "love": "woof woof", "food": "bark bark",
  "hungry": "bark bark bark", "eat": "bark", "play": "woof arf woof",
  "walk": "woof woof arf", "good boy": "woof woof woof", "bad": "grrr",
  "stop": "grrr grrr", "sit": "arf", "stay": "ruff ruff", "come": "woof arf",
  "yes": "woof", "no": "grr", "thank you": "woof woof arf", "please": "woof arf",
  "friend": "woof woof woof", "happy": "woof woof arf arf", "sad": "whine whine",
  "help": "bark bark bark", "water": "arf woof", "sleep": "ruff",
  "outside": "woof woof bark", "inside": "arf ruff", "treat": "bark bark woof",
};

const DOG_TO_HUMAN: Record<string, string> = Object.fromEntries(
  Object.entries(HUMAN_TO_DOG).map(([k, v]) => [v, k])
);

const SIMPLE_SOUNDS = ["woof", "bark", "arf", "ruff", "bow-wow"];

function generateSound(): string {
  return SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)];
}

export const dogAdapter: LanguageAdapter = {
  languageName: "Dog",
  simpleSounds: SIMPLE_SOUNDS,
  translateToAnimal(humanText: string): [string, number] {
    const normalized = humanText.toLowerCase().trim();
    if (HUMAN_TO_DOG[normalized]) return [HUMAN_TO_DOG[normalized], 1.0];
    const words = normalized.split(" ");
    const translated = words.map(w => HUMAN_TO_DOG[w] || generateSound()).join(" ");
    const confidence = words.filter(w => HUMAN_TO_DOG[w]).length / words.length;
    return [translated, confidence];
  },
  translateToHuman(animalText: string): [string, number] {
    const normalized = animalText.toLowerCase().trim();
    if (DOG_TO_HUMAN[normalized]) return [DOG_TO_HUMAN[normalized], 1.0];
    const sounds = normalized.split(" ");
    const translated = sounds.map(s => DOG_TO_HUMAN[s] || "?").join(" ");
    const confidence = sounds.filter(s => DOG_TO_HUMAN[s]).length / sounds.length;
    return [translated, confidence];
  },
  generateSimpleTranslation(wordCount: number): string {
    return Array.from({ length: wordCount }, () => SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)]).join(" ");
  },
};
