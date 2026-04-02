import { Context } from 'hono';

export interface ApiErrorResponse {
  error: string;
  code?: string;
  status: number;
  retry_after?: number;
  details?: unknown;
}

export interface ApiSuccessResponse<T> {
  data: T;
  meta?: Record<string, unknown>;
}

export function apiError(
  c: Context,
  message: string,
  status: number,
  code?: string,
  details?: unknown,
) {
  const body: ApiErrorResponse = {
    error: message,
    status,
  };
  if (code) body.code = code;
  if (details) body.details = details;
  return c.json(body, status);
}

export function apiSuccess<T>(c: Context, data: T, meta?: Record<string, unknown>) {
  return c.json<ApiSuccessResponse<T>>({ data, meta: meta ?? {} });
}

// Fire-and-forget usage tracking
export async function trackUsage(
  supabase: any,
  keyId: string,
  endpoint: string,
  statusCode: number,
) {
  try {
    await supabase.from('api_key_usage').insert({
      api_key_id: keyId,
      endpoint,
      status_code: statusCode,
    });
  } catch (err) {
    // Silently fail — usage tracking should not break requests
    console.error('Failed to track API usage:', err);
  }
}
