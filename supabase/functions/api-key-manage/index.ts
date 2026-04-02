import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcrypt';
import { validateAuth, corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const user = await validateAuth(req, supabaseUrl, supabaseKey);
    const url = new URL(req.url);
    const path = url.pathname;
    const method = req.method;

    // ============================================================
    // POST /keys — Generate new API key
    // ============================================================
    if (method === 'POST' && path.endsWith('/keys')) {
      const body = await req.json();
      const { name, scope, org_id } = body;

      if (!name) {
        return new Response(JSON.stringify({ error: 'Key name is required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const validScopes = ['translate:read', 'translate:write', 'translate:full'];
      const keyScope = scope || 'translate:full';
      if (!validScopes.includes(keyScope)) {
        return new Response(JSON.stringify({ error: `Invalid scope. Must be one of: ${validScopes.join(', ')}` }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Generate raw key
      const rawKey = 'wt_live_' + crypto.randomUUID().replace(/-/g, '');
      const keyPrefix = rawKey.slice(0, 16);

      // Hash with bcrypt (10 rounds)
      const keyHash = await bcrypt.hash(rawKey, 10);

      // Store in database
      const { data, error } = await supabase
        .from('api_keys')
        .insert({
          user_id: user.id,
          org_id: org_id || null,
          name,
          key_prefix: keyPrefix,
          key_hash: keyHash,
          scope: keyScope,
          rate_limit: body.rate_limit || 60,
        })
        .select('id, name, scope, rate_limit, created_at')
        .single();

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({
        ...data,
        key: rawKey, // Only time plaintext key is returned
      }), {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ============================================================
    // GET /keys — List user's API keys
    // ============================================================
    if (method === 'GET' && path.endsWith('/keys')) {
      const { data, error } = await supabase
        .from('api_keys')
        .select('id, name, scope, rate_limit, is_revoked, created_at, revoked_at')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ keys: data || [] }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ============================================================
    // DELETE /keys/:id — Revoke API key
    // ============================================================
    if (method === 'DELETE' && path.match(/\/keys\/.+/)) {
      const keyId = path.split('/').pop();

      // Verify ownership
      const { data: existingKey, error: fetchError } = await supabase
        .from('api_keys')
        .select('id, is_revoked')
        .eq('id', keyId)
        .eq('user_id', user.id)
        .single();

      if (fetchError || !existingKey) {
        return new Response(JSON.stringify({ error: 'Key not found or not owned by user' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const { error } = await supabase
        .from('api_keys')
        .update({ is_revoked: true, revoked_at: new Date().toISOString() })
        .eq('id', keyId);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ message: 'Key revoked' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ============================================================
    // PATCH /keys/:id — Update key name or scope
    // ============================================================
    if (method === 'PATCH' && path.match(/\/keys\/.+/)) {
      const keyId = path.split('/').pop();
      const body = await req.json();
      const updates: Record<string, unknown> = {};

      if (body.name) updates.name = body.name;
      if (body.scope) {
        const validScopes = ['translate:read', 'translate:write', 'translate:full'];
        if (!validScopes.includes(body.scope)) {
          return new Response(JSON.stringify({ error: 'Invalid scope' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }
        updates.scope = body.scope;
      }
      if (typeof body.rate_limit === 'number' && body.rate_limit > 0) {
        updates.rate_limit = body.rate_limit;
      }

      if (Object.keys(updates).length === 0) {
        return new Response(JSON.stringify({ error: 'No valid fields to update' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const { error } = await supabase
        .from('api_keys')
        .update(updates)
        .eq('id', keyId)
        .eq('user_id', user.id);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ message: 'Key updated' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: error.message === 'Missing or invalid authorization header' ? 401 : 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
