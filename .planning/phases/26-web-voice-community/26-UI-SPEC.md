# Phase 26: Web Voice & Community — UI Design Contract

**Generated:** 2026-03-31
**Phase:** 26 — Web Voice & Community
**Domain:** Frontend (Next.js/React)

---

## Design System

### Colors
- **Primary:** `#4CAF50` (green — WoofTalk brand)
- **Background:** `bg-background` (Tailwind semantic)
- **Card:** `bg-card` with `border`
- **Muted text:** `text-muted-foreground`
- **Secondary:** `bg-secondary` / `text-secondary-foreground`

### Typography
- **Font:** Inter (Google Fonts, latin subset)
- **Headings:** `text-lg font-semibold`, `text-2xl font-bold`
- **Body:** `text-sm`, `text-base`
- **Display:** `text-2xl font-medium` for translation results

### Spacing
- **Container:** `container mx-auto px-4 py-8 max-w-2xl`
- **Card padding:** `p-4`, `p-6`
- **Gap:** `gap-2`, `gap-4`

### Components (shadcn/ui)
- **Button** — primary, secondary, ghost variants
- **Card** — for phrase cards, translation results
- **Input** — search input, text fields
- **Textarea** — phrase contribution form
- **Badge** — status indicators (approved, flagged)
- **Tabs** — community/social/leaderboard sections
- **Dialog/Modal** — phrase submission form
- **Avatar** — user avatars in social features
- **Skeleton** — loading states

---

## Page Specifications

### 1. Translate Page (Enhanced) — `/translate`

**Existing page extended with voice I/O.**

#### Voice Input
- **Mic button** positioned next to text input area
- **States:**
  - Idle: mic icon, neutral color
  - Listening: pulsing red dot, waveform visualization
  - Processing: spinner, "Listening..." text
  - Error: warning icon, "Speech recognition unavailable" message
- **Auto-stop:** silence detection after 2 seconds of no speech
- **Fallback:** button hidden when SpeechRecognition API unavailable

#### Voice Output
- **Speaker/TTS button** next to translation result
- **Settings:** speed (0.5x–2x), pitch controls in `/settings`
- **Visual feedback:** animated speaker icon while speaking

#### Layout
```
┌──────────────────────────────────────┐
│  🐾 WoofTalk    Translate | History  │
├──────────────────────────────────────┤
│  ┌────────────────────────────┐      │
│  │ [Text input area]          │ 🎤   │
│  │ Enter text to translate... │      │
│  └────────────────────────────┘      │
│  [Dog] [Cat] [Bird]    [Translate]   │
│                                      │
│  ┌────────────────────────────┐      │
│  │ Translation Result         │ 🔊   │
│  │ "Woof woof bark"           │      │
│  │ Confidence: 85%  Source: AI│      │
│  └────────────────────────────┘      │
└──────────────────────────────────────┘
```

---

### 2. Community Page — `/community`

#### Phrase Browser
- **Layout:** Card grid, responsive (1 col mobile → 3 col desktop)
- **Search bar** at top with real-time filtering
- **Filter chips:** language (Dog/Cat/Bird), category, popularity
- **Sort:** Most upvoted, Newest, Trending
- **Loading:** Skeleton cards during fetch
- **Empty state:** "No phrases found — be the first to contribute!"

#### Phrase Card
```
┌──────────────────────────────┐
│ 🐕 "Hello" → "Woof woof"    │
│ by @username · 2h ago        │
│ ▲ 42  ▼  3  💬 8            │
│ [Share] [Save]               │
└──────────────────────────────┘
```

#### Contribute Button
- Floating action button or prominent "Contribute Phrase" button
- Opens modal dialog with submission form

---

### 3. Contribute Phrase Modal

#### Form Fields
- **Human phrase** (text input, required)
- **Animal language** (select: Dog/Cat/Bird, required)
- **Animal response** (textarea, required)
- **Context/notes** (optional textarea)

#### Validation
- Real-time field validation
- Spam detection runs on submit (client-side first)
- Submit button disabled while processing
- Success toast: "Phrase submitted for review!"

---

### 4. Social Page — `/social`

#### Tabs
- **Activity Feed** — recent actions (translations, contributions, follows)
- **Followers/Following** — user lists with follow/unfollow buttons
- **Leaderboard** — top contributors by phrase count, upvotes

#### Activity Feed Item
```
┌──────────────────────────────┐
│ @username contributed a      │
│ new phrase: "Hello" → "Woof" │
│ 5 minutes ago · ❤️ 12        │
└──────────────────────────────┘
```

#### Leaderboard
- Ranked list with position, avatar, username, score
- Top 3 highlighted with medals (🥇🥈🥉)
- Pagination or infinite scroll

---

### 5. Loading & Error States

| State | Visual |
|-------|--------|
| Loading | Skeleton cards/shimmer |
| Empty | Illustration + CTA text |
| Error | Error banner with retry button |
| Offline | "You're offline — some features unavailable" banner |
| No voice support | Voice features hidden, text-only mode |

---

## Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | 320px+ | Single column, stacked nav |
| Tablet | 768px+ | 2-column phrase grid |
| Desktop | 1440px+ | 3-column phrase grid, full nav |

---

## Accessibility Requirements

- All interactive elements keyboard-navigable
- Voice input has text fallback
- ARIA labels on mic/speaker buttons
- Color contrast meets WCAG AA
- Screen reader announces translation results
- Focus management in modal dialogs
