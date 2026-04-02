import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';
import { sendInviteEmail } from '@/lib/email/invite';

export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );

  try {
    const { email, role } = await req.json();

    if (!email) {
      return NextResponse.json({ error: 'Email required' }, { status: 400 });
    }

    // Get user's org
    const { data: userOrg, error: orgError } = await supabase
      .from('organization_members')
      .select('org_id, organizations(name)')
      .eq('status', 'active')
      .limit(1)
      .single();

    if (orgError || !userOrg) {
      return NextResponse.json({ error: 'No organization found' }, { status: 404 });
    }

    const inviteToken = crypto.randomUUID().replace(/-/g, '');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7-day expiry

    const { data, error } = await supabase
      .from('organization_members')
      .insert({
        org_id: userOrg.org_id,
        user_id: '00000000-0000-0000-0000-000000000000',
        role: role || 'member',
        status: 'invited',
        invite_token: inviteToken,
        invite_expires_at: expiresAt.toISOString(),
      })
      .select()
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Send email invite
    const emailResult = await sendInviteEmail({
      to: email,
      orgName: userOrg.organizations?.name || 'the organization',
      inviterName: 'WoofTalk Admin',
      inviteToken,
      expiresAt: expiresAt.toISOString(),
    });

    return NextResponse.json({ invite: data, email_sent: emailResult.success });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
