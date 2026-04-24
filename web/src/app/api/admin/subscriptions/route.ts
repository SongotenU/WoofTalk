import { NextRequest, NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase/server-admin';

export const runtime = 'nodejs';

export async function GET(req: NextRequest) {
  try {
    const adminClient = getAdminClient();

    const appId = process.env.REVENUECAT_APP_ID;
    const apiKey = process.env.REVENUECAT_API_KEY;

    if (!appId || !apiKey) {
      return NextResponse.json(
        { error: 'RevenueCat not configured', subscribers: [] },
        { status: 200 }
      );
    }

    // Fetch subscribers from RevenueCat
    const rcRes = await fetch(
      `https://api.revenuecat.com/v1/projects/${appId}/subscribers?limit=200`,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        next: { revalidate: 60 },
      }
    );

    if (!rcRes.ok) {
      const text = await rcRes.text();
      console.error('[admin/subscriptions] RevenueCat error:', text);
      return NextResponse.json(
        { error: 'Failed to fetch from RevenueCat', subscribers: [] },
        { status: 200 }
      );
    }

    const data = await rcRes.json();
    const subscribers = (data.subscribers ?? []).map((s: any) => ({
      uid: s.app_user_id ?? s.subscriber_id ?? '',
      email: s.email ?? s.original_app_user_id ?? '',
      subscription_status: s.subscription?.status ?? 'unknown',
      entitlement: s.entitlements?.premium?.expires_date
        ? `premium (expires ${s.entitlements.premium.expires_date})`
        : s.entitlements?.premium
        ? 'premium'
        : 'none',
      trial_end: s.subscription?.trial_end_date ?? null,
      cancel_at_period_end: s.subscription?.cancel_at_period_end ?? false,
    }));

    return NextResponse.json({ subscribers });
  } catch (err) {
    console.error('[admin/subscriptions]', err);
    return NextResponse.json(
      { error: 'Internal error', subscribers: [] },
      { status: 500 }
    );
  }
}