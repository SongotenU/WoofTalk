import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

interface ErrorPayload {
  platform: 'ios' | 'android' | 'web' | 'edge_function';
  error_type: string;
  message: string;
  stack_trace?: string;
  endpoint?: string;
  status_code?: number;
  metadata?: Record<string, any>;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify authentication - require user JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    const token = authHeader.substring(7);
    
    // Verify the JWT and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const payload: ErrorPayload = await req.json();

    if (!payload.platform || !payload.error_type || !payload.message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: platform, error_type, message' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { data, error } = await supabase
      .from('error_logs')
      .insert({
        platform: payload.platform,
        error_type: payload.error_type,
        message: payload.message,
        stack_trace: payload.stack_trace,
        user_id: user.id,  // Use authenticated user's ID
        endpoint: payload.endpoint,
        status_code: payload.status_code,
        metadata: payload.metadata || {},
      })
      .select('id')
      .single();

    if (error) throw error;

    // TODO: Configurable alert thresholds (email/Slack webhook) - check thresholds and notify
    // Could check recent error rates and trigger alerts via webhook

    return new Response(JSON.stringify({ success: true, id: data.id }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
