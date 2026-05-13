# Phase 57: Web Production Deployment — PLAN

**Goal**: Deploy Next.js web app to production with proper configuration and environment setup.

**Depends on**: Phase 56 (Android Build Fixes)

**Requirements**: WEB-01, WEB-02, WEB-03, WEB-04, WEB-05

**Success Criteria** (what must be TRUE):
1. ✅ Web app builds successfully with 0 errors
2. Web app deployed to production URL (Vercel)
3. Environment variables properly configured (Supabase, RevenueCat)
4. Supabase production connection verified
5. RevenueCat web SDK functioning
6. PWA features working (service worker, offline support, manifest)

---

## Plans

### 57-01: ✅ Fix Web App Build Errors
**File**: `web/src/lib/supabase.ts`, `web/next.config.ts`, `web/src/app/translate/page.tsx`, `web/src/hooks/useSpeechRecognition.ts`
**Goal**: Fix static prerendering errors caused by missing env vars at build time
**Verification**: `cd web && npm run build` succeeds with 0 errors

**Steps Completed**:
1. ✅ Made Supabase client initialization dynamic (lazy initialization in `supabase.ts`)
2. ✅ Updated `/admin/page.tsx` to use `export const dynamic = 'force-dynamic'`
3. ✅ Updated `/invite/accept/page.tsx` to use `export const dynamic = 'force-dynamic'`
4. ✅ Fixed `translate/page.tsx` - restructured with `TranslateContent` wrapper and dynamic export
5. ✅ Fixed `useSpeechRecognition.ts` - moved `SpeechRecognitionAPI` inside hook to prevent server-side `window` access
6. ✅ Fixed `useSpeechSynthesis.ts` - added `typeof window` checks
7. ✅ Fixed `push.ts` - added `typeof window` check in `urlBase64ToUint8Array`
8. ✅ Updated `next.config.ts` with `outputFileTracingRoot` to fix workspace warning
9. ✅ Fixed `layout.tsx` - added `viewport` export to fix metadata warnings

**Result**: Build succeeds with all 57 pages generated.

---

### 57-02: Production Environment Configuration
**File**: `.env.example`, Vercel project settings
**Goal**: Ensure all production environment variables are documented and configured
**Verification**: All required env vars present in `.env.example` and Vercel dashboard

**Steps**:
1. Review current `.env.example` for completeness
2. Add `NEXT_PUBLIC_REVENUECAT_WEB_API_KEY` if missing
3. Document required Vercel environment variables
4. Verify `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are set

---

### 57-03: Deploy to Vercel (Production)
**File**: `.github/workflows/web-deploy.yml`
**Goal**: Ensure Vercel deployment workflow is complete and functional
**Verification**: Successful deployment to production URL

**Steps**:
1. Review existing `web-deploy.yml` workflow
2. Verify Vercel secrets are set in GitHub repository
3. Trigger deployment and verify success
4. Add production health check step

---

### 57-04: Verify Supabase Production Connection
**File**: N/A (verification task)
**Goal**: Confirm web app connects to production Supabase instance
**Verification**: Production app can query Supabase, auth works, realtime subscriptions work

**Steps**:
1. Test production app loads without Supabase connection errors
2. Test authentication flow (sign in/sign up)
3. Test realtime subscriptions (activity feed, translations)

---

### 57-05: Test RevenueCat Web SDK
**File**: `web/src/lib/purchases-web.ts`, `web/src/lib/revenuecat.ts`
**Goal**: Verify RevenueCat web SDK is properly initialized and purchase flow works
**Verification**: Subscription offerings load, checkout flow works

**Steps**:
1. Check RevenueCat JS SDK initialization
2. Verify `EntitlementProvider` correctly wraps app
3. Test `/subscribe` page loads with offerings

---

### 57-06: Verify PWA Features
**File**: `web/public/manifest.json`, `web/public/sw.js`, `web/next.config.ts`
**Goal**: Ensure PWA features work in production
**Verification**: App can be installed as PWA, works offline

**Steps**:
1. Verify `manifest.json` exists and has correct fields
2. Check service worker registration (next-pwa)
3. Run Lighthouse PWA audit on production URL
