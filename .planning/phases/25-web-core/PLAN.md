# Phase 25: Web Core — Execution Plan

**Milestone:** v3.1 Web + Smartwatch
**Duration:** 3-4 weeks
**Prerequisites:** Phase 24 complete (Supabase backend ready)

---

## Goal

Build the web version of WoofTalk using React/Next.js — translation engine ported to TypeScript, Supabase integration, responsive UI with Tailwind CSS + shadcn/ui, PWA support for offline functionality.

---

## Requirements

| ID | Requirement |
|----|-------------|
| WEB-01 | Next.js app with React, TypeScript, Tailwind CSS, and shadcn/ui components |
| WEB-02 | Supabase client integration for auth, database, and realtime subscriptions |
| WEB-03 | Translation engine port to TypeScript with same vocabulary and output as iOS/Android |
| WEB-04 | Translation UI with text input, language selector, result display, and history |
| WEB-05 | PWA support with service worker, offline caching, and install prompt |
| WEB-06 | Responsive design for mobile, tablet, and desktop viewports |

---

## Task Breakdown

### Wave 1: Project Setup + Translation Engine (Days 1-5)

**T1. Next.js Project Setup**
- Initialize Next.js 15 with App Router, TypeScript, Tailwind CSS
- Configure shadcn/ui components
- Set up project structure: app/, components/, lib/, hooks/, services/, types/
- Configure ESLint, Prettier, path aliases
- **Effort:** 4 hours
- **Deliverable:** Buildable Next.js project with UI foundation

**T2. TypeScript Translation Engine**
- Port TranslationEngine from Kotlin to TypeScript
- Port all 3 language adapters (Dog, Cat, Bird) with same vocabulary
- Implement TranslationCache with LRU eviction and TTL
- Implement LanguageDetector and MultiLanguageRouter
- Unit test with same 50 test phrases as iOS/Android
- **Effort:** 8 hours
- **Deliverable:** TypeScript translation engine with matching output

**T3. Supabase Client Integration**
- Install @supabase/supabase-js
- Create Supabase client singleton with auth persistence
- Implement auth hooks (useAuth, useSession)
- Create auth pages (sign in, sign up, reset password)
- **Effort:** 6 hours
- **Deliverable:** Working auth flow with Supabase

### Wave 2: Translation UI (Days 6-10)

**T4. Translation Page**
- Create /translate page with:
  - Text input area
  - Language selector (Dog/Cat/Bird tabs)
  - Translate button
  - Result display with copy/share buttons
  - Recent translations list
- Implement useTranslation hook with engine + cache
- **Effort:** 8 hours
- **Deliverable:** Fully functional translation page

**T5. History Page**
- Create /history page with:
  - Paginated translation history from Supabase
  - Search/filter functionality
  - Favorite toggle
  - Delete translations
- **Effort:** 6 hours
- **Deliverable:** History page with full CRUD

**T6. Settings Page**
- Create /settings page with:
  - Language preferences
  - Cache configuration
  - Theme toggle (light/dark/system)
  - AI translation toggle
  - Account management
- **Effort:** 4 hours
- **Deliverable:** Settings page with all options

### Wave 3: PWA + Responsive (Days 11-14)

**T7. PWA Configuration**
- Configure next-pwa or custom service worker
- Create manifest.json with app metadata
- Implement offline fallback page
- Add install prompt
- Cache translation engine and vocabulary for offline use
- **Effort:** 6 hours
- **Deliverable:** PWA with offline translation capability

**T8. Responsive Design**
- Audit all pages at 320px, 768px, 1024px, 1440px
- Fix layout issues for mobile viewports
- Implement responsive navigation (mobile drawer, desktop sidebar)
- Test touch targets and accessibility
- **Effort:** 6 hours
- **Deliverable:** Fully responsive web app

---

## Verification Criteria

| # | Success Criterion | Verification Method |
|---|------------------|-------------------|
| 1 | Next.js app loads with all dependencies | `npm run build` succeeds, `npm run dev` works |
| 2 | Supabase auth works | Sign up, sign in, sign out all function |
| 3 | Translation output matches iOS/Android | Compare 50 test phrases, >95% match |
| 4 | Translation UI works end-to-end | Input → translate → result → history |
| 5 | PWA installs and works offline | Lighthouse PWA audit passes, offline translation works |
| 6 | Responsive at all breakpoints | Visual inspection at 320px, 768px, 1024px, 1440px |
