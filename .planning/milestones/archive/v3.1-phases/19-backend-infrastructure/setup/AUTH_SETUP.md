# Auth Provider Configuration Guide

**Phase:** 19 — Backend Infrastructure
**Date:** 2026-03-31

---

## 1. Email/Password Auth (Default)

Email auth is enabled by default in Supabase.

### Configuration
1. Dashboard → Authentication → Providers
2. Ensure "Email" is enabled
3. Configure email settings:
   - **Enable email confirmations**: Recommended for production
   - **Secure email change**: Enable to require confirmation for email changes
   - **Enable double opt-in**: Recommended

### Email Templates
Customize templates at Dashboard → Authentication → Email Templates:
- **Confirm signup**: Welcome message with app branding
- **Invite user**: Invitation template
- **Magic link**: Login link template
- **Change email address**: Confirmation template
- **Reset password**: Password reset template

Template variables available: `{{ .ConfirmationURL }}`, `{{ .Email }}`, `{{ .Token }}`, `{{ .Data }}`

---

## 2. Google OAuth

### Step 1: Create Google Cloud Project
1. Go to https://console.cloud.google.com
2. Create new project: "WoofTalk"
3. Enable "Google+ API" (for user profile data)

### Step 2: Configure OAuth Consent Screen
1. Go to APIs & Services → OAuth consent screen
2. Select "External" user type
3. Fill in:
   - App name: "WoofTalk"
   - User support email: your email
   - Developer contact email: your email
4. Add scopes: `email`, `profile`, `openid`
5. Add test users (until app is verified by Google)

### Step 3: Create OAuth 2.0 Credentials
1. Go to APIs & Services → Credentials
2. Create "OAuth client ID"
3. Application type: "Web application"
4. Authorized redirect URIs:
   ```
   https://your-project-id.supabase.co/auth/v1/callback
   ```
5. Save Client ID and Client Secret

### Step 4: Configure in Supabase
1. Dashboard → Authentication → Providers
2. Enable "Google"
3. Paste Client ID and Client Secret
4. Save

---

## 3. Apple Sign In

### Step 1: Create App ID
1. Go to https://developer.apple.com/account
2. Certificates, Identifiers & Profiles → Identifiers
3. Create new App ID:
   - Description: "WoofTalk"
   - Bundle ID: `com.wooftalk.app`
   - Enable "Sign in with Apple" capability

### Step 2: Create Service ID
1. Identifiers → Create new → "Services IDs"
2. Description: "WoofTalk Web"
3. Identifier: `com.wooftalk.web`
4. Configure "Sign in with Apple":
   - Primary App ID: `com.wooftalk.app`
   - Return URLs:
     ```
     https://your-project-id.supabase.co/auth/v1/callback
     ```
   - Domains: `your-project-id.supabase.co`

### Step 3: Create Key
1. Keys → Create new key
2. Name: "WoofTalk Sign In"
3. Enable "Sign in with Apple"
4. Configure:
   - Primary App ID: `com.wooftalk.app`
5. Download the `.p8` file (only downloadable once!)
6. Note the Key ID

### Step 4: Configure in Supabase
1. Dashboard → Authentication → Providers
2. Enable "Apple"
3. Fill in:
   - **Client ID**: Your Service ID (`com.wooftalk.web`)
   - **Secret**: Generate JWT from your `.p8` key (see below)
   - **Key ID**: From Step 3
   - **Team ID**: From Apple Developer account

### Generating Apple Secret (JWT)
```bash
# Generate JWT token (valid for 6 months max)
# Use this script or a JWT library:
import jwt
import time

key_id = "YOUR_KEY_ID"
team_id = "YOUR_TEAM_ID"
client_id = "com.wooftalk.web"
private_key = open("AuthKey_YOUR_KEY_ID.p8").read()

token = jwt.encode(
    {
        "iss": team_id,
        "iat": int(time.time()),
        "exp": int(time.time()) + 86400 * 180,  # 6 months
        "aud": "https://appleid.apple.com",
        "sub": client_id,
    },
    private_key,
    algorithm="ES256",
    headers={"kid": key_id},
)
print(token)
```

---

## 4. Auth Hooks for Platform Detection

### Custom User Metadata
When users sign up, include platform in metadata:

**iOS (Swift):**
```swift
let options = AuthOptions(
    redirectTo: "com.wooftalk://callback",
    data: ["platform": "ios"]
)
try await supabase.auth.signUp(email: email, password: password, options: options)
```

**Android (Kotlin):**
```kotlin
supabase.auth.signUpWith(
    Email(email, password) {
        data = mapOf("platform" to "android")
    }
)
```

### Database Trigger for Platform Tracking
Add to `003_functions_triggers.sql`:
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, platform, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'platform', 'unknown'),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 5. Verification Checklist

- [ ] Email auth working (sign up, sign in, password reset)
- [ ] Google OAuth working (sign in with Google account)
- [ ] Apple Sign In working (sign in with Apple ID)
- [ ] Email templates customized with WoofTalk branding
- [ ] Platform metadata captured on signup
- [ ] User records created in `users` table on auth
- [ ] Token refresh working (tokens expire after 1 hour by default)
