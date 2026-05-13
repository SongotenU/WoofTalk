# 🐾 WoofTalk

Translate between human and animal languages — on every platform.

**WoofTalk** is a multi-platform app that enables natural communication between humans and their pets through bidirectional translation with voice input/output. Available on iOS, Android, Web, and Wear OS — all synced in real-time via a shared Supabase backend.

[![iOS](https://img.shields.io/badge/iOS-v1.0.0-SwiftUI-black)](https://apps.apple.com/app/wooftalk)
[![Android](https://img.shields.io/badge/Android-v1.0-Kotlin-green)](https://play.google.com/store/apps/details?id=com.wooftalk.app)
[![Web](https://img.shields.io/badge/Web-v1.0.0-Next.js-blue)](https://wooftalk.app)
[![Watch](https://img.shields.io/badge/Watch-Wear_OS-orange)](android/WoofTalk/wear/)
[![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E)](supabase/)
[![Build](https://img.shields.io/github/actions/workflow/status/wooftalk/wooftalk/ios-build.yml?label=build)](https://github.com/wooftalk/wooftalk/actions)

## Features

- 🗣️ **Bidirectional Translation** — Human → Animal and Animal → Human for Dog, Cat, and Bird languages
- 🎤 **Voice I/O** — Speak to translate, listen to results — on every platform
- 🌐 **Cross-Platform Sync** — Start a translation on your watch, see it on your phone
- 👥 **Community Phrases** — Browse, contribute, and vote on user-submitted translations
- 📊 **Social Features** — Follow other users, view leaderboards, track activity
- 📱 **PWA Support** — Install the web app on any device, works offline
- ⚡ **Real-Time Updates** — Community phrases and translations sync in under 1 second
- 💎 **Premium Subscription** — Monthly/yearly plans with 3-day free trial via RevenueCat

## Platforms

| Platform | Tech Stack | Status |
|----------|-----------|--------|
| **iOS** | SwiftUI, Core Data, AVFoundation | ✅ v1.0.0 (App Store) |
| **Android** | Kotlin, Jetpack Compose, Room, Hilt | ✅ v1.0 (Play Store) |
| **Web** | Next.js, React, TypeScript, Tailwind CSS | ✅ v1.0.0 (https://wooftalk.app) |
| **Wear OS** | Kotlin, Compose for Wearables | ✅ v1.0 (Play Store) |

All platforms share the same **Supabase** (PostgreSQL) backend with real-time synchronization.

## Quick Start

### Web App

```bash
cd web
cp .env.example .env.local    # Add your Supabase credentials
npm install
npm run dev                   # http://localhost:3000
```

### Android App

```bash
cd android/WoofTalk
# Open in Android Studio — build and run on device/emulator
```

### iOS App

```bash
open WoofTalk.xcodeproj
# Build and run in Xcode
```

### Wear OS App

```bash
# Open android/WoofTalk/ in Android Studio
# Select the 'wear' module and run on a Wear OS emulator or device
```

## Project Structure

```
WoofTalk/
├── WoofTalk/                 # iOS app (SwiftUI)
├── WoofTalk.xcodeproj/       # Xcode project
├── android/WoofTalk/         # Android app (Kotlin + Jetpack Compose)
│   ├── app/                  # Phone app module
│   └── wear/                 # Wear OS companion app
├── web/                      # Web app (Next.js)
│   ├── src/
│   │   ├── app/              # Next.js App Router pages
│   │   │   ├── translate/    # Translation page with voice I/O
│   │   │   ├── community/    # Community phrase browser
│   │   │   ├── social/       # Social features (activity, leaderboard)
│   │   │   ├── history/      # Translation history
│   │   │   └── settings/     # App settings + voice controls
│   │   ├── components/       # Reusable UI components
│   │   ├── hooks/            # Custom React hooks
│   │   └── lib/              # Core libraries (Supabase, translation, sync)
│   └── public/               # Static assets, PWA files
├── supabase/                 # Database schema, migrations, edge functions
├── .planning/                # Project planning artifacts
│   ├── ROADMAP.md            # Full project roadmap
│   ├── REQUIREMENTS.md       # Current milestone requirements
│   ├── PROJECT.md            # Project documentation
│   ├── STATE.md              # Current project state
│   ├── phases/               # Phase-by-phase execution records
│   └── reports/              # Milestone summaries
└── README.md                 # You are here
```

## Architecture

### Translation Engine

WoofTalk uses a **protocol-based adapter pattern** for language translation:

```
Human Text → LanguageAdapter → Animal Text
Animal Text → LanguageAdapter → Human Text
```

Each animal language (Dog, Cat, Bird) implements a `LanguageAdapter` protocol/interface, making it trivial to add new languages. The fallback chain is: **AI → Vocabulary → Simple**.

### Backend

All platforms connect to a single **Supabase** project:

- **PostgreSQL** — 8 tables for users, translations, community phrases, social graph
- **Auth** — Email, Google, Apple sign-in across all platforms
- **Realtime** — PostgreSQL LISTEN/NOTIFY for <1s sync latency
- **Edge Functions** — Server-side validation, spam detection, push notifications
- **RLS Policies** — 30+ row-level security policies for data isolation

### Sync Strategy

- **Offline-first** — Local storage with persistent write queue and exponential backoff
- **Conflict resolution** — Last-write-wins (translations), merge (social), max-wins (votes)
- **Real-time channels** — Active subscriptions for translations, community phrases, and activity events

## Environment Setup

### Web

Create `web/.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Android

Add Supabase credentials to `android/WoofTalk/local.properties` or `secrets.properties`:

```properties
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### iOS

Configure Supabase URL and anon key in the app's configuration.

## CI/CD

### Supabase (Migrations + Edge Functions)

Triggered on push to `supabase/**`:
- Database migrations deploy
- Edge functions deploy

### Web (Next.js)

Triggered on push to `web/**` on main:
- Lint + TypeScript check
- RLS audit gate (blocks overly permissive policies)
- Deploy to Vercel

### Monitoring

- **Uptime checks** — GitHub Actions runs every 5 minutes, checks Supabase and web app health
- **Error tracking** — Sentry-ready (`ErrorReporter.swift` on iOS)
- **Load testing** — k6 scripts in `scripts/load-tests/` with RLS concurrent verification

## Deployment

### Web

Deployed to **Vercel** with PWA support:

```bash
cd web
npm run build
# Push to main — Vercel auto-deploys
```

Configuration: `web/vercel.json`, `web/next.config.ts`

### Android

Build release APK/AAB:

```bash
cd android/WoofTalk
./gradlew :app:assembleRelease
```

### Wear OS

Build for Play Store submission:

```bash
cd android/WoofTalk
./gradlew :wear:assembleRelease
```

## Testing

### Android

```bash
cd android/WoofTalk
./gradlew :app:test          # Unit tests
./gradlew :app:connectedAndroidTest  # Instrumented tests
```

50+ unit tests covering translation engine, cache, spam detection, conflict resolution, and audio processing.

### Web

```bash
cd web
npm run build                 # TypeScript + Next.js build validation
npx tsc --noEmit             # Type checking
```

## Milestones

| Milestone | Version | Status | Description |
|-----------|---------|--------|-------------|
| M001 | v1.0 | ✅ | Core Translation Engine — iOS app |
| M002 | v1.0 | ✅ | Community Features — iOS |
| M003 | v2.0 | ✅ | Advanced Features — AI, real-time, analytics |
| M004 | v3.0 | ✅ | Platform Expansion — Android + cross-platform sync |
| M005 | v3.1 | ✅ | Web + Smartwatch |
| M006 | v4.0 | ✅ | Enterprise — API access, admin features |
| M007 | v4.1 | ✅ | AR/VR Mixed Reality |
| M008 | v4.1 | ✅ | Production Hardening — CI/CD, observability, resilience |
| **M009** | **v1.0** | ✅ | **Subscription & Payments — RevenueCat integration** |
| **M010** | **v1.0.0** | ✅ | **Ship to Production — iOS, Android, Web** |

---

## Tech Stack

- **iOS**: Swift, SwiftUI, Core Data, AVFoundation
- **Android**: Kotlin, Jetpack Compose, Room, Hilt, Material 3
- **Web**: Next.js 15, React 19, TypeScript, Tailwind CSS
- **Watch**: Kotlin, Compose for Wearables
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Edge Functions)
- **Voice**: AVFoundation (iOS), SpeechRecognizer + TextToSpeech (Android), Web Speech API (Web)
- **Payments**: RevenueCat (subscriptions, in-app purchases)
- **CI/CD**: GitHub Actions (Supabase + Vercel pipelines, RLS audit)
- **Monitoring**: Sentry (iOS/Web), Firebase Crashlytics (Android), GitHub Actions uptime monitor
- **Deployment**: Vercel (Web), Google Play Store (Android + Wear OS), App Store (iOS)

---

## Production

### Web App
Deployed to **Vercel** with PWA support — https://wooftalk.app

### Mobile Apps
- **iOS**: Available on the App Store (v1.0.0)
- **Android**: Available on Google Play Store (v1.0)
- **Wear OS**: Available on Google Play Store

### Monitoring
- **Error Tracking**: Sentry (iOS/Web), Firebase Crashlytics (Android)
- **Uptime**: GitHub Actions checks every 5 minutes
- **Analytics**: Supabase Dashboard, RevenueCat Dashboard

---

## License

All rights reserved.
