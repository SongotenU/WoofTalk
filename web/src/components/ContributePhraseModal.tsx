'use client';

import { useState, useEffect, useRef } from 'react';
import { submitCommunityPhrase } from '@/lib/supabase';
import { detectSpam } from '@/lib/spamDetection';

interface ContributePhraseModalProps {
  userId: string;
  onClose: () => void;
  onSubmitted: () => void;
}

export function ContributePhraseModal({ userId, onClose, onSubmitted }: ContributePhraseModalProps) {
  const [humanPhrase, setHumanPhrase] = useState('');
  const [animalLanguage, setAnimalLanguage] = useState<'dog' | 'cat' | 'bird'>('dog');
  const [animalResponse, setAnimalResponse] = useState('');
  const [context, setContext] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [spamWarning, setSpamWarning] = useState<string | null>(null);
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEscape);
    document.body.style.overflow = 'hidden';
    modalRef.current?.focus();
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = '';
    };
  }, [onClose]);

  const validateForm = (): boolean => {
    if (!humanPhrase.trim()) {
      setError('Human phrase is required');
      return false;
    }
    if (!animalResponse.trim()) {
      setError('Animal response is required');
      return false;
    }
    return true;
  };

  const handleSubmit = async () => {
    setError(null);
    setSpamWarning(null);

    if (!validateForm()) return;

    const spamResult = detectSpam({ humanPhrase, animalResponse, userId });
    if (spamResult.isSpam) {
      setSpamWarning(`Possible spam detected: ${spamResult.reasons.join(', ')}`);
      return;
    }

    setSubmitting(true);

    const { error: submitError } = await submitCommunityPhrase({
      humanPhrase: humanPhrase.trim(),
      animalLanguage,
      animalResponse: animalResponse.trim(),
      context: context.trim() || undefined,
      userId,
    });

    setSubmitting(false);

    if (submitError) {
      setError(submitError.message);
    } else {
      onSubmitted();
    }
  };

  return (
    <div
      className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        ref={modalRef}
        tabIndex={-1}
        className="bg-card rounded-xl border max-w-lg w-full p-6 focus:outline-none"
        role="dialog"
        aria-modal="true"
        aria-label="Contribute a phrase"
      >
        <h2 className="text-xl font-bold mb-4">Contribute Phrase</h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Human Phrase *</label>
            <input
              type="text"
              value={humanPhrase}
              onChange={(e) => { setHumanPhrase(e.target.value); setError(null); setSpamWarning(null); }}
              placeholder='e.g., "Hello"'
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Animal Language *</label>
            <select
              value={animalLanguage}
              onChange={(e) => setAnimalLanguage(e.target.value as 'dog' | 'cat' | 'bird')}
              className="w-full px-3 py-2 border rounded-lg bg-background focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="dog">🐕 Dog</option>
              <option value="cat">🐈 Cat</option>
              <option value="bird">🐦 Bird</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Animal Response *</label>
            <textarea
              value={animalResponse}
              onChange={(e) => { setAnimalResponse(e.target.value); setError(null); setSpamWarning(null); }}
              placeholder='e.g., "Woof woof"'
              rows={3}
              className="w-full px-3 py-2 border rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Context (optional)</label>
            <textarea
              value={context}
              onChange={(e) => setContext(e.target.value)}
              placeholder="When does the animal say this?"
              rows={2}
              className="w-full px-3 py-2 border rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {error && (
            <p className="text-sm text-destructive">{error}</p>
          )}
          {spamWarning && (
            <p className="text-sm text-yellow-600">{spamWarning}</p>
          )}

          <div className="flex gap-3 justify-end">
            <button
              onClick={onClose}
              className="px-4 py-2 border rounded-lg hover:bg-secondary transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={submitting || !humanPhrase.trim() || !animalResponse.trim()}
              className="px-4 py-2 bg-primary text-primary-foreground rounded-lg font-medium disabled:opacity-50 hover:bg-primary/90 transition-colors"
            >
              {submitting ? 'Submitting...' : 'Submit'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
