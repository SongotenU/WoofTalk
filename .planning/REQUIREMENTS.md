# v3.1 Requirements — Web + Smartwatch

**Milestone:** v3.1 Web + Smartwatch
**Date:** 2026-03-31
**Goal:** Expand WoofTalk to web (React/Next.js) and smartwatch (Wear OS) platforms for complete multi-platform coverage.

---

## Web Core (Phase 25)

- [ ] **WEB-01**: Next.js app with React, TypeScript, Tailwind CSS, and shadcn/ui components
- [ ] **WEB-02**: Supabase client integration for auth, database, and realtime subscriptions
- [ ] **WEB-03**: Translation engine port to TypeScript with same vocabulary and output as iOS/Android
- [ ] **WEB-04**: Translation UI with text input, language selector, result display, and history
- [ ] **WEB-05**: PWA support with service worker, offline caching, and install prompt
- [ ] **WEB-06**: Responsive design for mobile, tablet, and desktop viewports

## Web Voice & Community (Phase 26)

- [ ] **WEB-VOICE-01**: Web Speech API (SpeechRecognition) for voice input
- [ ] **WEB-VOICE-02**: Web Speech API (SpeechSynthesis) for voice output with configurable speed/pitch
- [ ] **WEB-COMMUNITY-01**: Community phrase browser with search, filter, and pagination
- [ ] **WEB-COMMUNITY-02**: Phrase contribution with submission, validation, and spam detection
- [ ] **WEB-SOCIAL-01**: Social features: follow/unfollow, leaderboards, activity feed
- [ ] **WEB-SHARE-01**: Share translations via Web Share API and copy-to-clipboard
- [ ] **WEB-SYNC-01**: Cross-platform sync with iOS and Android (shared auth, history, social graph)

## Watch Core (Phase 27)

- [ ] **WATCH-01**: Wear OS app with Kotlin and Compose for Wearables
- [ ] **WATCH-02**: Voice input using SpeechRecognizer optimized for watch form factor
- [ ] **WATCH-03**: Quick translation UI with glanceable result display
- [ ] **WATCH-04**: Translation history accessible from watch
- [ ] **WATCH-05**: Supabase integration for sync with phone app and cloud
- [ ] **WATCH-06**: Complication for quick translation launch from watch face

## Integration (Phase 28)

- [ ] **INTEGRATION-WEB-01**: End-to-end web flow: voice → translate → share → sync to mobile
- [ ] **INTEGRATION-WATCH-01**: End-to-end watch flow: voice → translate → sync to phone
- [ ] **INTEGRATION-CROSS-01**: Cross-platform sync validation across iOS, Android, Web, Watch
- [ ] **INTEGRATION-PERF-01**: Web performance: LCP <2.5s, FID <100ms, CLS <0.1
- [ ] **INTEGRATION-DEPLOY-01**: Web deployment configured (Vercel/Netlify), Watch app ready for Play Store

---

## Out of Scope

| Requirement | Reason |
|-------------|--------|
| Wear OS standalone app | Watch is companion only, requires phone for full features |
| Apple Watch app | Deferred — prioritize Wear OS first (larger market) |
| Web admin dashboard | Deferred to M006 Enterprise milestone |
| Web push notifications | Deferred — use PWA notifications later |
| Watch community features | Watch is quick-translate only, no community browsing |

---

## Traceability

| Phase | Requirements | Success Criteria |
|-------|-------------|-----------------|
| Phase 25: Web Core | WEB-01 through WEB-06 | Web app loads, translates, works offline |
| Phase 26: Web Voice & Community | WEB-VOICE-01 through WEB-SYNC-01 | Voice I/O, community, social, sync all working |
| Phase 27: Watch Core | WATCH-01 through WATCH-06 | Watch translates via voice, syncs with phone |
| Phase 28: Integration | All | E2E flows work, performance targets met, deployed |
