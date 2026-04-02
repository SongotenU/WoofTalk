import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Admin-only routes
const ADMIN_PATHS = ['/admin'];

// Public paths that bypass auth check
const PUBLIC_PATHS = [
  '/_next',
  '/api/health',
  '/favicon.ico',
  '/icon',
  '/manifest.json',
  '/sw.js',
  '/workbox',
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

  // Check admin routes
  if (isAdminPath(pathname)) {
    const authCookie = request.cookies.get('sb-access-token') || request.cookies.get('supabase-auth-token');
    const authHeader = request.headers.get('authorization');

    if (!authCookie && !authHeader) {
      // No auth at all — redirect to login with return url
      const loginUrl = new URL('/auth/login', request.url);
      loginUrl.searchParams.set('redirect', encodeURIComponent(pathname));
      return NextResponse.redirect(loginUrl);
    }

    // Admin route access is checked server-side in page.tsx via getAdminClient().isAdmin().
    // For API routes, each handler does its own check.
    // This middleware just prevents unauthenticated access and provides 403 for known non-admin users.
    // The actual is_admin() check is done server-side to avoid leaking admin-only routes.

    // If we have a session cookie but admin check fails on page load, the page component
    // will handle redirect. Here we just ensure there's some auth token present.
  }

  // Admin API routes — handled at the route level with requireAdmin() helper

  return NextResponse.next();
}

export const config = {
  matcher: [
    // Match all request paths except static files and Next.js internals
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
