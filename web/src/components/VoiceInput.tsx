'use client';

import { useSpeechRecognition } from '@/hooks/useSpeechRecognition';

interface VoiceInputProps {
  onResult: (transcript: string) => void;
  onError?: (error: string) => void;
}

export function VoiceInput({ onResult, onError }: VoiceInputProps) {
  const { isListening, transcript, interimTranscript, error, isSupported, startListening, stopListening } =
    useSpeechRecognition();

  if (!isSupported) return null;

  const handleToggle = () => {
    if (isListening) {
      stopListening();
      const fullTranscript = transcript + interimTranscript;
      if (fullTranscript.trim()) {
        onResult(fullTranscript.trim());
      }
    } else {
      startListening();
    }
  };

  const displayText = error ? '⚠ Speech error' : isListening ? 'Listening...' : '';

  return (
    <div className="flex flex-col items-center gap-2">
      <button
        onClick={handleToggle}
        className={`relative w-12 h-12 rounded-full flex items-center justify-center transition-all ${
          isListening
            ? 'bg-red-500 text-white animate-pulse'
            : error
            ? 'bg-yellow-100 text-yellow-600 hover:bg-yellow-200'
            : 'bg-primary/10 text-primary hover:bg-primary/20'
        }`}
        aria-label={isListening ? 'Stop listening' : 'Start voice input'}
      >
        {isListening ? (
          <span className="w-3 h-3 bg-white rounded-full" />
        ) : (
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
            <path d="M19 10v2a7 7 0 0 1-14 0v2" />
            <line x1="12" x2="12" y1="19" y2="22" />
          </svg>
        )}
      </button>
      {displayText && (
        <p className="text-xs text-muted-foreground">{displayText}</p>
      )}
      {interimTranscript && isListening && (
        <p className="text-xs text-muted-foreground italic max-w-[200px] text-center truncate">
          {interimTranscript}
        </p>
      )}
    </div>
  );
}
