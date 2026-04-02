import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { bearerAuth } from 'hono/bearer-auth';
import { zValidator } from '@hono/zod-validator';
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';
import { validateApiKey, checkScope, ValidatedApiKey } from '../_shared/api-key.ts';
import { checkRateLimit } from '../_shared/rate-limit.ts';
import { apiError, apiSuccess, trackUsage } from '../_shared/response.ts';

// ============================================================
// Hono App
// ============================================================
const app = new Hono();

// ============================================================
// Global CORS
// ============================================================
app.use('*', cors({
  origin: ['https://wooftalk.com', 'https://www.wooftalk.com'],
  credentials: true,
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['authorization', 'content-type', 'x-api-version'],
  exposeHeaders: ['retry-after', 'x-ratelimit-remaining', 'x-ratelimit-limit', 'api-version'],
}));

// ============================================================
// Initialize clients
// ============================================================
const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

function getSupabase() {
  return createClient(supabaseUrl, serviceRoleKey);
}

// ============================================================
// Version header middleware
// ============================================================
app.use('/v1/*', async (c, next) => {
  c.header('API-Version', 'v1');
  await next();
});

// ============================================================
// API Key Auth Middleware
// ============================================================
app.use('/v1/*', async (c, next) => {
  const authHeader = c.req.header('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return apiError(c, 'Missing or invalid API key', 401, 'UNAUTHORIZED');
  }

  const rawKey = authHeader.replace('Bearer ', '');

  // Format check
  if (!rawKey.startsWith('wt_live_')) {
    return apiError(c, 'Invalid API key format', 401, 'INVALID_KEY_FORMAT');
  }

  const supabase = getSupabase();
  const validated = await validateApiKey(rawKey, supabase);

  if (!validated) {
    return apiError(c, 'Invalid or revoked API key', 401, 'INVALID_KEY');
  }

  // Store validated key in context
  c.set('apiKey', validated);
  await next();
});

// ============================================================
// Scope Check Middleware
// ============================================================
app.use('/v1/*', async (c, next) => {
  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const method = c.req.method;
  const path = c.req.path;

  const scopeResult = checkScope(apiKey.scope, method, path);
  if (!scopeResult.allowed) {
    return apiError(c, scopeResult.reason || 'Insufficient scope', 403, 'INSUFFICIENT_SCOPE');
  }

  await next();
});

// ============================================================
// IP Allowlist Middleware (API-09)
// ============================================================
app.use('/v1/*', async (c, next) => {
  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const forwarded = c.req.header('x-forwarded-for');
  const ip = forwarded ? forwarded.split(',')[0].trim() : c.req.header('x-real-ip') || '';

  // If key has ip_allowlist, check IP
  if (apiKey.ipAllowlist && apiKey.ipAllowlist.length > 0) {
    if (!ip || !apiKey.ipAllowlist.includes(ip)) {
      return apiError(c, 'IP address not allowed', 403, 'IP_NOT_ALLOWED');
    }
  }
  await next();
});

// ============================================================
// Rate Limit Middleware
// ============================================================
app.use('/v1/*', async (c, next) => {
  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const result = await checkRateLimit(apiKey.id, apiKey.rateLimit);

  c.header('X-RateLimit-Limit', String(result.limit));
  c.header('X-RateLimit-Remaining', String(result.remaining));

  if (!result.success) {
    const retryAfter = Math.ceil((result.reset - Date.now()) / 1000);
    c.header('Retry-After', String(retryAfter));
    return apiError(c, 'Rate limit exceeded', 429, 'RATE_LIMITED', {
      retry_after: retryAfter,
    });
  }

  await next();
});

// ============================================================
// Schemas
// ============================================================
const translateRequestSchema = z.object({
  source_language: z.enum(['human', 'dog']).default('human'),
  target_language: z.enum(['human', 'dog']).default('dog'),
  text: z.string().min(1).max(2000),
});

const translateResponseSchema = z.object({
  id: z.string().uuid(),
  human_text: z.string(),
  animal_text: z.string(),
  source_language: z.string(),
  target_language: z.string(),
  confidence: z.number().optional(),
  quality_score: z.number().nullable().optional(),
  created_at: z.string(),
});

const languageResponseSchema = z.object({
  code: z.string(),
  name: z.string(),
  direction: z.enum(['human_to_dog', 'dog_to_human']),
});

const usageResponseSchema = z.object({
  total_requests: z.number(),
  successful: z.number(),
  errors: z.number(),
  last_request_at: z.string().nullable(),
  usage_by_endpoint: z.array(z.object({
    endpoint: z.string(),
    count: z.number(),
    avg_status: z.number().nullable(),
  })),
});

// ============================================================
// POST /v1/translate
// ============================================================
app.post('/v1/translate', zValidator('json', translateRequestSchema), async (c) => {
  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const { source_language, target_language, text } = c.req.valid('json');
  const supabase = getSupabase();

  // Determine translation direction
  const direction =
    source_language === 'human' && target_language === 'dog'
      ? { human_text: text, animal_text: null }
      : source_language === 'dog' && target_language === 'human'
        ? { human_text: null, animal_text: text }
        : { human_text: text, animal_text: null };

  // Insert translation record
  const { data, error } = await supabase.from('translations').insert({
    user_id: apiKey.userId,
    org_id: apiKey.orgId,
    human_text: direction.human_text || text,
    animal_text: direction.animal_text || text,
    source_language,
    target_language,
    confidence: 0.8,
  }).select().single();

  if (error) {
    await trackUsage(supabase, apiKey.id, '/v1/translate', 500);
    return apiError(c, 'Translation failed', 500, 'TRANSLATION_ERROR', error.message);
  }

  // Fire-and-forget usage tracking
  trackUsage(supabase, apiKey.id, '/v1/translate', 201);

  return apiSuccess(c, {
    id: data.id,
    human_text: data.human_text,
    animal_text: data.animal_text,
    source_language: data.source_language,
    target_language: data.target_language,
    confidence: data.confidence,
    quality_score: data.quality_score,
    created_at: data.created_at,
  });
});

// ============================================================
// GET /v1/languages
// ============================================================
app.get('/v1/languages', async (c) => {
  const languages: z.infer<typeof languageResponseSchema>[] = [
    { code: 'human_to_dog', name: 'Human to Dog', direction: 'human_to_dog' },
    { code: 'dog_to_human', name: 'Dog to Human', direction: 'dog_to_human' },
  ];

  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const supabase = getSupabase();
  trackUsage(supabase, apiKey.id, '/v1/languages', 200);

  return apiSuccess(c, languages);
});

// ============================================================
// GET /v1/usage
// ============================================================
app.get('/v1/usage', async (c) => {
  const apiKey = c.get('apiKey') as ValidatedApiKey;
  const supabase = getSupabase();

  // Total requests
  const { data: total, error: totalError } = await supabase
    .from('api_key_usage')
    .select('id', { count: 'exact', head: true })
    .eq('api_key_id', apiKey.id);

  if (totalError) {
    return apiError(c, 'Failed to fetch usage', 500, 'USAGE_ERROR');
  }

  // Successful vs errors
  const { data: successData } = await supabase
    .from('api_key_usage')
    .select('id', { count: 'exact', head: true })
    .eq('api_key_id', apiKey.id)
    .gte('status_code', 200)
    .lt('status_code', 400);

  const { data: errorData } = await supabase
    .from('api_key_usage')
    .select('id', { count: 'exact', head: true })
    .eq('api_key_id', apiKey.id)
    .gte('status_code', 400);

  // Last request
  const { data: lastRequest } = await supabase
    .from('api_key_usage')
    .select('created_at')
    .eq('api_key_id', apiKey.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  // Usage by endpoint
  const { data: endpointUsage } = await supabase
    .from('api_key_usage')
    .select('endpoint, status_code')
    .eq('api_key_id', apiKey.id);

  const usageByEndpoint = endpointUsage?.reduce<Record<string, { counts: number[] }>>((acc, row) => {
    if (!acc[row.endpoint]) acc[row.endpoint] = { counts: [] };
    acc[row.endpoint].counts.push(row.status_code);
    return acc;
  }, {});

  const formattedEndpointUsage = Object.entries(usageByEndpoint ?? {}).map(([endpoint, data]) => ({
    endpoint,
    count: data.counts.length,
    avg_status: data.counts.reduce((sum: number, v: number) => sum + v, 0) / data.counts.length,
  }));

  return apiSuccess(c, {
    total_requests: total?.length ?? 0,
    successful: successData?.length ?? 0,
    errors: errorData?.length ?? 0,
    last_request_at: lastRequest?.created_at ?? null,
    usage_by_endpoint: formattedEndpointUsage,
  });
});

// ============================================================
// GET /v1/openapi.json (API-08)
// ============================================================
app.get('/v1/openapi.json', async (c) => {
  return c.json({
    openapi: '3.1.0',
    info: {
      title: 'WoofTalk API',
      version: 'v1',
      description: 'REST API for WoofTalk dog-to-human translation service',
      contact: { name: 'WoofTalk', url: 'https://wooftalk.com' },
    },
    servers: [{ url: 'https://${Deno.env.get("SUPABASE_URL")?.replace("https://", "") || "xxx"}.supabase.co/functions/v1/api-gateway' }],
    paths: {
      '/v1/translate': {
        post: {
          summary: 'Translate between human and dog languages',
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { source_language: { type: 'string', enum: ['human','dog'] }, target_language: { type: 'string', enum: ['human','dog'] }, text: { type: 'string', minLength: 1, maxLength: 2000 } }, required: ['source_language','target_language','text'] } } } },
          responses: {
            '201': { description: 'Translation successful' },
            '400': { description: 'Validation error' },
            '401': { description: 'Invalid API key' },
            '403': { description: 'Insufficient scope or IP not allowed' },
            '429': { description: 'Rate limit exceeded' },
          },
          security: [{ bearerAuth: [] }],
        },
      },
      '/v1/languages': {
        get: { summary: 'List supported languages', responses: { '200': { description: 'Language list' } }, security: [{ bearerAuth: [] }] },
      },
      '/v1/usage': {
        get: { summary: 'Get API key usage statistics', responses: { '200': { description: 'Usage data' } }, security: [{ bearerAuth: [] }] },
      },
    },
    components: {
      securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', description: 'API key with wt_live_ prefix' } },
    },
  });
});

// ============================================================
// Error Handler
// ============================================================
app.onError((err, c) => {
  if (err.name === 'ZodError') {
    return apiError(c, 'Validation failed', 400, 'VALIDATION_ERROR', (err as any).issues);
  }
  console.error('Unhandled error:', err);
  return apiError(c, 'Internal server error', 500, 'INTERNAL_ERROR');
});

export default app;
