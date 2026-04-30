"use client";

import { useCallback } from "react";
import { Share2 } from "lucide-react";

interface ShareButtonProps {
  text: string;
  sourceLang?: string;
  targetLang?: string;
}

export default function ShareButton({ text, sourceLang = "human", targetLang = "dog" }: ShareButtonProps) {
  const handleShare = useCallback(async () => {
    const shareData = {
      title: `WoofTalk Translation (${sourceLang} → ${targetLang})`,
      text: text,
      url: `https://wooftalk.app/translate?q=${encodeURIComponent(text)}&lang=${targetLang}`,
    };

    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (err: any) {
        if (err.name !== "AbortError") {
          console.error("Share failed:", err);
        }
      }
    } else {
      // Fallback: copy to clipboard
      try {
        await navigator.clipboard.writeText(text);
        alert("Copied to clipboard!");
      } catch {
        // Further fallback
        const textarea = document.createElement("textarea");
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand("copy");
        document.body.removeChild(textarea);
        alert("Copied to clipboard!");
      }
    }
  }, [text, sourceLang, targetLang]);

  return (
    <button
      onClick={handleShare}
      className="p-2 rounded-md hover:bg-secondary transition-colors"
      title="Share translation"
      aria-label="Share translation"
    >
      <Share2 className="w-4 h-4" />
    </button>
  );
}
