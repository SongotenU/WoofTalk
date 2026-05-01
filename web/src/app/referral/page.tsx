"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import Link from "next/link";

export default function ReferralPage() {
  const [referralCode, setReferralCode] = useState("");
  const [referralLink, setReferralLink] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [copied, setCopied] = useState(false);
  const [refereeCount, setRefereeCount] = useState(0);

  useEffect(() => {
    loadReferralData();
  }, []);

  const loadReferralData = async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;

      // Get or create referral code
      const { data: codes, error: codeError } = await supabase
        .from("referral_codes")
        .select("code")
        .eq("referrer_id", user.id)
        .eq("is_active", true)
        .single();

      if (codeError && codeError.code !== "PGRST116") throw codeError;

      let code = codes?.code;
      if (!code) {
        const { data: newCode, error: createError } = await supabase
          .rpc("generate_referral_code", { user_id: user.id })
          .single();
        if (createError) throw createError;
        code = newCode as string;
      }

      setReferralCode(code || "");
      setReferralLink(`${window.location.origin}/subscribe?ref=${code}`);

      // Count referrals
      const { count } = await supabase
        .from("referral_tracking")
        .select("*", { count: "exact", head: true })
        .eq("referral_code", code);

      setRefereeCount(count || 0);
    } catch (err: any) {
      setError(err.message || "Failed to load referral data");
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(referralLink);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
      const textArea = document.createElement("textarea");
      textArea.value = referralLink;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary">
            🐾 WoofTalk
          </Link>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-8 max-w-2xl">
        <h1 className="text-2xl font-semibold mb-2">Refer a Friend</h1>
        <p className="text-muted-foreground mb-8">
          Invite friends to WoofTalk and you both get 1 month free when they subscribe.
        </p>

        {error && (
          <div className="bg-destructive/10 text-destructive px-4 py-3 rounded-lg mb-6">
            {error}
          </div>
        )}

        <div className="bg-card rounded-lg border p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4">Your Referral Link</h2>
          <div className="flex gap-2">
            <input
              type="text"
              value={referralLink}
              readOnly
              className="flex-1 px-3 py-2 rounded-lg border border-border bg-background text-sm"
            />
            <button
              onClick={copyToClipboard}
              className="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm hover:bg-primary/90"
            >
              {copied ? "Copied!" : "Copy"}
            </button>
          </div>
          <p className="text-xs text-muted-foreground mt-2">
            Referral code: <span className="font-mono font-semibold">{referralCode}</span>
          </p>
        </div>

        <div className="bg-card rounded-lg border p-6">
          <h2 className="text-lg font-semibold mb-2">Your Referrals</h2>
          <p className="text-3xl font-bold">{refereeCount}</p>
          <p className="text-sm text-muted-foreground mt-1">
            friends referred
          </p>
        </div>

        <div className="mt-8 text-center">
          <Link href="/settings" className="text-sm text-muted-foreground hover:text-foreground">
            Back to Settings
          </Link>
        </div>
      </main>
    </div>
  );
}
