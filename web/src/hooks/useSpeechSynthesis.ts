'use client';

import { useState, useRef, useCallback, useEffect } from 'react';

interface SpeechSynthesisHook {
  isSpeaking: boolean;
  isSupported: boolean;
  speak: (text: string, options?: { rate?: number; pitch?: number }) => void;
  stop: () => void;
}

export function useSpeechSynthesis(): SpeechSynthesisHook {
  const [isSpeaking, setIsSpeaking] = useState(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);

  const isSupported =
    typeof window !== 'undefined' && !!window.speechSynthesis;

  const stop = useCallback(() => {
    if (typeof window !== 'undefined') {
      window.speechSynthesis.cancel();
    }
    utteranceRef.current = null;
    setIsSpeaking(false);
  }, []);

  const speak = useCallback(
    (text: string, options?: { rate?: number; pitch?: number }) => {
      if (!isSupported || !text) return;

      window.speechSynthesis.cancel();

      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = options?.rate ?? parseFloat(localStorage.getItem('voiceRate') ?? '1');
      utterance.pitch = options?.pitch ?? parseFloat(localStorage.getItem('voicePitch') ?? '1');

      utterance.onstart = () => setIsSpeaking(true);
      utterance.onend = () => {
        utteranceRef.current = null;
        setIsSpeaking(false);
      };
      utterance.onerror = () => {
        utteranceRef.current = null;
        setIsSpeaking(false);
      };

      utteranceRef.current = utterance;
      window.speechSynthesis.speak(utterance);
    },
    [isSupported]
  );

  useEffect(() => {
    return () => {
      if (typeof window !== 'undefined') {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  return { isSpeaking, isSupported, speak, stop };
}
