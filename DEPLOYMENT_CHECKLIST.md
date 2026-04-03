# Deployment Checklist — WoofTalk Cross-Platform

## 1. Backend Deployment

### Supabase
- [ ] **Migrations**: Execute in order
  - 0009_arvr_data_model.sql (`ALTER TABLE translation_history`, `CREATE TABLE dog_avatars`, `CREATE TABLE user_devices`)
  - 0010_rls_arvr_tables.sql (RLS policies for new tables)
- [ ] **Edge Functions**: Deploy all functions
  ```bash
  supabase functions deploy translate
  supabase functions deploy community
  supabase functions deploy leaderboard
  supabase functions deploy phrases-search
  supabase functions deploy activity-batch
  ```
- [ ] **Database**: Verify tables exist, RLS policies active, indexes created
- [ ] **Redis**: Upstash Redis configured for rate limiting
- [ ] **Credentials**: API keys, service roles, webhook secrets rotated

### Environment Variables
| Variable | Description | Required For |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | All clients |
| `SUPABASE_ANON_KEY` | Public anon key | All clients |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin access (edge functions only) | Backend |
| `OPENAI_API_KEY` | AI translation service | Translate function |
| `RESEND_API_KEY` | Email invites | Web/Backend |

## 2. Frontend Deployment

### iOS / visionOS
- [ ] Build in Xcode with Release configuration
- [ ] Archive and upload to App Store Connect
- [ ] Submit for review (App Store or TestFlight for beta)
- [ ] Verify: translation, voice I/O, community features, AR overlay (visionOS)

### Android
- [ ] Build signed APK/AAB in Android Studio
- [ ] Upload to Google Play Console (internal testing → production)
- [ ] Verify: translation, voice I/O, community features, sync with iOS

### Web
- [ ] Deploy to Vercel/Netlify: `git push` triggers deploy from `web/`
- [ ] Environment variables configured in Vercel dashboard
- [ ] Custom domain + SSL configured
- [ ] Verify: voice input (Web Speech API), community browser, PWA install

### Smartwatch (Wear OS)
- [ ] Build signed AAB in Android Studio
- [ ] Upload to Google Play Console (Wear OS track)
- [ ] Verify: voice input, glanceable results, sync with phone app

## 3. AR/VR Deployment

### Vision Pro (AR)
- [ ] Archive visionOS build in Xcode
- [ ] Upload to App Store Connect
- [ ] TestFlight distribution for beta testing
- [ ] Verify: camera passthrough, bark detection, spatial audio, bubble positioning

### Meta Quest (VR)
- [ ] Build Android APK (IL2CPP, ARM64)
- [ ] Submit to Meta Quest Store or App Lab
- [ ] Verify: hand tracking, environment switching, performance (72/90 FPS)
- [ ] iPhone ARKit fallback available for non-Vision Pro users

## 4. Post-Deployment Validation

### Automated Checks
- [ ] Run consumer regression suite: `./scripts/e2e-consumer-regression.sh`
- [ ] Verify all 4 Edge Functions return correct responses
- [ ] Check RLS isolation: org members cannot access other org data

### Manual Checks
- [ ] Translation accuracy test (5+ languages)
- [ ] Voice I/O latency measurement (<2s response time)
- [ ] Community phrase CRUD operations
- [ ] Social features (follow, leaderboards, activity feed)
- [ ] Admin dashboard moderation tools
- [ ] Organization management (invites, roles, API keys)

## 5. Rollback Plan

- **Supabase**: Re-run previous migration if needed (create down-migration first)
- **Edge Functions**: Deploy previous version via `supabase functions deploy --version <prev>`
- **Web**: Vercel rollbacks via dashboard (instant)
- **Mobile**: Previous App Store/Play Store version remains available until update approved
- **AR/VR**: Previous TestFlight/App Lab build remains available

---

*Last updated: 2026-04-03 | Phase 42: Cross-Platform Integration*
