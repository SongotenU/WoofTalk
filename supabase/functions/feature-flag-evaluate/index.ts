import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { key, user_id } = await req.json();

    if (!key) {
      return new Response(JSON.stringify({ error: 'key is required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: flag, error } = await supabase
      .from('feature_flags')
      .select('*')
      .eq('key', key)
      .single();

    if (error || !flag) {
      return new Response(JSON.stringify({ enabled: false, reason: 'flag_not_found' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!flag.is_enabled) {
      return new Response(JSON.stringify({ enabled: false, reason: 'flag_disabled', value: flag.value }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Rollout percentage check
    if (flag.rollout_percentage < 100 && user_id) {
      const hash = hashCode(user_id);
      const bucket = (hash % 100) + 1;
      if (bucket > flag.rollout_percentage) {
        return new Response(JSON.stringify({ enabled: false, reason: 'rollout', value: flag.value }), {
          status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    return new Response(JSON.stringify({ enabled: true, value: flag.value }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash);
}
