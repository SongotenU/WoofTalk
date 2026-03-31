# Phase 20: Android Core Translation — Execution Plan

**Milestone:** v3.0 Platform Expansion
**Duration:** 4-5 weeks
**Prerequisites:** Phase 19 complete (backend infrastructure)

---

## Goal

Build the Android app's core translation layer — Kotlin port of the translation engine, Jetpack Compose UI, Room database persistence, multi-language support, and LRU caching — achieving full feature parity with the iOS translation experience.

---

## Requirements

| ID | Requirement |
|----|-------------|
| ANDROID-CORE-01 | Kotlin translation engine with rule-based translation matching iOS TranslationEngine |
| ANDROID-CORE-02 | AI translation with OpenAI fallback chain (AI → Vocabulary → Simple) |
| ANDROID-CORE-03 | Jetpack Compose UI with Material 3 (translation view, history, settings) |
| ANDROID-CORE-04 | Room Database for local persistence matching iOS Core Data schema |
| ANDROID-CORE-05 | Multi-language support (Dog, Cat, Bird) with protocol-based adapters |
| ANDROID-CORE-06 | LRU translation cache with configurable max size and TTL |

---

## Task Breakdown

### Wave 1: Project Setup + Data Layer (Days 1-5)

**T1. Android Project Structure**
- Create Android project with Kotlin + Jetpack Compose
- Configure Gradle with dependencies: Compose BOM, Room, Coroutines, Hilt, Supabase Kotlin SDK
- Set up package structure: `data/`, `domain/`, `ui/`, `di/`
- Configure Material 3 theming (light/dark, dynamic color)
- **Effort:** 4 hours
- **Deliverable:** Buildable Android project with Compose UI skeleton

**T2. Room Database Schema**
- Create Room entities matching PostgreSQL schema from Phase 19:
  - `TranslationEntity` (id, userId, humanText, animalText, sourceLanguage, targetLanguage, confidence, qualityScore, isFavorite, createdAt)
  - `CommunityPhraseEntity` (id, phraseText, language, submittedBy, approvalStatus, upvotes, downvotes, createdAt)
  - `UserEntity` (id, email, displayName, avatarUrl, platform, isPremium, createdAt)
- Create DAOs: `TranslationDao`, `CommunityPhraseDao`, `UserDao`
- Create `AppDatabase` with migrations
- **Effort:** 4 hours
- **Deliverable:** Room database with all entities, DAOs, and type converters

**T3. Repository Layer**
- Create `TranslationRepository` (Room + Supabase dual-source)
- Create `CommunityPhraseRepository` (Room + Supabase dual-source)
- Create `UserRepository` (Room + Supabase dual-source)
- Implement offline-first read strategy (Room first, fallback to Supabase)
- **Effort:** 6 hours
- **Deliverable:** Repository layer with offline-first data access

### Wave 2: Translation Engine (Days 6-12)

**T4. Kotlin Translation Engine**
- Port `TranslationEngine.swift` to Kotlin:
  - `TranslationEngine` class with `translate(text, direction)` method
  - Rule-based vocabulary lookup (human→dog, dog→human, etc.)
  - Confidence scoring based on vocabulary match quality
  - Simple fallback (woof/bark/meow/chirp) for unknown text
- Port `VocabularyDatabase` with 100+ phrase mappings
- **Effort:** 8 hours
- **Deliverable:** Working Kotlin translation engine matching iOS output

**T5. Language Adapter System**
- Create `LanguageAdapter` interface (protocol equivalent)
- Implement `DogLanguageAdapter`, `CatLanguageAdapter`, `BirdLanguageAdapter`
- Create `LanguageDetector` for auto-detecting input language
- Implement `MultiLanguageRouter` for routing translations to correct adapter
- **Effort:** 6 hours
- **Deliverable:** Extensible multi-language system

**T6. AI Translation Service**
- Create `AITranslationService` with OpenAI API integration
- Implement fallback chain: AI → Vocabulary → Simple
- Add quality scoring for AI translations
- Implement error handling with graceful degradation
- **Effort:** 6 hours
- **Deliverable:** AI translation with fallback chain

**T7. LRU Translation Cache**
- Create `TranslationCache` with LRU eviction
- Configurable max size (default 1000 entries)
- TTL-based expiration (default 24 hours)
- Efficient key generation (normalized text + direction)
- Memory pressure handling
- **Effort:** 4 hours
- **Deliverable:** LRU cache with TTL and eviction

### Wave 3: UI Layer (Days 13-18)

**T8. Translation Screen**
- Create `TranslationScreen` Composable with:
  - Text input field (human text)
  - Language selector (Dog/Cat/Bird)
  - Translate button
  - Result display (animal text)
  - History list (recent translations)
  - Favorite toggle
- Implement view model with state management
- **Effort:** 8 hours
- **Deliverable:** Fully functional translation screen

**T9. History Screen**
- Create `HistoryScreen` Composable with:
  - Paginated translation history list
  - Search/filter functionality
  - Favorite filtering
  - Swipe-to-delete
  - Share translation
- **Effort:** 6 hours
- **Deliverable:** History screen with full CRUD

**T10. Settings Screen**
- Create `SettingsScreen` Composable with:
  - Language preferences
  - Cache size configuration
  - Theme selection (light/dark/system)
  - AI translation toggle
  - Account settings link
- **Effort:** 4 hours
- **Deliverable:** Settings screen with all options

**T11. Navigation + App Shell**
- Create `MainActivity` with Compose Navigation
- Set up bottom navigation (Translate, History, Settings)
- Implement app theming (Material 3, dynamic color)
- Add splash screen
- **Effort:** 4 hours
- **Deliverable:** Complete app shell with navigation

---

## Dependency Graph

```
Wave 1:  T1 ─┬─ T2 ─┬─ T3
             │      │
             └──────┘ (T1 first, then T2+T3 parallel)

Wave 2:  T4 ─┬─ T5 ─┬─ T7
             ├─ T6 ─┤
             └──────┘ (T4 first, then T5+T6 parallel, then T7)

Wave 3:  T8 ─┬─ T9 ─┬─ T11
             ├─ T10 ─┤
             └───────┘ (T8 first, then T9+T10 parallel, then T11)
```

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Android translates "hello" → dog language with >80% match to iOS | Compare output of Kotlin engine vs Swift engine for 50 test phrases |
| 2 | AI translation works with fallback when API unavailable | Mock API failure → verify fallback to rule-based → verify simple fallback |
| 3 | Material 3 UI matches iOS: translation, history, settings screens | Visual comparison with iOS screenshots |
| 4 | Room Database persists history and survives app restart | Save translations → kill app → restart → verify history intact |
| 5 | Multi-language works for Dog, Cat, Bird with detection | Test each language pair, verify auto-detection accuracy |
| 6 | LRU cache returns cached translations within 10ms | Benchmark repeated translations, verify cache hit timing |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Kotlin translation output differs from Swift | Medium | High | Unit test with same vocabulary, compare outputs |
| Room schema drift from PostgreSQL | Low | Medium | Use same field names, validate against Phase 19 schema |
| Compose performance issues on low-end devices | Medium | Medium | Use lazy lists, avoid recomposition, profile early |
| OpenAI API costs on Android | Low | Medium | Implement rate limiting, cache aggressively |
