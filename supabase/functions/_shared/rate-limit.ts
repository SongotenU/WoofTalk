import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

interface RateLimitResult {
  success: boolean;
  limit: number;
  remaining: number;
  reset: number;
}

let ratelimitInstance: Ratelimit | null = null;
let ratelimitConfig: { limit: number; window: string } = {
  limit: 60,
  window: '60s',
};

function getRedis(): Redis | null {
  const url = Deno.env.get('UPSTASH_REDIS_REST_URL');
  const token = Deno.env.get('UPSTASH_REDIS_TOKEN');
  if (!url || !token) return null;

  return new Redis({ url, token });
}

export function initRateLimiter(limit: number = 60, window: string = '60s'): void {
  const redis = getRedis();
  if (!redis) {
    console.warn('Upstash Redis not configured — rate limiting disabled');
    return;
  }

  ratelimitInstance = new Ratelimit({
    redis,
    limiter: Ratelimit.fixedWindow(limit, window),
    prefix: 'wooftalk:ratelimit',
  });
  ratelimitConfig = { limit, window };
}

export async function checkRateLimit(
  keyId: string,
  customLimit?: number,
): Promise<RateLimitResult> {
  // If Redis not configured, allow all requests (dev fallback)
  if (!ratelimitInstance) {
    initRateLimiter(customLimit);
    if (!ratelimitInstance) {
      return { success: true, limit: customLimit ?? 60, remaining: 999, reset: Date.now() + 60000 };
    }
  }

  const limit = customLimit ?? ratelimitConfig.limit;

  // Use per-key instance if custom limit differs from default
  const limiter =
    limit !== ratelimitConfig.limit && ratelimitInstance
      ? (() => {
          const redis = getRedis();
          if (!redis) return ratelimitInstance;
          return new Ratelimit({
            redis,
            limiter: Ratelimit.fixedWindow(limit, '60s'),
            prefix: `wooftalk:ratelimit:${keyId}`,
          });
        })()
      : ratelimitInstance;

  const result = await limiter.limit(keyId);
  return {
    success: result.success,
    limit: result.limit,
    remaining: result.remaining,
    reset: result.reset,
  };
}
