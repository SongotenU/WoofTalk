# Pitfalls Research: M009 Subscription & Payments

**Domain:** Common mistakes when adding subscription/payments with RevenueCat to multi-platform apps
**Researched:** 2026-04-14
**Confidence:** HIGH

---

## Critical Pitfalls (7)

### Pitfall 1: App Store Review Guideline 3.1.1 — No External Payment Links

**What goes wrong:**
Apple requires ALL digital purchases on iOS to go through StoreKit. Including a link to Stripe/web payment or even mentioning alternative pricing violates Guideline 3.1.1. This is the #1 reason subscription apps get rejected.

**Why it happens:**
- Developers add "cheaper on web" links to bypass Apple's 30% commission
- Cross-platform apps sometimes show web payment options inside the iOS app
- Even text like "Subscribe on our website for a discount" triggers rejection

**Prevention:**
1. iOS app uses ONLY StoreKit via RevenueCat SDK — no Stripe, no web payment links
2. Never show web pricing in the iOS app
3. iOS paywall shows only Apple-processed prices
4. Web/app pricing parity: do NOT offer cheaper web pricing visible in the iOS app

**Phase to address:** Phase 52 (Paywall UI) — iOS paywall must be StoreKit-only

---

### Pitfall 2: Stale Entitlement Cache After Purchase

**What goes wrong:**
User completes purchase, but `CustomerInfo` still shows free tier because the SDK cache hasn't refreshed. User thinks purchase failed and tries again, causing double-purchase or support tickets.

**Why it happens:**
- RevenueCat SDK caches `CustomerInfo` and updates on SDK calls (not pushed)
- If app doesn't call any SDK method after purchase, cache stays stale
- Network delays on RevenueCat's receipt validation

**Prevention:**
1. After purchase, immediately call `Purchases.shared.getCustomerInfo()` to force refresh
2. Use `PurchasesDelegate` / listener to react to `CustomerInfo` updates
3. Show loading state after purchase until entitlement is confirmed
4. Never rely on local state — always check `CustomerInfo.activeEntitlements`

**Phase to address:** Phase 50 (SDK Integration) — delegate/listener setup must be correct

---

### Pitfall 3: Free Tier Bypass via API Direct Calls

**What goes wrong:**
Client-side entitlement checks prevent free users from accessing premium features in the app UI, but API calls bypass the client entirely. A technical user can call Edge Functions directly with a valid auth token and get unlimited translations.

**Why it happens:**
- RLS policies don't enforce translation limits
- Edge Functions trust client headers without server-side entitlement verification
- Rate limiter uses fixed limits regardless of subscription tier

**Prevention:**
1. RLS policy on `translation_requests`: free users limited to 3 INSERTs per day
2. Edge Functions check `subscription_status` table before processing
3. API Gateway rate limits tiered by subscription (free: 3/day, pro: 100/day)
4. Server-side is the hard gate; client-side is the UX layer

**Phase to address:** Phase 51 (Subscription Backend) — RLS + Edge Function enforcement

---

### Pitfall 4: Cross-Platform Entitlement Desync

**What goes wrong:**
User subscribes on iOS, but Android app still shows free tier. Or user cancels on web, but iOS app still shows premium. Entitlements don't sync across platforms.

**Why it happens:**
- RevenueCat uses `appUserID` to identify users across platforms
- If iOS uses anonymous ID and Android uses different auth ID, they're separate customers
- Web Stripe purchases create a different RevenueCat customer if not linked

**Prevention:**
1. Use Supabase `auth.uid` as RevenueCat `appUserID` on ALL platforms
2. Require login before showing paywall — no anonymous purchases
3. On app launch, call `Purchases.shared.logIn(auth.uid)` to ensure correct identity
4. Test: subscribe on iOS → verify entitlement on Android and Web within 30 seconds

**Phase to address:** Phase 50 (SDK Integration) — identity linking must use auth.uid

---

### Pitfall 5: Play Console Review — Subscription Pricing Mismatch

**What goes wrong:**
Google Play requires subscription prices to be configured in the Play Console BEFORE RevenueCat can offer them. If you create offerings in RevenueCat but forget to create the corresponding products in Play Console, the purchase flow fails silently or shows errors.

**Why it happens:**
- RevenueCat and Play Console are separate systems
- Product IDs must match exactly between RevenueCat and Play Console
- Play Console changes can take hours to propagate

**Prevention:**
1. Create products in App Store Connect AND Play Console FIRST, then configure in RevenueCat
2. Use identical product IDs across all platforms (e.g., `wooftalk_monthly`, `wooftalk_annual`)
3. Test with RevenueCat sandbox before submitting to stores
4. Verify products appear in `getOfferings()` before showing paywall

**Phase to address:** Phase 52 (Paywall UI) — product configuration must be complete

---

### Pitfall 6: Webhook Idempotency Failures

**What goes wrong:**
RevenueCat retries failed webhooks for up to 72 hours. If your Edge Function doesn't handle duplicate events, a single subscription can be recorded multiple times, corrupting `subscription_status`.

**Why it happens:**
- Edge Function times out (>400s for Deno)
- Edge Function returns non-2xx status code
- RevenueCat retries the same event, creating duplicate rows

**Prevention:**
1. Use `event_id` from RevenueCat webhook as idempotency key
2. Store processed `event_id`s in a table or check before updating
3. Always return 200 OK to RevenueCat quickly, process async if needed
4. Make updates idempotent: `UPDATE ... SET tier = 'pro' WHERE user_id = X` (not INSERT)

**Phase to address:** Phase 51 (Subscription Backend) — webhook handler must be idempotent

---

### Pitfall 7: Trial Abuse via Multiple Accounts

**What goes wrong:**
Users create multiple accounts to get unlimited free trials. Each new account gets 7 days of premium, so a user can keep creating accounts for perpetual free access.

**Why it happens:**
- Free trial tied to account, not device
- No device fingerprinting or anti-abuse measures
- Side project — limited resources for fraud prevention

**Prevention:**
1. Accept this as a low-risk issue for a dog translation app (not a high-value target)
2. RevenueCat's fraud detection catches obvious patterns
3. If abuse becomes measurable: add device-level trial tracking (iOS: `identifierForVendor`)
4. Consider requiring email verification before trial starts

**Phase to address:** Phase 53 (Feature Gating) — basic protection, don't over-engineer

---

## Additional Risks (Lower Priority)

- **Apple 30% commission**: iOS subscriptions lose 30% to Apple first year, 15% after. Budget accordingly.
- **Google 15% commission**: Play Store takes 15% (reduced from 30% for first $1M).
- **Stripe 2.9% + $0.30**: Web transactions have different fee structure.
- **Currency conversion**: Users in different countries see different prices. RevenueCat supports per-market pricing.
- **Tax handling**: RevenueCat doesn't handle tax reporting. Use Stripe Tax or manual accounting.
- **Play Console account verification**: Android requires app to verify purchases server-side (not just client-side). RevenueCat handles this.
- **App Tracking Transparency**: If collecting device info for trial abuse prevention, may need ATT prompt on iOS.
