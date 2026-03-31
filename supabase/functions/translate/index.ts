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

    const body = await req.json();
    const { human_text, animal_text, source_language, target_language, confidence, quality_score } = body;

    if (!human_text || !animal_text) {
      return new Response(JSON.stringify({ error: 'human_text and animal_text are required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data, error } = await supabase.from('translations').insert({
      user_id: user.id,
      human_text,
      animal_text,
      source_language: source_language || 'human',
      target_language: target_language || 'dog',
      confidence: confidence || 0.0,
      quality_score: quality_score || null,
    }).select().single();

    if (error) throw error;

    return new Response(JSON.stringify(data), {
      status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
