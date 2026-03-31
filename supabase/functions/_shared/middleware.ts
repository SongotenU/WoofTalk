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

const rateLimits = new Map<string, { tokens: number; lastRefill: number }>();

export function checkRateLimit(key: string, maxTokens: number = 60, refillRate: number = 1): boolean {
  const now = Date.now();
  const bucket = rateLimits.get(key) || { tokens: maxTokens, lastRefill: now };
  const elapsed = (now - bucket.lastRefill) / 1000;
  bucket.tokens = Math.min(maxTokens, bucket.tokens + elapsed * refillRate);
  bucket.lastRefill = now;
  if (bucket.tokens < 1) return false;
  bucket.tokens -= 1;
  rateLimits.set(key, bucket);
  return true;
}

export function validatePhraseText(text: string): string {
  if (!text || text.trim().length === 0) throw new Error('Phrase text is required');
  if (text.length > 500) throw new Error('Phrase text must be 500 characters or less');
  return text.trim();
}

export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};
