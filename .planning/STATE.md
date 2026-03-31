## Current Position

Phase: Complete (v3.1 Web + Smartwatch)
Plan: —
Status: Milestone complete — awaiting next milestone
Last activity: 2026-03-31 — Milestone v3.1 Web + Smartwatch completed

## Accumulated Context

### Previous Milestones
- **v1.0 (M001+M002)**: Core Translation Engine + Community Features — Complete iOS app
- **v2.0 (M003)**: Advanced Features — AI translation, real-time, multi-language, analytics, performance, integration
- **v3.0 (M004)**: Platform Expansion — Android app, Supabase backend, cross-platform sync
- **v3.1 (M005)**: Web + Smartwatch — Next.js web app, Wear OS companion app

### v3.1 Deliverables
- **Web app (Next.js)**: React + TypeScript + Tailwind CSS + shadcn/ui
  - Voice I/O: Web Speech API (SpeechRecognition + SpeechSynthesis)
  - Community: Phrase browser, contribution modal, spam detection
  - Social: Activity feed, leaderboard, follow/unfollow
  - Cross-platform sync: Supabase Realtime channels
  - PWA support with service worker
- **Watch app (Wear OS)**: Kotlin + Compose for Wearables
  - Voice input via SpeechRecognizer
  - Glanceable translation results
  - Supabase sync with phone app
- **Deployment**: Vercel-ready web config, Play Store-ready watch module

### v3.0 Deliverables (carried forward)
- **69 new files** across 6 phases (19-24)
- **29 requirements** delivered
- **50+ unit tests** covering engine, cache, spam, conflict resolution, audio
- **Supabase backend**: 8 tables, 30+ RLS policies, 6 Edge Functions, FCM push
- **Android app**: Kotlin + Jetpack Compose, Room, Hilt, Material 3
- **Translation engine**: 3 language adapters (Dog/Cat/Bird), LRU cache, AI fallback
- **Voice I/O**: SpeechRecognizer, TextToSpeech, foreground service
- **Community**: Phrase browser, contribution, leaderboards, spam detection, share intents, widget
- **Cross-platform sync**: Offline-first queue, conflict resolution, realtime activity

### Key Architecture Decisions
- Supabase (PostgreSQL) for shared backend over Firebase
- Protocol-based language adapters for extensibility
- Offline-first with persistent write queue and exponential backoff
- Conflict resolution: last-write-wins (translations), merge (social), max-wins (votes)
- Fallback chain: AI → Vocabulary → Simple
- Web: Next.js App Router with PWA support
- Watch: Wear OS companion mode (not standalone)

### Known Tech Debt
- Duplicate `audio_processing/` directory in iOS (~1,161 lines)
- TranslationCache exists but never connected to TranslationEngine
- LanguageDetectionManager O(n²) nested loop on audio hot path
- Missing retry + circuit breaker for AI translation
- Multiple NotificationCenter/Timer memory leaks

### Lessons Learned
- Protocol-based adapter pattern proved highly effective for extensibility
- Offline-first architecture required careful sync logic but paid off in reliability
- Streaming translation chunk size tuning was critical for latency targets
- Web Speech API provides adequate voice I/O without third-party dependencies
- Wear OS Compose enables rapid watch UI development
