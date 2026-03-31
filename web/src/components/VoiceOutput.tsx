'use client';

import { useSpeechSynthesis } from '@/hooks/useSpeechSynthesis';

interface VoiceOutputProps {
  text: string;
}

export function VoiceOutput({ text }: VoiceOutputProps) {
  const { isSpeaking, isSupported, speak, stop } = useSpeechSynthesis();

  if (!isSupported || !text) return null;

  const handleClick = () => {
    if (isSpeaking) {
      stop();
    } else {
      speak(text);
    }
  };

  return (
    <button
      onClick={handleClick}
      className={`w-10 h-10 rounded-full flex items-center justify-center transition-all ${
        isSpeaking
          ? 'bg-primary text-primary-foreground animate-pulse'
          : 'bg-primary/10 text-primary hover:bg-primary/20'
      }`}
      aria-label={isSpeaking ? 'Stop speaking' : 'Read aloud'}
    >
      {isSpeaking ? (
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
        </svg>
      ) : (
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
          <path d="M15.54 8.46a5 5 0 0 1 0 7.07" />
          <path d="M19.07 4.93a10 10 0 0 1 0 14.14" />
        </svg>
      )}
    </button>
  );
}
