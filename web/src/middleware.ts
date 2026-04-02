import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Admin-only route prefixes
const ADMIN_PATHS = ['/admin'];

// Public/static paths that bypass auth check
const PUBLIC_PATHS = [
  '/_next',
  '/api/health',
  '/favicon.ico',
  '/icon',
  '/manifest.json',
  '/sw.js',
  '/workbox',
  '/401',
  '/403',
];

function isPublicPath(path: string): boolean {
  return PUBLIC_PATHS.some((p) => path.startsWith(p));
}

function isAdminPath(path: string): boolean {
  return ADMIN_PATHS.some((p) => path.startsWith(p));
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip middleware for public/static paths
  if (isPublicPath(pathname)) {
    return NextResponse.next();
  }

  // Enforce admin auth on admin routes
  if (isAdminPath(pathname)) {
    const authCookie =
      request.cookies.get('sb-access-token') ||
      request.cookies.get('supabase-auth-token');
    const authHeader = request.headers.get('authorization');

    if (!authCookie && !authHeader) {
      // No auth at all — redirect to login with return url
      const loginUrl = new URL('/auth/login', request.url);
      loginUrl.searchParams.set('redirect', encodeURIComponent(pathname));
      return NextResponse.redirect(loginUrl);
    }

    // Call Supabase edge-compatible is_admin check via service function
    const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (SUPABASE_URL && SUPABASE_SERVICE_KEY) {
      const supabaseUrl = SUPABASE_URL;
      const supabaseKey = SUPABASE_SERVICE_KEY;

      // Validate the session via Supabase Auth
      const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${(authCookie?.value || authHeader)?.replace(/^Bearer /, '')}`,
        },
      });

      if (!userRes.ok) {
        // Invalid or expired token — reject
        return NextResponse.json(
          { message: 'Unauthorized', redirect: '/auth/login' },
          { status: 401, headers: { location: '/auth/login' } },
        );
      }

      const userData = await userRes.json();
      const userId = userData?.id;

      if (!userId) {
        return NextResponse.json(
          { message: 'Unauthorized', redirect: '/auth/login' },
          { status: 401, headers: { location: '/auth/login' } },
        );
      }

      // Check if user is admin or owner in organization_members
      const adminRes = await fetch(
        `${supabaseUrl}/rest/v1/organization_members?select=user_id,role&user_id=eq.${userId}&status=eq.active`,
        {
          headers: {
            apikey: supabaseKey,
            Authorization: `Bearer ${supabaseKey}`,
          },
        },
      );

      if (adminRes.ok) {
        const members = await adminRes.json();
        const isAdmin = members.some(
          (m: { role: string }) => m.role === 'admin' || m.role === 'owner'
        );

        if (!isAdmin) {
          // Authenticated but not admin — redirect to 403
          return NextResponse.redirect(new URL('/403', request.url));
        }
      }
    }

    // If Supabase env vars not available (dev mode), allow through
    // but log a warning is not possible in middleware — trust the route-level checks
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    // Match all request paths except static files and Next.js internals
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};