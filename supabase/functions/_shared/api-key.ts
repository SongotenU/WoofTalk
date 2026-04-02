import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcrypt';

export interface ApiKeyRecord {
  id: string;
  user_id: string;
  org_id: string | null;
  name: string;
  scope: 'translate:read' | 'translate:write' | 'translate:full';
  rate_limit: number;
  key_hash: string;
  is_revoked: boolean;
}

export interface ValidatedApiKey {
  id: string;
  userId: string;
  orgId: string | null;
  scope: string;
  rateLimit: number;
}

export async function validateApiKey(
  rawKey: string,
  supabase: ReturnType<typeof createClient>,
): Promise<ValidatedApiKey | null> {
  // Format check
  if (!rawKey || !rawKey.startsWith('wt_live_')) {
    return null;
  }

  // Extract prefix (first 16 chars)
  const keyPrefix = rawKey.slice(0, 16);

  // Look up by prefix
  const { data: keyRecord, error } = await supabase
    .from('api_keys')
    .select('id, user_id, org_id, name, scope, rate_limit, key_hash, is_revoked')
    .eq('key_prefix', keyPrefix)
    .eq('is_revoked', false)
    .single();

  if (error || !keyRecord) return null;

  // Bcrypt compare (one comparison only, O(1) lookup)
  const isValid = await bcrypt.compare(rawKey, keyRecord.key_hash);
  if (!isValid) return null;

  return {
    id: keyRecord.id,
    userId: keyRecord.user_id,
    orgId: keyRecord.org_id,
    scope: keyRecord.scope,
    rateLimit: keyRecord.rate_limit,
  };
}

export interface ScopeCheck {
  allowed: boolean;
  reason?: string;
}

const SCOPE_PERMISSIONS: Record<string, { methods: string[]; patterns: string[] }> = {
  'translate:read': {
    methods: ['GET'],
    patterns: ['/v1/languages', '/v1/usage'],
  },
  'translate:write': {
    methods: ['POST'],
    patterns: ['/v1/translate'],
  },
  'translate:full': {
    methods: ['GET', 'POST'],
    patterns: ['/v1/translate', '/v1/languages', '/v1/usage'],
  },
};

export function checkScope(
  scope: string,
  method: string,
  path: string,
): ScopeCheck {
  const perms = SCOPE_PERMISSIONS[scope];
  if (!perms) {
    return { allowed: false, reason: 'Unknown scope' };
  }

  const matched = perms.patterns.some((pattern) => path.startsWith(pattern));
  if (!matched) {
    return { allowed: false, reason: 'No matching endpoint for scope' };
  }

  if (!perms.methods.includes(method)) {
    return {
      allowed: false,
      reason: `Method ${method} not allowed for scope ${scope}`,
    };
  }

  return { allowed: true };
}
