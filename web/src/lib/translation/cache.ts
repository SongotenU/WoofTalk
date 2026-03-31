import { TranslationDirection, TranslationResult } from "./types";

interface CacheEntry {
  result: TranslationResult;
  timestamp: number;
}

export class TranslationCache {
  private cache = new Map<string, CacheEntry>();
  private order: string[] = [];

  constructor(
    private maxSize: number = 1000,
    private ttlMs: number = 24 * 60 * 60 * 1000
  ) {}

  private key(text: string, direction: TranslationDirection): string {
    return `${text.toLowerCase().trim()}_${direction}`;
  }

  get(text: string, direction: TranslationDirection): TranslationResult | null {
    const k = this.key(text, direction);
    const entry = this.cache.get(k);
    if (!entry) return null;
    if (Date.now() - entry.timestamp > this.ttlMs) {
      this.cache.delete(k);
      this.order = this.order.filter(o => o !== k);
      return null;
    }
    return entry.result;
  }

  put(text: string, direction: TranslationDirection, result: TranslationResult): void {
    const k = this.key(text, direction);
    if (this.cache.has(k)) {
      this.order = this.order.filter(o => o !== k);
    }
    this.cache.set(k, { result, timestamp: Date.now() });
    this.order.push(k);
    while (this.cache.size > this.maxSize) {
      const oldest = this.order.shift()!;
      this.cache.delete(oldest);
    }
  }

  clear(): void {
    this.cache.clear();
    this.order = [];
  }

  get size(): number { return this.cache.size; }
}

export const translationCache = new TranslationCache();
