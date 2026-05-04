# Milestones

## v1.0.0 M009 Subscription & Payments (Shipped: 2026-05-04)

**Phases completed:** 5 phases, 17 plans, 5 tasks

**Key accomplishments:**

- Status
- PostgreSQL migration with subscription_status table, tier-aware RLS policy enforcing 3/day free limit, and shared subscription utility module
- RevenueCat webhook Edge Function with Bearer token auth, 14-event-type switch handler, event_id idempotency, and always-200 response pattern
- Server-side entitlement verification with RevenueCat REST API, 5-minute DB-backed caching, and translate Edge Function tier gate blocking free-user overages
- Completed:

---

## v1.0.0 M009 - Subscription & Payments (Shipped: 2026-04-29)

**Phases completed:** 5 phases, 17 plans

**Key accomplishments:**

- Phase 50: RevenueCat SDK Integration — SDK initialized on all platforms, users identified by Supabase auth.uid, entitlements readable and reactive
- Phase 51: Subscription Backend — Server-side subscription authority, webhooks update status, RLS enforces free tier limits, Edge Functions verify entitlement
- Phase 52: Paywall UI — Users can view offerings, complete purchases through native payment flow, see entitlement confirmed on all platforms
- Phase 53: Feature Gating & Soft Paywall — Free users have clear limits (3 translations/day, last 10 history, locked premium), premium users unrestricted
- Phase 54: Cross-Platform Sync & Admin — Subscriptions activate entitlements across all platforms, admin dashboard monitors subscription health

**Key technical deliverables:**

- PostgreSQL migration with subscription_status table, tier-aware RLS policy enforcing 3/day free limit, shared subscription utility module
- RevenueCat webhook Edge Function with Bearer token auth, 14-event-type switch handler, event_id idempotency, always-200 response pattern
- Server-side entitlement verification with RevenueCat REST API, 5-minute DB-backed caching, translate Edge Function tier gate blocking free-user overages
- iOS/Watch sync via WatchSyncManager (WCSessionDelegate), Android sync with entitlement listener in MainActivity
- Web sync with useEntitlementSync hook + Supabase real-time, admin dashboard at /admin/subscriptions with Stripe portal link
- 120+ files modified across iOS, Android, Web, Backend, and Watch platforms

---

## v0.2.0 Production Hardening (Shipped: 2026-04-07)

**Phases completed:** 7 phases, 7 plans, 0 tasks

**Key accomplishments:**

- ✅ Memory leak elimination — NotificationCenter/Timer fixes, 156MB stable memory
- ✅ Structural cleanup — removed duplicate audio_processing, consolidated TranslationDirection, os_log adoption
- ✅ Performance optimization — TranslationCache connected, O(n²) → O(n), static phrase maps
- ✅ Resilience infrastructure — CircuitBreaker state machine, retry/backoff, timeout enforcement
- ✅ CI/CD automation — Supabase migrations, Vercel deployment, RLS audit gate
- ✅ Observability — ErrorReporter, uptime monitor (5-min), Slack alerts
- ✅ Scale testing — k6 load tests, concurrent RLS verification, rate limit validation

---

## v0.1.0 M007 AR/VR Mixed Reality (Shipped: 2026-04-04)

**Phases completed:** 5 phases, 21 plans, 9 tasks

**Key accomplishments:**

- Vision Pro AR app with ARKit/RealityKit, Core ML dog bark classifier, real-time camera passthrough, translation bubble rendering, and spatial audio
- AR spatial UX with gaze-based dog position estimation (raycast + hit-testing), bubble placement engine with distance clamping and billboarding, 90 FPS readability optimization
- Bubble pinning, manual placement gestures, environmental awareness with wall/furniture occlusion avoidance
- Meta Quest VR project with Unity 2022 LTS, Meta XR SDK v63, DogAvatar prefab with idle/bark/head-turn animations and Animator controller
- VR hand tracking via OVRHand with pinch detection, translation bubble system using TextMeshPro world-space UI with 5-bubble object pool, VR menu system
- VR bark detection with TFLite model integration (mock fallback), Oculus Spatializer for 3D audio attenuation and direction
- 3 virtual environments, dog avatar customization with Supabase Storage, Quest 2/3 performance presets (72/90 FPS), motion sickness mitigation, settings UI
- Cross-platform translation history sync, shared user settings, platform-specific analytics across iOS/Android/Web/Watch/AR/VR
- Database migrations: platform column, spatial_position JSONB, dog_avatars table, user_devices table, platform backfill, RLS policies
- App Store submission guides for Vision Pro and Meta Quest, deployment checklist, user documentation, fallback strategies for non-Vision Pro iOS devices

---
