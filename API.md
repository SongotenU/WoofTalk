# WoofTalk API Documentation

Base URL: `https://your-supabase-project.supabase.co`

All API requests require authentication via Supabase JWT token in the `Authorization` header:
```
Authorization: Bearer <supabase_jwt_token>
```

---

## Supabase Edge Functions

### 1. Translate
**POST** `/functions/v1/translate`

Translates text between human and animal languages with entitlement check for premium features.

#### Request
```json
{
  "text": "Hello doggy",
  "sourceLanguage": "human",
  "targetLanguage": "dog",
  "voiceInput": false
}
```

#### Response
```json
{
  "translation": "Woof woof!",
  "confidence": 0.95,
  "audioUrl": "https://...storage.../audio.mp3",
  "isPremium": true
}
```

#### Rate Limit
100 requests per minute per user (enforced via Supabase Edge Function middleware)

#### Errors
- `401 Unauthorized` — Invalid/missing JWT
- `403 Forbidden` — Premium feature, no active subscription
- `429 Too Many Requests` — Rate limit exceeded
- `500` — Translation engine error

---

### 2. Phrase Search
**GET** `/functions/v1/phrases/search?q=<query>&limit=20&offset=0`

Full-text search across community phrases.

#### Query Parameters
| Param | Type | Default | Description |
|--------|------|---------|-------------|
| q | string | — | Search query |
| limit | number | 20 | Max results (max 100) |
| offset | number | 0 | Pagination offset |
| language | string | "dog" | Filter by language (dog/cat/bird) |

#### Response
```json
{
  "phrases": [
    {
      "id": "uuid",
      "text": "Woof woof!",
      "translation": "Hello!",
      "language": "dog",
      "upvotes": 42,
      "author": { "username": "doglover" },
      "created_at": "2026-05-05T12:00:00Z"
    }
  ],
  "total": 156
}
```

---

### 3. Leaderboard
**GET** `/functions/v1/leaderboard?period=week&limit=50`

Computed leaderboard of top translators.

#### Query Parameters
| Param | Type | Default | Description |
|--------|------|---------|-------------|
| period | string | "week" | "day", "week", "month", "all" |
| limit | number | 50 | Max results (max 100) |

#### Response
```json
{
  "leaderboard": [
    {
      "user_id": "uuid",
      "username": "wooftalker",
      "translation_count": 89,
      "recent_translations": 12,
      "rank": 1
    }
  ]
}
```

---

### 4. Activity Batch
**POST** `/functions/v1/activity/batch`

Batch activity creation for performance optimization.

#### Request
```json
{
  "activities": [
    {
      "type": "translation",
      "payload": { "sourceLanguage": "human", "targetLanguage": "dog" }
    }
  ]
}
```

#### Response
```json
{
  "created": 5,
  "failed": 0
}
```

---

### 5. Send Push Notification
**POST** `/functions/v1/send-push-notification`

Sends FCM push notification to a user (called internally or via webhook).

#### Request
```json
{
  "userId": "uuid",
  "title": "New follower!",
  "body": "User @doglover started following you",
  "data": { "type": "follow", "userId": "uuid" }
}
```

#### Response
```json
{
  "success": true,
  "messageId": "fcm-message-id"
}
```

---

## Supabase REST API (Auto-Generated)

Base URL: `/rest/v1/`

### Tables

#### `profiles`
```
GET /rest/v1/profiles?id=eq.<user_id>
POST /rest/v1/profiles
PATCH /rest/v1/profiles?id=eq.<user_id>
```

#### `translations`
```
GET /rest/v1/translations?user_id=eq.<user_id>&order=created_at.desc
POST /rest/v1/translations
```

#### `community_phrases`
```
GET /rest/v1/community_phrases?language=eq.dog&order=upvotes.desc
POST /rest/v1/community_phrases
PATCH /rest/v1/community_phrases?id=eq.<phrase_id>
```

#### `social_follows`
```
GET /rest/v1/social_follows?follower_id=eq.<user_id>
POST /rest/v1/social_follows
DELETE /rest/v1/social_follows?follower_id=eq.<user_id>&following_id=eq.<target_id>
```

#### `activity_logs`
```
GET /rest/v1/activity_logs?user_id=eq.<user_id>&order=created_at.desc&limit=50
POST /rest/v1/activity_logs
```

---

## Authentication

### Sign Up
```
POST /auth/v1/signup
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

### Sign In
```
POST /auth/v1/token?grant_type=password
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

### OAuth (Google/Apple)
```
GET /auth/v1/authorize?provider=google&redirect_to=https://wooftalk.app/callback
```

---

## Rate Limiting

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Edge Functions | 100 req/min | Per user (JWT) |
| REST API | 200 req/min | Per user (JWT) |
| Auth endpoints | 10 req/min | Per IP |

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1714920000
```

---

## React Hooks (Web)

### `useSupabase()`
```typescript
const { supabase, user, loading } = useSupabase()
```

### `useTranslation()`
```typescript
const { translate, result, loading, error } = useTranslation()
```

### `useCommunityPhrases()`
```typescript
const { phrases, search, loading } = useCommunityPhrases()
```

---

## SDK Usage

### iOS (Swift)
```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "https://...supabase.co")!,
    anonKey: "your-anon-key"
)

// Sign in
try await client.auth.signIn(email: "user@example.com", password: "pass")

// Fetch translations
let translations: [Translation] = try await client
    .from("translations")
    .select()
    .eq("user_id", userId)
    .order("created_at", ascending: false)
    .execute()
    .value
```

### Android (Kotlin)
```kotlin
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth

val supabase = SupabaseClient(
    supabaseUrl = "https://...supabase.co",
    supabaseKey = "your-anon-key"
)

// Sign in
supabase.auth.signInWith(Email) { email = "user@example.com"; password = "pass" }

// Fetch translations
val translations = supabase.from("translations")
    .select { eq("user_id", userId) }
    .decodeList<Translation>()
```

---

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK — request successful |
| 201 | Created — resource created |
| 400 | Bad Request — invalid parameters |
| 401 | Unauthorized — invalid/missing JWT |
| 403 | Forbidden — insufficient permissions (RLS) |
| 404 | Not Found — resource not found |
| 429 | Too Many Requests — rate limit exceeded |
| 500 | Internal Server Error — server error |

---

## Webhooks (RevenueCat → Supabase)

RevenueCat sends subscription events to `/functions/v1/webhooks/revenuecat`:
- `INITIAL_PURCHASE` — New subscription
- `RENEWAL` — Subscription renewed
- `CANCELLATION` — Subscription cancelled
- `EXPIRATION` — Subscription expired

---
