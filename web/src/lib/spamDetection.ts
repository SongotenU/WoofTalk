interface SpamResult {
  isSpam: boolean;
  confidence: number;
  reasons: string[];
}

const spamPatterns = [
  { regex: /(.)\1{4,}/g, label: 'Repeated characters' },
  { regex: /(http|https|www):\/\/\S+/g, label: 'URL detected' },
  { regex: /\b(spam|buy|cheap|free|click|win)\b/gi, label: 'Spam keyword' },
];

const submissionTimestamps = new Map<string, number[]>();

export function detectSpam(phrase: {
  humanPhrase: string;
  animalResponse: string;
  userId?: string;
}): SpamResult {
  const reasons: string[] = [];
  let spamScore = 0;

  const combinedText = `${phrase.humanPhrase} ${phrase.animalResponse}`;

  spamPatterns.forEach(({ regex, label }) => {
    if (regex.test(combinedText)) {
      spamScore += 0.3;
      reasons.push(label);
    }
  });

  if (combinedText.length > 500) {
    spamScore += 0.2;
    reasons.push(`Text too long (${combinedText.length} chars)`);
  }

  const words = combinedText.split(/\s+/);
  const uniqueWords = new Set(words);
  if (uniqueWords.size < words.length / 2) {
    spamScore += 0.3;
    reasons.push('High word repetition');
  }

  if (phrase.userId) {
    const now = Date.now();
    const userSubmissions = submissionTimestamps.get(phrase.userId) ?? [];
    userSubmissions.push(now);
    const recentSubmissions = userSubmissions.filter((t) => now - t < 60000);
    submissionTimestamps.set(phrase.userId, recentSubmissions);

    if (recentSubmissions.length > 5) {
      spamScore += 0.4;
      reasons.push(`Too many submissions (${recentSubmissions.length}/min)`);
    }
  }

  return {
    isSpam: spamScore >= 0.5,
    confidence: Math.min(1, Math.max(0, spamScore)),
    reasons,
  };
}

export function clearSpamCache() {
  const now = Date.now();
  submissionTimestamps.forEach((timestamps, userId) => {
    submissionTimestamps.set(
      userId,
      timestamps.filter((t) => now - t < 3600000)
    );
  });
}
