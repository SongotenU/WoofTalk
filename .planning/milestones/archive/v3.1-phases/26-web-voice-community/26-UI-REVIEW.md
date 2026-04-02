# Phase 26: Web Voice & Community — UI Review

**Audited:** 2026-03-31
**Phase:** 26 — Web Voice & Community
**Baseline:** 26-UI-SPEC.md design contract
**Auditor:** gsd-ui-auditor

---

## Pillar Scores

| Pillar | Score | Max |
|--------|-------|-----|
| Copywriting | 3 | 4 |
| Visuals | 3 | 4 |
| Color | 3 | 4 |
| Typography | 3 | 4 |
| Spacing | 4 | 4 |
| Experience Design | 3 | 4 |
| **Total** | **19** | **24** |

---

## 1. Copywriting — 3/4

**What works:**
- Consistent label patterns: "Human Phrase *", "Animal Language *", "Animal Response *"
- Clear action text: "Tap to Speak", "Translating...", "Submitting..."
- Good empty states: "No phrases found — be the first to contribute!", "No activity yet"
- ARIA labels on all interactive elements

**Gaps:**
- ActivityFeed empty state ("No activity yet") is bare — spec calls for illustration + CTA
- No success toast text visible — modal calls `onSubmitted()` without showing "Phrase submitted for review!"
- Spam warning message is functional but lacks brand tone: "Possible spam detected: ..."
- Leaderboard empty state ("No contributors yet") has no CTA to drive engagement

**Fix:** Add a toast/notification system for submission success. Enrich empty states with CTAs.

---

## 2. Visuals — 3/4

**What works:**
- Consistent SVG icon style (Lucide-style) for mic, speaker icons
- Avatar pattern consistent across ActivityFeed, Leaderboard, UserFollowCard (colored circles with initials)
- Skeleton loading states with `animate-pulse` — uniform across all components
- Modal with `backdrop-blur-sm` and `rounded-xl` — polished
- PhraseCard `hover:shadow-md transition-shadow` — nice micro-interaction
- Leaderboard top-3 highlight with `bg-primary/5 border-primary/20` — excellent visual hierarchy

**Gaps:**
- Empty states are text-only — spec calls for "Illustration + CTA text"
- Copy button on PhraseCard uses emoji 📋 — inconsistent with SVG icon pattern elsewhere
- No error banner with retry button (spec: "Error banner with retry button")
- No offline detection banner (spec: "You're offline — some features unavailable")
- No success toast component for phrase submission

**Fix:** Replace 📋 emoji with SVG icon. Add illustration placeholders for empty states. Implement error/offline banners.

---

## 3. Color — 3/4

**What works:**
- Primary `#4CAF50` used consistently via `text-primary`, `bg-primary`, `focus:ring-primary`
- Semantic tokens used correctly: `bg-background`, `bg-card`, `text-muted-foreground`, `text-destructive`
- VoiceInput state colors: green (idle), red (listening/pulsing), yellow (error) — clear visual language
- VoiceOutput: `bg-primary/10` idle → `bg-primary` speaking — intuitive state progression
- Spam warning uses `text-yellow-600` — visible but distinguishable from errors

**Gaps:**
- Spam warning uses hardcoded `text-yellow-600` instead of semantic token (should be `text-warning` or similar)
- Dark mode configured in tailwind (`darkMode: ["class", ""]`) but no `dark:` variants used anywhere
- VoiceInput error state `bg-yellow-100` may lack contrast on light backgrounds
- No color differentiation between upvote/downvote buttons beyond hover state

**Fix:** Add semantic warning color token. Implement dark mode variants. Add color distinction for vote buttons.

---

## 4. Typography — 3/4

**What works:**
- Inter font configured in layout.tsx ✅
- Clear hierarchy: `text-2xl font-bold` (page titles) → `text-xl font-bold` (modal) → `text-lg font-semibold` (sections) → `text-sm` (body) → `text-xs` (metadata)
- Translation result: `text-2xl font-medium text-primary` ✅ matches spec
- Language labels: `text-xs text-muted-foreground capitalize` — clean

**Gaps:**
- No `tabular-nums` for numerical data (confidence %, vote counts, leaderboard scores)
- "Confidence: 85%" and "▲ 42" would align better with tabular numbers
- Font weight `font-medium` used for both labels and values in some places — could tighten hierarchy
- No `tracking-tight` on large headings for polish

**Fix:** Add `tabular-nums` to data display elements. Use `tracking-tight` on page headings.

---

## 5. Spacing — 4/4

**What works:**
- Container: `container mx-auto px-4 py-8 max-w-2xl` ✅ matches spec
- Card padding: `p-4`, `p-6` ✅ consistent
- Gap scale: `gap-2`, `gap-3`, `gap-4` — logical progression
- Modal: `p-6` with `space-y-4` between fields — comfortable density
- SearchFilterBar: `flex-col sm:flex-row gap-3` — responsive stacking works well
- Community page: `max-w-5xl` for wider grid — intentional and correct
- Leaderboard: `space-y-2` with `p-4` — dense but readable
- All components use consistent spacing tokens

**No gaps found.** Spacing is the strongest pillar.

---

## 6. Experience Design — 3/4

**What works:**
- VoiceInput: Toggle start/stop, auto-stop on 2s silence, hidden when unsupported ✅
- VoiceOutput: Toggle speak/stop, hidden when unsupported or no text ✅
- ContributePhraseModal: Escape to close, backdrop click to close, focus management, form validation, spam detection ✅
- UserFollowCard: Optimistic UI with error rollback ✅
- SearchFilterBar: Real-time search, filter chips, sort dropdown ✅
- Responsive grid: 1 col → 2 col → 3 col progression ✅
- Accessibility: `aria-label`, `role="dialog"`, `aria-modal="true"`, keyboard Escape ✅

**Gaps:**
- **No focus trap in modal** — spec calls for "Focus trap while open"; Tab can escape the modal
- **Inconsistent navigation** — Translate page nav has 3 links (Translate, History, Settings) while Community/Social pages have 5 links (adds Community, Social). Translate page is missing Community and Social nav links
- **No Web Share API** — WEB-SHARE-01 requirement only partially met (copy-to-clipboard works, but `navigator.share` not implemented)
- **No offline detection** — spec calls for offline banner
- **No error retry** — spec calls for "Error banner with retry button"
- **Local history on translate page** doesn't sync with `/history` page — confusing UX

**Fix:** Add focus trap to modal. Unify nav across all pages. Implement Web Share API. Add offline detection.

---

## Top 5 Fixes (Priority Order)

1. **Unify navigation** — Add Community/Social links to translate and history page navs (missing on 2 of 5 pages)
2. **Add focus trap to modal** — ContributePhraseModal needs Tab confinement for accessibility
3. **Implement Web Share API** — WEB-SHARE-01 requirement: use `navigator.share()` with clipboard fallback
4. **Add success toast** — Phrase submission needs visible confirmation ("Phrase submitted for review!")
5. **Add tabular-nums** — Confidence %, vote counts, leaderboard scores need `tabular-nums` for alignment

---

## UI-SPEC Compliance Checklist

| Spec Requirement | Status |
|-----------------|--------|
| Mic button on translate page | ✅ Implemented |
| Voice states (idle/listening/processing/error) | ✅ Implemented |
| Auto-stop on 2s silence | ✅ Implemented |
| Graceful degradation (hidden when unsupported) | ✅ Implemented |
| Speaker button with animated feedback | ✅ Implemented |
| Speed/pitch controls in settings | ✅ Implemented |
| Community card grid responsive | ✅ Implemented |
| SearchFilterBar with search/filter/sort | ✅ Implemented |
| Loading skeletons | ✅ Implemented |
| Empty states | ⚠️ Text only, no illustrations |
| Contribute modal with validation | ✅ Implemented |
| Spam detection on submit | ✅ Implemented |
| Social page with tabs | ✅ Implemented |
| Activity feed with real-time | ✅ Implemented |
| Leaderboard with top-3 medals | ✅ Implemented |
| Follow/unfollow with optimistic UI | ✅ Implemented |
| Focus trap in modal | ❌ Missing |
| Error banner with retry | ❌ Missing |
| Offline banner | ❌ Missing |
| Web Share API | ⚠️ Partial (clipboard only) |

**Compliance: 17/20 (85%)**
