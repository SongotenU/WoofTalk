# Phase 27: Watch Core — UI Design Contract

**Generated:** 2026-03-31
**Phase:** 27 — Watch Core
**Domain:** Wear OS (Kotlin + Compose for Wearables)

---

## Design System

### Colors
- **Primary:** `#4CAF50` (green — WoofTalk brand, consistent with iOS/Android/Web)
- **Background:** `MaterialTheme.colors.background` — dark by default on Wear OS
- **On-background:** `MaterialTheme.colors.onBackground`
- **Surface:** `MaterialTheme.colors.surface`
- **On-surface:** `MaterialTheme.colors.onSurface`
- **Primary content:** `MaterialTheme.colors.primary`
- **On-primary:** `MaterialTheme.colors.onPrimary`

### Typography
- **Font:** System default (Roboto on Wear OS)
- **Title:** `MaterialTheme.typography.title3` — page titles
- **Body:** `MaterialTheme.typography.body1` — primary text
- **Caption:** `MaterialTheme.typography.caption` — metadata, timestamps
- **Display:** Large custom text for translation results — `fontSize = 20.sp` minimum, scales up for short text

### Spacing (Wear OS scale)
- **Screen padding:** `ScalingLazyColumnDefaults.padding()` — built-in Wear OS edge padding
- **Item spacing:** `8.dp` between list items
- **Chip padding:** Built-in `Chip` component handles internal spacing
- **Icon size:** `24.dp` standard, `32.dp` for primary action

### Components (Compose for Wearables)
- **Chip** — primary interaction element (tap to speak, view history)
- **ScalingLazyColumn** — scrollable list with auto-scaling items
- **TimeText** — always-visible time indicator at top
- **PositionIndicator** — scroll position indicator
- **Vignette** — edge fade for readability
- **ToggleChip** — for settings toggles
- **CompactChip** — for secondary actions

---

## Screen Specifications

### 1. Translation Screen (Primary) — `TranslationScreen`

**Single-screen flow: tap → speak → see result**

#### Layout Structure
```
┌─────────────────┐
│     12:34       │  ← TimeText (always visible)
├─────────────────┤
│                 │
│   🎤 Tap to     │  ← Primary Chip (centered, large)
│      Speak      │
│                 │
│   "Hello"       │  ← Input text (shown after speech)
│                 │
│   → "Woof woof" │  ← Translation result (large, primary color)
│                 │
│   ◉ 60% AI      │  ← Confidence + source (caption)
│                 │
├─────────────────┤
│   ◉             │  ← PositionIndicator
└─────────────────┘
```

#### States
| State | Visual |
|-------|--------|
| Idle | Mic chip with "Tap to Speak" text |
| Listening | Chip turns red, pulsing animation, "Listening..." text |
| Processing | Circular progress indicator, "Translating..." text |
| Result | Input text (small) → Translation result (large, primary color), confidence badge |
| Error | Warning icon + "Speech error" text, retry chip |

#### Interactions
- **Tap mic chip** → launches SpeechRecognizer intent
- **Speech result** → auto-translates, displays result
- **Tap result** → reads aloud via TextToSpeech
- **Scroll down** → reveals history chips
- **Scroll up** → scrolls back to mic chip

---

### 2. History Screen — Secondary (scroll from main)

#### Layout
```
┌─────────────────┐
│   History       │  ← Title
├─────────────────┤
│ Hello → Woof    │  ← CompactChip, truncated
│ Good boy → Arf  │  ← CompactChip, truncated
│ Sit → *tilts*   │  ← CompactChip, truncated
│                 │
└─────────────────┘
```

- Each item: `CompactChip` with truncated translation pair
- Tap item → expands to full translation view
- Max 20 items (matches mobile/web history limit)
- Empty state: "No translations yet" centered text

---

### 3. Settings Screen — Tertiary (scroll from main)

#### Layout
- Simple list of `ToggleChip` and `CompactChip` items
- Settings available:
  - **Voice Speed** — not configurable on watch (uses phone settings)
  - **Language** — CompactChip selector (Dog/Cat/Bird)
  - **Sync Status** — indicator showing connected/disconnected

---

## Loading & Error States

| State | Visual |
|-------|--------|
| Loading | `CircularProgressIndicator` centered |
| Empty | Centered text: "No translations yet" |
| Error | Warning icon + error text + retry chip |
| Offline | Small "⚠ Offline" text in caption style |
| No speech recognition | Mic chip disabled + "Voice unavailable" text |

---

## Wear OS-Specific Constraints

### Screen Size
- **Target:** 320×320 (standard round watch face)
- **Safe area:** ~280×280 usable (accounting for chin/round edges)
- **Text truncation:** All text must handle overflow with `TextOverflow.Ellipsis`

### Interaction Model
- **Primary:** Tap (single touch)
- **Secondary:** Scroll (rotary encoder or swipe)
- **No:** Long press, multi-touch, swipe gestures (reserved for system)

### Performance Targets
- **Launch time:** <2 seconds (watch users expect instant access)
- **Translation display:** <3 seconds from speech end to result
- **Scroll:** 60fps on ScalingLazyColumn

### Battery Considerations
- SpeechRecognizer only active during active listening
- No background polling — use Supabase Realtime subscriptions only when screen visible
- Network requests only on user action or screen open

---

## Accessibility

- All chips have `contentDescription` for TalkBack
- Translation results announced via TalkBack
- Minimum touch target: `48.dp` (Chip component handles this)
- Color contrast meets WCAG AA on dark background (default Wear OS theme)
- No color-only state indicators (listening = red + text change, not just color)

---

## Consistency with Other Platforms

| Element | iOS | Android | Web | Watch |
|---------|-----|---------|-----|-------|
| Primary color | #4CAF50 | #4CAF50 | #4CAF50 | #4CAF50 |
| Language options | Dog/Cat/Bird | Dog/Cat/Bird | Dog/Cat/Bird | Dog/Cat/Bird |
| Translation flow | Speak → Translate → Result | Speak → Translate → Result | Speak → Translate → Result | Tap → Speak → Result |
| History limit | 20 items | 20 items | 20 items | 20 items |
| Voice speed control | Settings | Settings | Settings | Uses phone settings |
