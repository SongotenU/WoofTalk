import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export function getServerSupabase(request: NextRequest) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  // Check for auth tokens from request cookies
  const sessionCookie =
    request.cookies.get('supabase-auth-token')?.value ||
    request.cookies.get('sb-access-token')?.value;

  if (sessionCookie) {
    try {
      const parsed = JSON.parse(sessionCookie);
      const accessToken = parsed.access_token || sessionCookie;
      // Set session on Supabase client
      // Note: we use service_role key for admin operations in API routes
    } catch {
      // Token might be raw — try to use as-is
    }
  }

  return supabase;
}

export function getServiceRoleSupabase() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set for admin API routes',
    );
  }

  return createClient(supabaseUrl, serviceRoleKey);
}

export async function requireAdmin(request: NextRequest): Promise<NextResponse | null> {
  const supabase = getServiceRoleSupabase();

  // Extract user ID from session cookie
  const rawCookie =
    request.cookies.get('supabase-auth-token')?.value ||
    request.cookies.get('sb-access-token')?.value;

  if (!rawCookie) {
    return NextResponse.json(
      { error: 'Authentication required', code: 'UNAUTHORIZED' },
      { status: 401 },
    );
  }

  let accessToken: string;
  try {
    const parsed = JSON.parse(rawCookie);
    accessToken = parsed.access_token || rawCookie;
  } catch {
    accessToken = rawCookie;
  }

  if (!accessToken) {
    return NextResponse.json(
      { error: 'Authentication required', code: 'UNAUTHORIZED' },
      { status: 401 },
    );
  }

  // Verify the user has an active session
  const clientSupabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } }
  );

  const { data: { user }, error: authError } = await clientSupabase.auth.getUser(accessToken);

  if (authError || !user) {
    return NextResponse.json(
      { error: 'Authentication required', code: 'UNAUTHORIZED' },
      { status: 401 },
    );
  }

  // Check if user is admin via organization_members
  const { data: member } = await supabase
    .from('organization_members')
    .select('role')
    .eq('user_id', user.id)
    .eq('role', 'admin')
    .eq('status', 'active')
    .single();

  // Also check owner role
  const { data: owner } = await supabase
    .from('organization_members')
    .select('role')
    .eq('user_id', user.id)
    .eq('role', 'owner')
    .eq('status', 'active')
    .single();

  // Also check is_admin() SQL function
  const { data: isAdminResult } = await supabase.rpc('is_admin', undefined).throwOnError();

  if (!member && !owner && !isAdminResult) {
    return NextResponse.json(
      { error: 'Admin access required', code: 'FORBIDDEN' },
      { status: 403 },
    );
  }

  return null; // User is authorized, continue
}
