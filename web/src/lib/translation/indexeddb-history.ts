"use client";

import { TranslationDirection, TranslationResult } from "./types";

const DB_NAME = "wooftalk-db";
const STORE_NAME = "translation-history";
const DB_VERSION = 1;
const MAX_HISTORY = 1000;

interface HistoryEntry {
  id?: number;
  text: string;
  direction: TranslationDirection;
  result: TranslationResult;
  timestamp: number;
}

function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: "id", autoIncrement: true });
        store.createIndex("direction", "direction", { unique: false });
        store.createIndex("timestamp", "timestamp", { unique: false });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function saveTranslationHistory(
  text: string,
  direction: TranslationDirection,
  result: TranslationResult
): Promise<void> {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, "readwrite");
  const store = tx.objectStore(STORE_NAME);

  await new Promise<void>((resolve, reject) => {
    const addReq = store.add({
      text: text.toLowerCase().trim(),
      direction,
      result,
      timestamp: Date.now(),
    });
    addReq.onsuccess = () => resolve();
    addReq.onerror = () => reject(addReq.error);
  });

  // Evict oldest entries if over limit
  const countReq = store.count();
  countReq.onsuccess = () => {
    const count = countReq.result;
    if (count > MAX_HISTORY) {
      const index = store.index("timestamp");
      const toDelete = count - MAX_HISTORY;
      let deleted = 0;
      index.openCursor().onsuccess = (e: any) => {
        const cursor = e.target.result;
        if (cursor && deleted < toDelete) {
          cursor.delete();
          deleted++;
          cursor.continue();
        }
      };
    }
  };

  await new Promise<void>((resolve) => {
    tx.oncomplete = () => resolve();
  });
}

export async function getTranslationHistory(limit = 50): Promise<HistoryEntry[]> {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, "readonly");
  const store = tx.objectStore(STORE_NAME);
  const index = store.index("timestamp");

  return new Promise((resolve) => {
    const results: HistoryEntry[] = [];
    index.openCursor(null, "prev").onsuccess = (e: any) => {
      const cursor = e.target.result;
      if (cursor && results.length < limit) {
        results.push(cursor.value);
        cursor.continue();
      } else {
        resolve(results);
      }
    };
  });
}

export async function clearTranslationHistory(): Promise<void> {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, "readwrite");
  const store = tx.objectStore(STORE_NAME);
  await new Promise<void>((resolve, reject) => {
    const req = store.clear();
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

export async function getCachedTranslation(
  text: string,
  direction: TranslationDirection
): Promise<TranslationResult | null> {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, "readonly");
  const store = tx.objectStore(STORE_NAME);
  const index = store.index("timestamp");

  return new Promise((resolve) => {
    const key = text.toLowerCase().trim();
    const ttlMs = 24 * 60 * 60 * 1000;
    let found: TranslationResult | null = null;

    index.openCursor(null, "prev").onsuccess = (e: any) => {
      const cursor = e.target.result;
      if (cursor) {
        const entry = cursor.value;
        if (entry.text === key && entry.direction === direction) {
          if (Date.now() - entry.timestamp < ttlMs) {
            found = entry.result;
          }
        }
        cursor.continue();
      } else {
        resolve(found);
      }
    };
  });
}
