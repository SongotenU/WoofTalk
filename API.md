# WoofTalk API Documentation

Base URL: `https://bzcyllgdetedwrifrgvc.supabase.co/functions/v1/`

All endpoints require authentication via Supabase JWT token in the `Authorization` header:
```
Authorization: Bearer <supabase_jwt_token>
```

Rate limiting: 100 requests per minute per user.

---

## Translation API

### `POST /translate`

Translates text or voice input to/from animal sounds. Checks user entitlement for premium features.

**Request:**
```json
{
  "input": "Hello dog",
  "inputType": "text",
  "sourceLanguage": "en",
  "targetAnimal": "dog",
  "voiceId": "en-US-Neural2-D",
  "userId": "user-uuid"
}
```

**Response (200 OK):**
```json
{
  "translation": "Woof woof!",
  "audioUrl": "https://supabase.co/storage/v1/object/public/translations/...",
  "detectedLanguage": "en",
  "remainingTranslations": 10
}
```

**Error Responses:**
- `401 Unauthorized` — Invalid or missing JWT
- `403 Forbidden` — Free user exceeded limit (premium required)
- `429 Too Many Requests` — Rate limit exceeded
- `500 Internal Server Error` — Translation service error

**Entitlement Check:**
- Free users: Last 10 translations accessible
- Premium users: Unlimited translations + voice input + sharing

---

## Phrase Search API

### `GET /phrases/search`

Full-text search across community phrases.

**Query Parameters:**
- `q` (required) — Search query
- `animal` (optional) — Filter by animal type (dog, cat, bird, etc.)
- `limit` (optional, default=20) — Max results
- `offset` (optional, default=0) — Pagination offset

**Request:**
```
GET /phrases/search?q=hello&animal=dog&limit=10
```

**Response (200 OK):**
```json
{
  "phrases": [
    {
      "id": "phrase-uuid",
      "text": "Hello dog",
      "translation": "Woof woof!",
      "animal": "dog",
      "language": "en",
      "contributorId": "user-uuid",
      "upvotes": 42,
      "downvotes": 3,
      "createdAt": "2026-05-01T10:00:00Z"
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

**Error Responses:**
- `401 Unauthorized` — Invalid or missing JWT
- `429 Too Many Requests` — Rate limit exceeded

---

## Leaderboard API

### `GET /leaderboard`

Returns computed leaderboard of top contributors.

**Query Parameters:**
- `period` (optional) — "daily", "weekly", "monthly", "all" (default: "weekly")
- `limit` (optional, default=50) — Max results

**Request:**
```
GET /leaderboard?period=weekly&limit=10
```

**Response (200 OK):**
```json
{
  "leaderboard": [
    {
      "userId": "user-uuid",
      "displayName": "DogLover123",
      "avatarUrl": "https://...",
      "score": 150,
      "translationsCount": 50,
      "contributionsCount": 30,
      "rank": 1
    }
  ],
  "period": "weekly",
  "generatedAt": "2026-05-05T10:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Invalid or missing JWT

---

## Activity Batch API

### `POST /activity/batch`

Creates multiple activity records in a single request (for batch sync).

**Request:**
```json
{
  "activities": [
    {
      "type": "translation",
      "userId": "user-uuid",
      "timestamp": "2026-05-05T10:00:00Z",
      "metadata": {
        "sourceLanguage": "en",
        "targetAnimal": "dog",
        "inputType": "text"
      }
    },
    {
      "type": "contribution",
      "userId": "user-uuid",
      "timestamp": "2026-05-05T10:05:00Z",
      "metadata": {
        "phraseId": "phrase-uuid"
      }
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "created": 2,
  "failed": 0,
  "errors": []
}
```

**Error Responses:**
- `401 Unauthorized` — Invalid or missing JWT
- `400 Bad Request` — Invalid activity format
- `429 Too Many Requests` — Rate limit exceeded

---

## Entitlement Check API

### `POST /entitlement-check`

Checks user's subscription entitlements (used internally by other functions).

**Request:**
```json
{
  "userId": "user-uuid"
}
```

**Response (200 OK):**
```json
{
  "isPremium": true,
  "subscriptionStatus": "active",
  "expiresAt": "2026-06-05T10:00:00Z",
  "entitlements": ["premium", "offline_mode", "unlimited_translations"]
}
```

**Error Responses:**
- `401 Unauthorized` — Invalid or missing JWT
- `404 Not Found` — User not found

---

## Webhook APIs

### `POST /revenuecat-webhook`

Receives RevenueCat webhook events for subscription changes.

**Headers:**
```
Content-Type: application/json
X-RevenueCat-Signature: <hmac_signature>
```

**Payload:**
```json
{
  "event": {
    "type": "INITIAL_PURCHASE",
    "app_id": "app-id",
    "original_app_user_id": "user-uuid",
    "product_id": "com.wooftalk.premium.monthly",
    "entitlement_ids": ["premium"],
    "expiration_at_ms": 1717500000000
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Webhook processed"
}
```

---

## Rate Limiting

All endpoints are rate-limited to 100 requests per minute per user.

**Headers in Response:**
- `X-RateLimit-Limit: 100`
- `X-RateLimit-Remaining: 95`
- `X-RateLimit-Reset: 1717500060`

When rate limit is exceeded (429):
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again in 30 seconds."
}
```

---

## Authentication

All API requests require a valid Supabase JWT token:

```javascript
// Get token from Supabase client
const { data: { session } } = await supabase.auth.getSession();
const token = session?.access_token;

// Use in API request
const response = await fetch('https://.../translate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({...})
});
```

---

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 401 | Unauthorized | Invalid or missing JWT token |
| 403 | Forbidden | Insufficient entitlements (free user limit exceeded) |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error (translation service, database, etc.) |

---

*Generated: 2026-05-05*
*Base URL: https://bzcyllgdetedwrifrgvc.supabase.co/functions/v1/*
