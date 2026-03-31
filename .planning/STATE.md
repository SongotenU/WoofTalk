## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-31 — Milestone v3.0 Platform Expansion started

## Accumulated Context

### Previous Milestones
- **v1.0 (M001+M002)**: Core Translation Engine + Community Features — Complete iOS app
- **v2.0 (M003)**: Advanced Features — AI translation, real-time, multi-language, analytics, performance, integration

### Key Architecture Decisions
- Rule-based translation engine as MVP, AI as enhancement layer
- Offline-first architecture with sync when online
- Protocol-based language adapter pattern for multi-language support
- Fallback chain: AI → Vocabulary → Simple (woof/meow/chirp)
- LRU caching with configurable max size for translation results
- UserDefaults for analytics storage (may need SQLite migration as data grows)

### Known Tech Debt (from optimization audit)
- Duplicate `audio_processing/` directory (~1,161 lines)
- TranslationCache exists but never connected to TranslationEngine
- LanguageDetectionManager O(n²) nested loop on audio hot path
- Missing retry + circuit breaker for AI translation
- Multiple NotificationCenter/Timer memory leaks

### Lessons Learned
- Protocol-based adapter pattern proved highly effective for extensibility
- Offline-first architecture required careful sync logic but paid off in reliability
- Streaming translation chunk size tuning was critical for latency targets
