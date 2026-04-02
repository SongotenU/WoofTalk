# API Gateway Environment Variables

Set these on both `api-gateway` and `api-key-manage` Edge Functions.

## Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key for DB writes | `eyJ...` |

## Required for Rate Limiting

| Variable | Description | Example |
|----------|-------------|---------|
| `UPSTASH_REDIS_REST_URL` | Upstash Redis REST URL | `https://xxx.upstash.io` |
| `UPSTASH_REDIS_TOKEN` | Upstash Redis token | `xxx` |

## Deploy

```bash
# Deploy api-gateway
supabase functions deploy api-gateway --project-ref <your-project-ref>

# Deploy api-key-manage
supabase functions deploy api-key-manage --project-ref <your-project-ref>

# Set secrets (replace with your values)
supabase secrets set --project-ref <your-project-ref> \
  SUPABASE_URL="https://xxxx.supabase.co" \
  SUPABASE_SERVICE_ROLE_KEY="eyJ..." \
  UPSTASH_REDIS_REST_URL="https://xxx.upstash.io" \
  UPSTASH_REDIS_TOKEN="xxx"
```

## Test

```bash
# Without key (expect 401)
curl -i https://xxx.supabase.co/functions/v1/api-gateway/v1/languages

# With invalid key (expect 401)
curl -i -H "Authorization: Bearer invalid" https://xxx.supabase.co/functions/v1/api-gateway/v1/languages

# With valid key
curl -i -H "Authorization: Bearer wt_live_xxx" https://xxx.supabase.co/functions/v1/api-gateway/v1/languages

# POST translate
curl -i -X POST \
  -H "Authorization: Bearer wt_live_xxx" \
  -H "Content-Type: application/json" \
  -d '{"source_language":"human","target_language":"dog","text":"hello"}' \
  https://xxx.supabase.co/functions/v1/api-gateway/v1/translate

# Generate API key
curl -i -X POST \
  -H "Authorization: Bearer <SUPABASE_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-test-key","scope":"translate:full"}' \
  https://xxx.supabase.co/functions/v1/api-key-manage/keys
```
