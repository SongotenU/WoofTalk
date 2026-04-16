# Phase 51: Subscription Backend - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 5 (new/modified)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `supabase/migrations/0013_subscription_status.sql` | migration | CRUD | `supabase/migrations/0001_organizations.sql` | exact |
| `supabase/functions/entitlement-webhook/index.ts` | controller | event-driven | `supabase/functions/send-push-notification/index.ts` | role-match |
| `supabase/functions/entitlement-check/index.ts` | controller | request-response | `supabase/functions/translate/index.ts` | exact |
| `supabase/functions/_shared/subscription.ts` | utility | request-response | `supabase/functions/_shared/middleware.ts` | exact |
| `supabase/functions/translate/index.ts` | controller | request-response | (self -- modifying) | exact |

## Pattern Assignments

### `supabase/migrations/0013_subscription_status.sql` (migration, CRUD)

**Analog:** `supabase/migrations/0001_organizations.sql`

**Table creation pattern** (lines 7-15):
```sql
CREATE TABLE IF NOT EXISTS public.organizations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    slug text NOT NULL UNIQUE,
    plan_type text NOT NULL DEFAULT 'free' CHECK (plan_type IN ('free', 'pro', 'enterprise')),
    owner_id uuid REFERENCES auth.users(id) NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
```

**RLS enable + policy pattern** (lines 17-24):
```sql
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage their org"
    ON public.organizations
    FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);
```

**Index pattern** (lines 36-37):
```sql
CREATE INDEX idx_organizations_slug ON public.organizations(slug);
CREATE INDEX idx_organizations_owner ON public.organizations(owner_id);
```

**updated_at trigger pattern** (lines 177-188):
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
```

**Secondary analog:** `supabase/migrations/0005_migrate_rls_policies.sql`

**DROP + CREATE policy pattern for translations** (lines 8-25) -- the exact policy being replaced:
```sql
DROP POLICY IF EXISTS "Users can insert own translations" ON public.translations;

CREATE POLICY "Users can insert own translations"
    ON public.translations FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

**RLS subquery pattern** (lines 17-21 of 0005) -- used for org-scoped checks, same technique for tier checks:
```sql
auth.uid() IN (
    SELECT om.user_id FROM public.organization_members om
    WHERE om.org_id = translations.org_id AND om.status = 'active'
)
```

**Secondary analog:** `supabase/migrations/0008_admin_audit_log.sql`

**Audit/event table with indexes** (lines 4-13):
```sql
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    action text NOT NULL,
    target_type text,
    target_id uuid,
    details jsonb DEFAULT '{}',
    ip_address text,
    created_at timestamptz DEFAULT now() NOT NULL
);
```

---

### `supabase/functions/entitlement-webhook/index.ts` (controller, event-driven)

**Analog:** `supabase/functions/send-push-notification/index.ts`

This is the closest analog because it is the only existing Edge Function that receives inbound requests and calls an external API. However, the webhook is unique in the codebase: it receives POST requests from RevenueCat (not from the app client) and authenticates via a shared secret (not validateAuth). The send-push-notification pattern shows external API integration with error handling.

**Imports pattern** (lines 1-3 of send-push-notification):
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';
```

**External API call pattern with Authorization header** (lines 41-48 of send-push-notification):
```typescript
const response = await fetch(FCM_ENDPOINT, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `key=${fcmServerKey}`,
  },
  body: JSON.stringify(payload),
});
```

**Error handling with catch block** (lines 59-63 of send-push-notification):
```typescript
} catch (_err) {
  await supabase.from('push_notifications').update({
    status: 'failed',
  }).eq('id', notification.id);
}
```

**Top-level try/catch + service role client pattern** (lines 7-17 of send-push-notification):
```typescript
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');

    if (!fcmServerKey) throw new Error('FCM_SERVER_KEY not configured');

    const supabase = createClient(supabaseUrl, supabaseKey);
```

**Secondary analog:** `supabase/functions/translate/index.ts`

**Standard Deno Edge Function response pattern** (lines 49-51 of translate):
```typescript
return new Response(JSON.stringify(data), {
  status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
});
```

**Note:** The webhook handler does NOT use validateAuth from middleware -- it authenticates via a Bearer token compared against `REVENUECAT_WEBHOOK_AUTH` env var (D-02). This is a new auth pattern in the codebase, similar to the FCM_SERVER_KEY env check in send-push-notification.

---

### `supabase/functions/entitlement-check/index.ts` (controller, request-response)

**Analog:** `supabase/functions/translate/index.ts`

This is the best analog because entitlement-check follows the same pattern as translate: validate Bearer auth, use service role client, query Supabase, and return a JSON response. The only addition is calling the RevenueCat REST API when cached data is stale.

**Full standard Edge Function pattern** (translate/index.ts, lines 1-57):
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { validateAuth, checkRateLimit, corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const user = await validateAuth(req, supabaseUrl, supabaseKey);

    const ip = req.headers.get('x-forwarded-for') || 'unknown';
    if (!checkRateLimit(`translate:${user.id}`, 100)) {
      return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
        status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ... business logic ...

    return new Response(JSON.stringify(data), {
      status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
```

**External API call pattern** (from send-push-notification/index.ts, lines 41-48):
```typescript
const response = await fetch('https://api.revenuecat.com/v1/subscribers/${userId}', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${Deno.env.get('REVENUECAT_API_KEY')}`,
  },
});
const data = await response.json();
```

---

### `supabase/functions/_shared/subscription.ts` (utility, request-response)

**Analog:** `supabase/functions/_shared/middleware.ts`

This is the exact analog: both are shared Deno modules exporting utility functions used by multiple Edge Functions. The new subscription.ts should export a tier-check helper and type definitions, just as middleware.ts exports validateAuth, checkRateLimit, and corsHeaders.

**Shared module pattern** (middleware.ts, full file):
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export interface AuthenticatedUser {
  id: string;
  email: string;
  platform?: string;
}

export async function validateAuth(request: Request, supabaseUrl: string, supabaseKey: string): Promise<AuthenticatedUser> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid authorization header');
  }
  const token = authHeader.replace('Bearer ', '');
  const supabase = createClient(supabaseUrl, supabaseKey);
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) throw new Error('Invalid token');
  return { id: user.id, email: user.email || '', platform: user.user_metadata?.platform };
}

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};
```

**Key convention:** Export typed interfaces + async utility functions that take Supabase client params. No default exports. No `serve()` call in shared modules.

---

### `supabase/functions/translate/index.ts` (controller, request-response) -- MODIFY

**Analog:** The file itself. Surgical addition of subscription tier check.

**Current insert flow** (lines 37-45):
```typescript
const { data, error } = await supabase.from('translations').insert({
  user_id: user.id,
  human_text,
  animal_text,
  source_language: source_language || 'human',
  target_language: target_language || 'dog',
  confidence: confidence || 0.0,
  quality_score: quality_score || null,
}).select().single();
```

**Modification point:** Insert a subscription tier check between the rate limit check (line 16) and the method check (line 22). The check should:
1. Query `subscription_status` for the user's tier
2. If tier is `'free'`, count today's translations for this user
3. If count >= 3, return 403 with error message
4. Otherwise, proceed with insert (RLS is the hard gate for client-side; this check covers service role bypass per D-04)

**Error response pattern to follow** (from existing lines 17-19):
```typescript
return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
  status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
});
```

For the tier check, return similar pattern with 403:
```typescript
return new Response(JSON.stringify({ error: 'Daily translation limit reached' }), {
  status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
});
```

---

## Shared Patterns

### Authentication
**Source:** `supabase/functions/_shared/middleware.ts` lines 10-19
**Apply to:** `entitlement-check/index.ts` (uses validateAuth), `translate/index.ts` (already uses it)
**NOT applied to:** `entitlement-webhook/index.ts` (uses REVENUECAT_WEBHOOK_AUTH Bearer token comparison instead, per D-02)

```typescript
export async function validateAuth(request: Request, supabaseUrl: string, supabaseKey: string): Promise<AuthenticatedUser> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid authorization header');
  }
  const token = authHeader.replace('Bearer ', '');
  const supabase = createClient(supabaseUrl, supabaseKey);
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) throw new Error('Invalid token');
  return { id: user.id, email: user.email || '', platform: user.user_metadata?.platform };
}
```

### Error Handling
**Source:** All existing Edge Functions use the same pattern
**Apply to:** All Edge Function files

```typescript
try {
  // business logic
} catch (error: any) {
  return new Response(JSON.stringify({ error: error.message }), {
    status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
```

**Exception for webhook:** The webhook handler MUST return 200 even on error (RevenueCat retries non-200 for 72 hours per RESEARCH.md Pitfall 2). Use `console.error` for logging but always return 200.

### CORS
**Source:** `supabase/functions/_shared/middleware.ts` lines 46-50
**Apply to:** All Edge Functions

```typescript
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};
```

### Service Role Client
**Source:** `supabase/functions/translate/index.ts` lines 9-11
**Apply to:** `entitlement-webhook/index.ts`, `entitlement-check/index.ts`, `translate/index.ts`

```typescript
const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseKey);
```

### updated_at Trigger
**Source:** `supabase/migrations/0001_organizations.sql` lines 177-183
**Apply to:** `0013_subscription_status.sql` (for subscription_status and user_profiles tables)

```sql
-- Function already exists from migration 0001, just create triggers:
CREATE TRIGGER update_subscription_status_updated_at
    BEFORE UPDATE ON public.subscription_status
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
```

### RLS Policy Naming Convention
**Source:** `supabase/migrations/0005_migrate_rls_policies.sql` throughout
**Apply to:** `0013_subscription_status.sql`

Pattern: `"{Subject} can {action} {target}"` -- e.g., `"Users can read own subscription status"`, `"Users can insert own translations with tier limit"`

### OPTIONS Preflight
**Source:** All Edge Functions
**Apply to:** All Edge Functions

```typescript
if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `supabase/functions/entitlement-webhook/index.ts` | controller | event-driven | No existing Edge Function receives inbound webhooks from an external service. The closest match (send-push-notification) calls an external API but does not receive inbound events. The webhook auth pattern (Bearer token vs shared secret) is new in the codebase. Use RESEARCH.md Code Examples section for the full webhook handler pattern. |

## Metadata

**Analog search scope:** `supabase/migrations/`, `supabase/functions/`, `supabase/functions/_shared/`
**Files scanned:** 12 migrations, 7 Edge Functions, 5 shared modules
**Pattern extraction date:** 2026-04-15
