import { LanguageAdapter } from "./types";

const HUMAN_TO_BIRD: Record<string, string> = {
  "hello": "chirp chirp", "hi": "tweet", "goodbye": "chirp tweet",
  "i love you": "whistle whistle", "love": "whistle", "food": "chirp chirp chirp",
  "hungry": "squawk squawk", "eat": "chirp", "play": "tweet tweet",
  "good": "trill trill", "bad": "squawk", "happy": "chirp tweet trill",
  "sad": "tweet mew", "sleep": "trill", "friend": "chirp chirp tweet",
  "water": "tweet chirp", "fly": "chirp tweet chirp", "sing": "whistle trill whistle",
  "morning": "chirp chirp chirp", "night": "trill trill",
};

const BIRD_TO_HUMAN: Record<string, string> = Object.fromEntries(
  Object.entries(HUMAN_TO_BIRD).map(([k, v]) => [v, k])
);

const SIMPLE_SOUNDS = ["chirp", "tweet", "whistle", "squawk", "trill"];

function generateSound(): string {
  return SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)];
}

export const birdAdapter: LanguageAdapter = {
  languageName: "Bird",
  simpleSounds: SIMPLE_SOUNDS,
  translateToAnimal(humanText: string): [string, number] {
    const normalized = humanText.toLowerCase().trim();
    if (HUMAN_TO_BIRD[normalized]) return [HUMAN_TO_BIRD[normalized], 1.0];
    const words = normalized.split(" ");
    const translated = words.map(w => HUMAN_TO_BIRD[w] || generateSound()).join(" ");
    const confidence = words.filter(w => HUMAN_TO_BIRD[w]).length / words.length;
    return [translated, confidence];
  },
  translateToHuman(animalText: string): [string, number] {
    const normalized = animalText.toLowerCase().trim();
    if (BIRD_TO_HUMAN[normalized]) return [BIRD_TO_HUMAN[normalized], 1.0];
    const sounds = normalized.split(" ");
    const translated = sounds.map(s => BIRD_TO_HUMAN[s] || "?").join(" ");
    const confidence = sounds.filter(s => BIRD_TO_HUMAN[s]).length / sounds.length;
    return [translated, confidence];
  },
  generateSimpleTranslation(wordCount: number): string {
    return Array.from({ length: wordCount }, () => SIMPLE_SOUNDS[Math.floor(Math.random() * SIMPLE_SOUNDS.length)]).join(" ");
  },
};
