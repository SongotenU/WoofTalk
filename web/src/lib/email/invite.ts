interface SendInviteEmail {
  to: string;
  orgName: string;
  inviterName: string;
  inviteToken: string;
  expiresAt: string;
}

export async function sendInviteEmail({
  to,
  orgName,
  inviterName,
  inviteToken,
  expiresAt,
}: SendInviteEmail): Promise<{ success: boolean; error?: string }> {
  const resendKey = process.env.RESEND_API_KEY;

  if (!resendKey) {
    console.warn('RESEND_API_KEY not set — email invite skipped');
    return { success: false, error: 'Email provider not configured' };
  }

  const inviteUrl = `${process.env.NEXT_PUBLIC_APP_URL || 'https://wooftalk.com'}/invite/accept?token=${inviteToken}`;

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'WoofTalk Invites <invites@wooftalk.com>',
        to,
        subject: `${inviterName} invited you to ${orgName} on WoofTalk`,
        html: `
          <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
            <h2>You're invited to ${orgName}</h2>
            <p><strong>${inviterName}</strong> has invited you to join <strong>${orgName}</strong> on WoofTalk.</p>
            <p style="margin: 24px 0;">
              <a href="${inviteUrl}" style="background: #16a34a; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">Accept Invitation</a>
            </p>
            <p style="font-size: 14px; color: #666;">
              Or visit: <a href="${inviteUrl}">${inviteUrl}</a>
            </p>
            <p style="font-size: 12px; color: #999; margin-top: 32px;">
              This invitation expires on ${new Date(expiresAt).toLocaleDateString()}.
              If you didn't expect this invite, you can safely ignore this email.
            </p>
          </div>
        `,
      }),
    });

    if (!res.ok) {
      const err = await res.json();
      return { success: false, error: err.message || res.statusText };
    }

    return { success: true };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
}
