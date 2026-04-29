"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { supabase, signOut } from "@/lib/supabase";
import { useSpeechSynthesis } from "@/hooks/useSpeechSynthesis";
import { useEntitlementStore } from "@/lib/entitlement-store";
import { useTheme } from "@/lib/theme-provider";
import { Sun, Moon, Monitor, Contrast } from "lucide-react";

export default function SettingsPage() {
  const [aiEnabled, setAiEnabled] = useState(false);
  const [cacheSize, setCacheSize] = useState(1000);
  const [voiceRate, setVoiceRate] = useState(1.0);
  const [voicePitch, setVoicePitch] = useState(1.0);
  const [highContrast, setHighContrast] = useState(false);
  const { speak } = useSpeechSynthesis();
  const { isPremium, isTrialActive } = useEntitlementStore();
  const { theme, toggleTheme, setTheme } = useTheme();

  useEffect(() => {
    const savedRate = localStorage.getItem('voiceRate');
    const savedPitch = localStorage.getItem('voicePitch');
    const savedContrast = localStorage.getItem('highContrast');
    if (savedRate) setVoiceRate(parseFloat(savedRate));
    if (savedPitch) setVoicePitch(parseFloat(savedPitch));
    if (savedContrast === 'true') {
      setHighContrast(true);
      document.documentElement.setAttribute('data-contrast', 'high');
    }
  }, []);

  const handleVoiceRateChange = (value: number) => {
    setVoiceRate(value);
    localStorage.setItem('voiceRate', value.toString());
  };

  const handleVoicePitchChange = (value: number) => {
    setVoicePitch(value);
    localStorage.setItem('voicePitch', value.toString());
  };

  const previewVoice = () => {
    speak("Hello", { rate: voiceRate, pitch: voicePitch });
  };

  const getThemeIcon = () => {
    if (theme === "dark") return <Moon className="w-4 h-4" />;
    if (theme === "light") return <Sun className="w-4 h-4" />;
    return <Monitor className="w-4 h-4" />;
  };

  const getThemeLabel = () => {
    if (theme === "dark") return "Dark";
    if (theme === "light") return "Light";
    return "System";
  };

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">WoofTalk</Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">History</Link>
            <Link href="/community" className="text-muted-foreground hover:text-foreground">Community</Link>
            <Link href="/social" className="text-muted-foreground hover:text-foreground">Social</Link>
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
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span>Theme</span>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">{getThemeLabel()}</span>
                  {getThemeIcon()}
                </div>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setTheme("light")}
                  className={`px-3 py-1.5 rounded-md text-sm transition-colors ${
                    theme === "light" ? "bg-primary text-primary-foreground" : "bg-secondary text-secondary-foreground hover:bg-secondary/80"
                  }`}
                >
                  <Sun className="w-3.5 h-3.5 inline mr-1" /> Light
                </button>
                <button
                  onClick={() => setTheme("dark")}
                  className={`px-3 py-1.5 rounded-md text-sm transition-colors ${
                    theme === "dark" ? "bg-primary text-primary-foreground" : "bg-secondary text-secondary-foreground hover:bg-secondary/80"
                  }`}
                >
                  <Moon className="w-3.5 h-3.5 inline mr-1" /> Dark
                </button>
                <button
                  onClick={() => setTheme("system")}
                  className={`px-3 py-1.5 rounded-md text-sm transition-colors ${
                    theme === "system" ? "bg-primary text-primary-foreground" : "bg-secondary text-secondary-foreground hover:bg-secondary/80"
                  }`}
                >
                  <Monitor className="w-3.5 h-3.5 inline mr-1" /> System
                </button>
              </div>
              <div className="flex items-center justify-between pt-3 border-t">
                <div className="flex items-center gap-2">
                  <Contrast className="w-4 h-4" />
                  <span>High Contrast</span>
                </div>
                <button
                  onClick={() => {
                    const next = !highContrast;
                    setHighContrast(next);
                    localStorage.setItem('highContrast', String(next));
                    if (next) {
                      document.documentElement.setAttribute('data-contrast', 'high');
                    } else {
                      document.documentElement.removeAttribute('data-contrast');
                    }
                  }}
                  className={`w-12 h-6 rounded-full transition-colors ${highContrast ? 'bg-primary' : 'bg-muted'}`}
                >
                  <div className={`w-5 h-5 bg-white rounded-full transition-transform ${highContrast ? 'translate-x-6' : 'translate-x-0.5'}`} />
                </button>
              </div>
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
            <h2 className="text-lg font-semibold mb-4">Voice</h2>
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm">Speed: {voiceRate.toFixed(1)}x</span>
                </div>
                <input
                  type="range"
                  min="0.5"
                  max="2"
                  step="0.1"
                  value={voiceRate}
                  onChange={(e) => handleVoiceRateChange(Number(e.target.value))}
                  className="w-full"
                />
              </div>
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm">Pitch: {voicePitch.toFixed(1)}</span>
                </div>
                <input
                  type="range"
                  min="0.5"
                  max="2"
                  step="0.1"
                  value={voicePitch}
                  onChange={(e) => handleVoicePitchChange(Number(e.target.value))}
                  className="w-full"
                />
              </div>
              <button
                onClick={previewVoice}
                className="px-4 py-2 bg-primary/10 text-primary rounded-lg hover:bg-primary/20 transition-colors text-sm"
              >
                Preview Voice
              </button>
            </div>
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

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Subscription</h2>
            {isPremium && !isTrialActive ? (
              <div className="space-y-3">
                <p className="text-primary font-medium">Pro plan active</p>
                <div className="flex gap-2">
                  <a
                    href="https://billing.stripe.com/p/login"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-muted-foreground hover:text-primary transition-colors"
                  >
                    Manage Subscription
                  </a>
                  <span className="text-muted-foreground">|</span>
                  <Link href="/settings/cancel" className="text-sm text-destructive hover:underline">
                    Cancel
                  </Link>
                </div>
                <div className="pt-3 border-t">
                  <Link href="/referral" className="text-sm text-primary hover:underline">
                    Refer a Friend
                  </Link>
                </div>
              </div>
            ) : isTrialActive ? (
              <div className="space-y-3">
                <p className="text-muted-foreground">Trial active</p>
                <a
                  href="https://billing.stripe.com/p/login"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-muted-foreground hover:text-primary transition-colors"
                >
                  Manage Subscription
                </a>
                <div className="pt-3 border-t">
                  <Link href="/referral" className="text-sm text-primary hover:underline">
                    Refer a Friend
                  </Link>
                </div>
              </div>
            ) : (
              <Link href="/subscribe" className="text-primary hover:underline">
                View Plans
              </Link>
            )}
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Restore Purchases</h2>
            <button
              onClick={async () => {
                try {
                  const { restorePurchases } = await import('@/lib/purchases-web');
                  await restorePurchases();
                  alert('Purchases restored successfully!');
                } catch {
                  alert('Failed to restore purchases. Please try again.');
                }
              }}
              className="px-4 py-2 bg-primary/10 text-primary rounded-lg hover:bg-primary/20 transition-colors text-sm"
            >
              Restore Purchases
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
