# Phase 53: Feature Gating & Soft Paywall - Execution Plan

**Goal**: Free users experience clear limits (3 translations/day, last 10 history, locked premium features) with non-blocking upgrade paths; premium users have unrestricted access.

**Depends on**: Phase 51, Phase 52

**Requirements**: GATE-01 through GATE-09 (9 total)

## Execution Strategy

**4 waves**: entitlement middleware → translation gating → feature gating → watch app integration

### Wave 1: Entitlement Manager Extension
- Extend EntitlementManager wrapper (iOS, Android, Web) to include `isPremium`, `isTrialActive`, and `dailyTranslationsUsed` properties.
- Implement server-side daily translation count via Edge Function or RLS policy (building on Phase 51 subscription backend).
- Ensure entitlement state updates in real-time after purchases.

### Wave 2: Translation Gating
- Modify translation request flow to check daily limit (3 translations/day) for free users.
- Block translation attempts beyond limit with non-blocking upgrade prompt linking to paywall.
- Update history retrieval to return only last 10 items for free users; premium users get full history.
- Display lock icon on translation button when free tier limit reached.

### Wave 3: Feature Gating for Premium Features
- Restrict AI translation, community phrase contribution, and export/share features to premium users.
- Show upgrade prompt (non-blocking modal/toast) when free users attempt these actions.
- Display lock icons on disabled premium features in UI.
- Ensure upgrade prompt links directly to paywall for seamless conversion.

### Wave 4: Watch App & Cross-Platform Sync
- Implement watch app subscription status inheritance from paired phone (no separate purchase required).
- Ensure watch app respects same feature gating and limits as phone.
- Test cross-platform entitlement sync (purchase on phone unlocks premium on watch immediately).

## Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| Backend latency for daily limit check | Cache entitlement state locally with short TTL; validate periodically via lightweight endpoint. |
| Inconsistent UI states across platforms | Use shared EntitlementManager interface; unit tests for gating logic. |
| WatchOS complications with shared dependencies | Reuse phone's subscription status via Watch Connectivity framework (iOS) / equivalent on Android. |

## Success Criteria

1. ✅ Free users limited to 3 translations/day (server-enforced) and can only see last 10 history items; premium users have unlimited history.
2. ✅ AI translation, community phrase contribution, and export/share restricted to premium users — free users see upgrade prompts when attempting these features.
3. ✅ EntitlementManager wrapper provides `isPremium`, `isTrialActive`, and `dailyTranslationsUsed` on all platforms.
4. ✅ After the 3rd translation, free users see a non-blocking upgrade prompt linking to paywall; premium features display lock icons when user is on free tier.
5. ✅ Watch app inherits phone subscription status with no separate purchase required.

---