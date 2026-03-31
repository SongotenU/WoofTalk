"use client";

import { useState } from "react";
import Link from "next/link";
import { supabase, signOut } from "@/lib/supabase";

export default function SettingsPage() {
  const [darkMode, setDarkMode] = useState(false);
  const [aiEnabled, setAiEnabled] = useState(false);
  const [cacheSize, setCacheSize] = useState(1000);

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">🐾 WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">History</Link>
            <Link href="/settings" className="text-primary font-medium">Settings</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-2xl">
        <h1 className="text-2xl font-bold mb-8">Settings</h1>

        <div className="space-y-6">
          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Translation</h2>
            <div className="flex items-center justify-between">
              <span>AI Translation</span>
              <button
                onClick={() => setAiEnabled(!aiEnabled)}
                className={`w-12 h-6 rounded-full transition-colors ${aiEnabled ? 'bg-primary' : 'bg-muted'}`}
              >
                <div className={`w-5 h-5 bg-white rounded-full transition-transform ${aiEnabled ? 'translate-x-6' : 'translate-x-0.5'}`} />
              </button>
            </div>
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Appearance</h2>
            <div className="flex items-center justify-between">
              <span>Dark Mode</span>
              <button
                onClick={() => setDarkMode(!darkMode)}
                className={`w-12 h-6 rounded-full transition-colors ${darkMode ? 'bg-primary' : 'bg-muted'}`}
              >
                <div className={`w-5 h-5 bg-white rounded-full transition-transform ${darkMode ? 'translate-x-6' : 'translate-x-0.5'}`} />
              </button>
            </div>
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Cache</h2>
            <p className="text-sm text-muted-foreground mb-2">Cache size: {cacheSize} entries</p>
            <input
              type="range"
              min="100"
              max="5000"
              step="100"
              value={cacheSize}
              onChange={(e) => setCacheSize(Number(e.target.value))}
              className="w-full"
            />
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Account</h2>
            <button
              onClick={() => signOut()}
              className="w-full px-4 py-2 bg-destructive text-destructive-foreground rounded-lg hover:bg-destructive/90 transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
