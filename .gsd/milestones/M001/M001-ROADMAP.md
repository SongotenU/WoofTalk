# M001: Core Translation Engine

**Vision:** Build a real-time speech-to-speech translation iOS app that enables meaningful communication between humans and dogs with comprehensive vocabulary and offline capability.

**Success Criteria:**
- Real-time translation latency under 2 seconds
- 5000+ dog-human vocabulary phrases with contextual accuracy
- Offline mode supports 80% of core phrases
- iOS app passes App Store review with native performance

---

## Slices

- [x] **S01: Audio Processing Foundation** `risk:high` `depends:[]`
  > After this: App can capture, process, and play audio with low latency.

- [x] **S02: Translation Engine** `risk:high` `depends:[S01]`
  > After this: Real-time translation between human speech and dog vocalizations.

- [x] **S03: Core UI & UX** `risk:medium` `depends:[S02]`
  > After this: Native iOS app with intuitive translation interface.

- [x] **S04: Offline Mode** `risk:medium` `depends:[S03]`
  > After this: Core translation works without internet connection.

- [x] **S05: App Store Integration** `risk:low` `depends:[S04]`
  > After this: App passes App Store review and is available for download.

---

## Boundary Map

### S01 → S02
**Produces:**
  audio.ts → captureAudio(), processAudio(), playAudio() (interfaces)
  audio_engine.ts → AudioEngine class with real-time processing

**Consumes:** nothing (leaf node)

### S02 → S03
**Produces:**
  translation.ts → translateHumanToDog(), translateDogToHuman() (interfaces)
  translation_engine.ts → TranslationEngine class with context handling

**Consumes from S01:**
  audio.ts → captureAudio(), processAudio() for input
  audio_engine.ts → playAudio() for output

### S03 → S04
**Produces:**
  ui/main_view_controller.swift → Main translation interface
  ui/translation_view_controller.swift → Real-time translation display
  ui/offline_mode_view_controller.swift → Offline mode interface

**Consumes from S02:**
  translation.ts → translateHumanToDog(), translateDogToHuman() functions
  translation_engine.ts → TranslationEngine instance

### S04 → S05
**Produces:**
  offline_storage.ts → cacheTranslations(), loadCachedTranslations()
  offline_manager.ts → OfflineManager class with fallback logic

**Consumes from S03:**
  ui/offline_mode_view_controller.swift → triggers offline mode
  ui/main_view_controller.swift → handles connectivity changes

### S05 → None
**Produces:**
  app_store_config.ts → App Store metadata and compliance
  app_store_screenshots.ts → Screenshot generation and optimization

**Consumes from S04:**
  offline_manager.ts → offline capability for App Store review
  ui/main_view_controller.swift → core functionality for demonstration