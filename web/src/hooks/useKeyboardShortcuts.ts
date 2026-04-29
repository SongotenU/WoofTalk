"use client";

import { useEffect } from "react";
export function useKeyboardShortcuts() {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      // Cmd/Ctrl + Enter: Translate
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        const translateBtn = document.querySelector("[data-action='translate']") as HTMLButtonElement;
        if (translateBtn && !translateBtn.disabled) translateBtn.click();
      }

      // Cmd/Ctrl + Shift + V: Toggle voice input
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === "V") {
        e.preventDefault();
        const voiceBtn = document.querySelector("[data-action='voice-toggle']") as HTMLButtonElement;
        if (voiceBtn) voiceBtn.click();
      }

      // Cmd/Ctrl + Shift + S: Go to Settings
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === "S") {
        e.preventDefault();
        window.location.href = "/settings";
      }

      // Cmd/Ctrl + Shift + H: Go to History
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === "H") {
        e.preventDefault();
        window.location.href = "/history";
      }

      // Escape: clear input if focused on textarea
      if (e.key === "Escape") {
        const textarea = document.activeElement as HTMLTextAreaElement;
        if (textarea && textarea.tagName === "TEXTAREA") {
          textarea.value = "";
          textarea.blur();
        }
      }
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);
}
