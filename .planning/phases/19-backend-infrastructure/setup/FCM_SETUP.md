# Firebase Cloud Messaging Setup

## 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create project: "WoofTalk"

## 2. Generate Server Key
1. Project Settings → Cloud Messaging
2. Copy "Server key" → set as `FCM_SERVER_KEY` env var in Supabase

## 3. Configure Supabase Edge Function
1. Dashboard → Edge Functions → Settings
2. Set env var: `FCM_SERVER_KEY=your-key`
3. Deploy `send-push-notification` function

## 4. Android Client Setup
1. Add Firebase to Android app (google-services.json)
2. Implement FCM token registration
3. Send token to Supabase `push_notifications` table on login

## 5. Testing
```bash
curl -X POST https://your-project-id.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```
