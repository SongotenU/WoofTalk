import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/middleware.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // Verify authentication - require user JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    const token = authHeader.substring(7);
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify the JWT and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { experiment_name } = await req.json();
    if (!experiment_name) {
      return new Response(JSON.stringify({ error: 'experiment_name is required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get experiment
    const { data: experiment, error: expError } = await supabase
      .from('ab_experiments')
      .select('*')
      .eq('name', experiment_name)
      .eq('is_active', true)
      .single();

    if (expError || !experiment) {
      return new Response(JSON.stringify({ variant: null, reason: 'experiment_not_found_or_inactive' }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Weighted random assignment based on user ID (deterministic per user per experiment)
    const variants = experiment.variants as Array<{ name: string; weight: number }>;
    const totalWeight = variants.reduce((sum, v) => sum + v.weight, 0);
    let random = (hashCode(user.id + experiment.id) % totalWeight);
    if (random < 0) random += totalWeight;

    let assignedVariant = variants[0].name;
    for (const v of variants) {
      if (random < v.weight) {
        assignedVariant = v.name;
        break;
      }
      random -= v.weight;
    }

    // Use upsert to handle race condition - the unique constraint on (experiment_id, user_id) prevents duplicates
    const { data: assignment, error: upsertError } = await supabase
      .from('experiment_assignments')
      .upsert({
        experiment_id: experiment.id,
        user_id: user.id,
        variant: assignedVariant,
      }, {
        onConflict: 'experiment_id,user_id',
        ignoreDuplicates: false,
      })
      .select('variant')
      .single();

    if (upsertError) {
      // If upsert fails due to duplicate, fetch existing assignment
      const { data: existing } = await supabase
        .from('experiment_assignments')
        .select('variant')
        .eq('experiment_id', experiment.id)
        .eq('user_id', user.id)
        .maybeSingle();
      
      if (existing) {
        return new Response(JSON.stringify({ variant: existing.variant, assigned: false }), {
          status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      throw upsertError;
    }

    return new Response(JSON.stringify({ variant: assignment.variant, assigned: true }), {
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
