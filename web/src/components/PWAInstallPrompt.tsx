"use client";

import { useState, useEffect, useCallback } from "react";
import { X, Download } from "lucide-react";

export default function PWAInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [showPrompt, setShowPrompt] = useState(false);

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e);
      setShowPrompt(true);
    };
    window.addEventListener("beforeinstallprompt", handler);

    // Hide if already installed
    window.addEventListener("appinstalled", () => {
      setShowPrompt(false);
      setDeferredPrompt(null);
    });

    return () => {
      window.removeEventListener("beforeinstallprompt", handler);
    };
  }, []);

  const handleInstall = useCallback(async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === "accepted") {
      setShowPrompt(false);
      setDeferredPrompt(null);
    }
  }, [deferredPrompt]);

  const handleDismiss = useCallback(() => {
    setShowPrompt(false);
  }, []);

  if (!showPrompt) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 md:left-auto md:right-4 md:w-80 z-50 bg-card border rounded-lg shadow-lg p-4 flex items-center gap-3 animate-slide-up">
      <Download className="w-8 h-8 text-primary shrink-0" />
      <div className="flex-1 min-w-0">
        <p className="font-medium text-sm">Install WoofTalk</p>
        <p className="text-xs text-muted-foreground">Install as an app for offline use</p>
      </div>
      <div className="flex gap-2 shrink-0">
        <button onClick={handleDismiss} className="p-1 text-muted-foreground hover:text-foreground">
          <X className="w-4 h-4" />
        </button>
        <button onClick={handleInstall} className="px-3 py-1 bg-primary text-primary-foreground text-sm rounded-md hover:bg-primary/90 transition-colors">
          Install
        </button>
      </div>
    </div>
  );
}
