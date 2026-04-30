"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { supabase, signOut } from "@/lib/supabase";
import { useSpeechSynthesis } from "@/hooks/useSpeechSynthesis";
import { useEntitlementStore } from "@/lib/entitlement-store";
import { useTheme } from "@/lib/theme-provider";
import { Sun, Moon, Monitor } from "lucide-react";

export default function SettingsPage() {
  const [aiEnabled, setAiEnabled] = useState(false);
  const [cacheSize, setCacheSize] = useState(1000);
  const [voiceRate, setVoiceRate] = useState(1.0);
  const [voicePitch, setVoicePitch] = useState(1.0);
  const { speak } = useSpeechSynthesis();
  const { isPremium, isTrialActive, isAuthenticated, setAuthenticated } = useEntitlementStore();
  const { theme, toggleTheme, setTheme } = useTheme();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [signInError, setSignInError] = useState<string | null>(null);
  const [signingIn, setSigningIn] = useState(false);

  useEffect(() => {
    const savedRate = localStorage.getItem("voiceRate");
    const savedPitch = localStorage.getItem("voicePitch");
    if (savedRate) setVoiceRate(parseFloat(savedRate));
    if (savedPitch) setVoicePitch(parseFloat(savedPitch));

    // Check auth state on load
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setAuthenticated(!!session?.user);
    };
    checkAuth();

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      setAuthenticated(!!session?.user);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [setAuthenticated]);

  const handleVoiceRateChange = (value: number) => {
    setVoiceRate(value);
    localStorage.setItem("voiceRate", value.toString());
  };

  const handleVoicePitchChange = (value: number) => {
    setVoicePitch(value);
    localStorage.setItem("voicePitch", value.toString());
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

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setSignInError(null);
    setSigningIn(true);

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw error;
      }

      setAuthenticated(true);
    } catch (err: any) {
      setSignInError(err.message || "Failed to sign in");
    } finally {
      setSigningIn(false);
    }
  };

  // Show sign-in form if not authenticated
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-background">
        <nav className="border-b">
          <div className="container mx-auto px-4 py-4 flex items-center justify-between">
            <Link href="/" className="text-2xl font-bold text-primary">
              WoofTalk
            </Link>
            <div className="flex gap-4">
              <Link href="/translate" className="text-muted-foreground hover:text-foreground">
                Translate
              </Link>
              <Link href="/history" className="text-muted-foreground hover:text-foreground">
                History
              </Link>
              <Link href="/community" className="text-muted-foreground hover:text-foreground">
                Community
              </Link>
              <Link href="/social" className="text-muted-foreground hover:text-foreground">
                Social
              </Link>
              <Link href="/settings" className="text-primary font-medium">
                Settings
              </Link>
            </div>
          </div>
        </nav>

        <main className="container mx-auto px-4 py-8 max-w-md">
          <div className="bg-card rounded-2xl border p-8 shadow-lg">
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold mb-2">Welcome Back</h1>
              <p className="text-muted-foreground">Sign in to access WoofTalk</p>
            </div>

            <form onSubmit={handleSignIn} className="space-y-4">
              {signInError && (
                <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded-lg text-sm">
                  {signInError}
                </div>
              )}

              <div>
                <label htmlFor="signin-email" className="block text-sm font-medium mb-2">
                  Email
                </label>
                <input
                  id="signin-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  required
                  className="w-full px-4 py-3 rounded-xl border border-input bg-background focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                  disabled={signingIn}
                />
              </div>

              <div>
                <label htmlFor="signin-password" className="block text-sm font-medium mb-2">
                  Password
                </label>
                <input
                  id="signin-password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  required
                  className="w-full px-4 py-3 rounded-xl border border-input bg-background focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                  disabled={signingIn}
                />
              </div>

              <button
                type="submit"
                disabled={signingIn}
                className="w-full bg-primary text-primary-foreground font-semibold py-3 rounded-xl hover:bg-primary/90 transition-all duration-200 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              >
                {signingIn ? "Signing In..." : "Sign In"}
              </button>
            </form>

            <p className="text-center text-sm text-muted-foreground mt-6">
              Need an account?{" "}
              <a
                href="https://app.supabase.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline font-medium"
              >
                Contact support
              </a>
            </p>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">
            WoofTalk
          </Link>
          <div className="flex gap-4">
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">
              Translate
            </Link>
            <Link href="/history" className="text-muted-foreground hover:text-foreground">
              History
            </Link>
            <Link href="/community" className="text-muted-foreground hover:text-foreground">
              Community
            </Link>
            <Link href="/social" className="text-muted-foreground hover:text-foreground">
              Social
            </Link>
            <Link href="/settings" className="text-primary font-medium">
              Settings
            </Link>
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
                className={`w-12 h-6 rounded-full transition-colors ${
                  aiEnabled ? "bg-primary" : "bg-muted"
                }`}
              >
                <div
                  className={`w-5 h-5 bg-white rounded-full transition-transform ${
                    aiEnabled ? "translate-x-6" : "translate-x-0.5"
                  }`}
                />
              </button>
            </div>
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Voice Settings</h2>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between mb-2">
                  <span>Voice Rate</span>
                  <span className="text-sm text-muted-foreground">{voiceRate}x</span>
                </div>
                <input
                  type="range"
                  min="0.5"
                  max="2"
                  step="0.1"
                  value={voiceRate}
                  onChange={(e) => handleVoiceRateChange(parseFloat(e.target.value))}
                  className="w-full"
                />
              </div>

              <div>
                <div className="flex justify-between mb-2">
                  <span>Voice Pitch</span>
                  <span className="text-sm text-muted-foreground">{voicePitch}</span>
                </div>
                <input
                  type="range"
                  min="0.5"
                  max="2"
                  step="0.1"
                  value={voicePitch}
                  onChange={(e) => handleVoicePitchChange(parseFloat(e.target.value))}
                  className="w-full"
                />
              </div>

              <button
                onClick={previewVoice}
                className="w-full px-4 py-2 bg-primary/10 text-primary rounded-lg hover:bg-primary/20 transition-colors"
              >
                Preview Voice
              </button>
            </div>
          </div>

          <div className="p-4 bg-card rounded-lg border">
            <h2 className="text-lg font-semibold mb-4">Display</h2>
            <div className="flex items-center justify-between">
              <span>Theme</span>
              <div className="flex gap-1">
                <button
                  onClick={() => setTheme("light")}
                  className={`p-2 rounded-lg transition-colors ${
                    theme === "light" ? "bg-primary text-primary-foreground" : "hover:bg-muted"
                  }`}
                >
                  <Sun className="w-4 h-4" />
                  <span className="sr-only">Light</span>
                </button>
                <button
                  onClick={() => setTheme("dark")}
                  className={`p-2 rounded-lg transition-colors ${
                    theme === "dark" ? "bg-primary text-primary-foreground" : "hover:bg-muted"
                  }`}
                >
                  <Moon className="w-4 h-4" />
                  <span className="sr-only">Dark</span>
                </button>
                <button
                  onClick={() => setTheme("system")}
                  className={`p-2 rounded-lg transition-colors ${
                    theme === "system" ? "bg-primary text-primary-foreground" : "hover:bg-muted"
                  }`}
                >
                  <Monitor className="w-4 h-4" />
                  <span className="sr-only">System</span>
                </button>
              </div>
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
                  const { restorePurchases } = await import("@/lib/purchases-web");
                  await restorePurchases();
                  alert("Purchases restored successfully!");
                } catch {
                  alert("Failed to restore purchases. Please try again.");
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
