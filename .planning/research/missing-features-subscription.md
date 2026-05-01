# Subscription/Payment Feature Gaps

## Current State

WoofTalk has a basic subscription system implemented across phases 50-54:

**Implemented Features:**
- RevenueCat SDK integration (iOS, Web) with Supabase auth.uid identity linking
- Two subscription plans: monthly ($4.99/mo), annual ($39.99/yr) with 7-day free trial
- Single "pro" entitlement unlocking all premium features
- Free tier: 3 translations/day (enforced via RLS + client-side prompts)
- Paywall UI on iOS (RevenueCatUI), Android, and Web (/subscribe page)
- Feature gating: AI translation, community contribution, export/share locked for free users
- Server-side enforcement via subscription_status table and RLS policies
- RevenueCat webhook handling (entitlement-webhook Edge Function)
- Admin subscription viewer (read-only list with status filter, pagination)
- Entitlement sync via Supabase real-time + window focus polling
- Restore purchases functionality (iOS and Web)

**Product IDs:** `wooftalk_monthly`, `wooftalk_annual`
**Entitlement ID:** `pro`
**Free tier limit:** 3 translations per calendar day (UTC midnight reset)

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact | Notes |
|---|---------|----------|--------|--------|-------|
| 1 | **Cancellation feedback survey** | High | Low | High | DB column `cancellation_reason` exists (populated by RC webhooks), but NO client-side UI to collect reason from users at cancellation time. Adding an in-app survey feeds win-back strategy |
| 2 | **Win-back email campaigns** | High | Medium | High | Come-back offers for cancelled users; needs cancellation_reason (already tracked in DB) |
| 3 | **Promo code support** | High | Medium | High | Black Friday, influencer codes; RevenueCat offers/promotions API available |
| 4 | **Referral/affiliate program** | Medium | Medium | High | Invite friend get 1 month free; drives organic growth |
| 5 | **Subscription pause (vacation mode)** | Medium | Low | Medium | Dog boarding scenario; RevenueCat subscription pause API supported |
| 6 | **Downgrade flow with proration** | Medium | Medium | Medium | Annual → monthly mid-cycle; RevenueCat handles proration |
| 7 | **Loyalty rewards** | Medium | Medium | Medium | Year 2 discount, streak bonuses; increases retention |
| 8 | **Usage analytics dashboard for subscribers** | Medium | Medium | Medium | Show translation stats, savings; basic analytics exist in iOS but not subscriber-facing |
| 9 | **Student/senior discounts** | Low | Low | Medium | Targeted pricing; RevenueCat offerings can support this |
| 10 | **Gift subscriptions** | Low | Medium | Medium | Buy for another dog owner; RevenueCat gifting API available |
| 11 | **Family sharing (up to 5 members)** | Low | High | Medium | Apple/Google family sharing or custom; complex cross-platform |
| 12 | **Apple Pay/Google Pay one-tap checkout** | Low | Low | Low | Faster checkout; RevenueCat hosted checkout via Stripe supports Apple Pay |
| 13 | **Enterprise/veterinarian plans** | Low | High | Low | Multi-dog practices; needs custom tier + org management (M009 enterprise phase exists but separate) |
| 14 | **Usage-based pricing** | Low | High | Low | Pay per translation; fundamental business model change, conflicts with subscription model |
| 15 | **Crypto payment support** | Low | High | Low | Niche payment method; very low demand for pet app |

## Recommendations

### 1. Cancellation Feedback Survey + Win-Back Campaigns (Ship Together)
The `subscription_status` table already has a `cancellation_reason` column (populated by RevenueCat webhooks per 51-CONTEXT D-07). Adding a client-side survey on cancellation (2-3 questions) and automated win-back emails (come-back-with-20%-off offers) is the highest-leverage improvement. Effort: ~3-5 days. Requires: email service integration (Resend/SendGrid), survey UI on all platforms, delayed trigger logic.

### 2. Promo Code Support
RevenueCat's offerings/promotions API supports promo codes natively. This enables Black Friday campaigns, influencer codes, and targeted discounts. The infrastructure is partially there — the `/subscribe` page reads offerings dynamically. Adding a promo code input field that applies an offering discount is ~2-3 days of work. High revenue impact during promotional periods.

### 3. Referral/Affiliate Program
A "give 1 month, get 1 month free" program drives organic growth at low CAC. Implementation: add a referral code system in Supabase (referral_codes table, referral_events tracking), generate unique codes per user, validate on signup/purchase. RevenueCat's attribution API can help track referrals. Effort: ~5-7 days. Multi-platform: needs UI in Settings page showing user's referral code + share button.

## Implementation Notes

- **RevenueCat API coverage**: Most missing features (pause, promo codes, gifting, family sharing) have corresponding RevenueCat API endpoints — leverage them rather than building custom billing logic.
- **Enterprise track**: M009 (Enterprise phase) is already complete per team memory — veterinarian/multi-dog practice features should be evaluated under that existing work rather than as a new subscription feature.
- **Usage-based pricing** conflicts with the current subscription model and should be evaluated as a separate business decision before implementation.
- **Family sharing**: Apple's StoreKit family sharing applies automatically to auto-renewing subscriptions if enabled in App Store Connect — may already work on iOS without code changes. Verify before building custom solution.
