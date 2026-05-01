"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { useEntitlementStore } from "@/lib/entitlement-store";

const CANCELLATION_REASONS = [
  "Too expensive",
  "Missing features I need",
  "Not using it enough",
  "Technical issues",
  "Switching to another app",
  "Temporary break",
  "Other",
];

export default function CancelSubscriptionPage() {
  const router = useRouter();
  const { isPremium } = useEntitlementStore();
  const [selectedReason, setSelectedReason] = useState("");
  const [feedback, setFeedback] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedReason) return;

    setIsSubmitting(true);
    setError("");

    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) throw new Error("Not authenticated");

      // Submit cancellation survey
      const { error: surveyError } = await supabase.from("cancellation_surveys").insert({
        user_id: user.id,
        reason: selectedReason,
        feedback: feedback || null,
      });

      if (surveyError) throw surveyError;

      // Update subscription_status
      const { error: statusError } = await supabase
        .from("subscription_status")
        .update({
          cancellation_reason: selectedReason,
          cancellation_feedback: feedback || null,
          cancelled_at: new Date().toISOString(),
        })
        .eq("user_id", user.id);

      if (statusError) throw statusError;

      // Redirect to manage subscription (Stripe portal or RevenueCat)
      router.push("/settings");
    } catch (err: any) {
      setError(err.message || "Failed to submit. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isPremium) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-xl font-semibold mb-4">No Active Subscription</h1>
          <Link href="/settings" className="text-primary hover:underline">
            Back to Settings
          </Link>
        </div>
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
        <h1 className="text-2xl font-semibold mb-2">Cancel Subscription</h1>
        <p className="text-muted-foreground mb-8">
          We&apos;re sorry to see you go. Please let us know why you&apos;re cancelling.
        </p>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="text-sm font-medium mb-3 block">Reason for cancelling</label>
            <div className="space-y-2">
              {CANCELLATION_REASONS.map((reason) => (
                <button
                  key={reason}
                  type="button"
                  onClick={() => setSelectedReason(reason)}
                  className={`w-full text-left px-4 py-3 rounded-lg border transition-colors ${
                    selectedReason === reason
                      ? "border-primary bg-primary/5"
                      : "border-border hover:bg-accent"
                  }`}
                >
                  {reason}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label htmlFor="feedback" className="text-sm font-medium mb-2 block">
              Additional feedback (optional)
            </label>
            <textarea
              id="feedback"
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-border bg-background min-h-[100px]"
              placeholder="Tell us how we can improve..."
            />
          </div>

          {error && <p className="text-sm text-destructive">{error}</p>}

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={!selectedReason || isSubmitting}
              className="flex-1 h-12 bg-destructive text-destructive-foreground rounded-lg hover:bg-destructive/90 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? "Submitting..." : "Submit & Cancel"}
            </button>
            <Link
              href="/settings"
              className="flex-1 h-12 flex items-center justify-center rounded-lg border border-border hover:bg-accent"
            >
              Keep Subscription
            </Link>
          </div>
        </form>
      </main>
    </div>
  );
}
