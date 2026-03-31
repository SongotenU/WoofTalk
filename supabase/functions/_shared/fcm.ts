import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendPushNotification(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  payload: PushPayload
): Promise<boolean> {
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');
  if (!fcmServerKey) return false;

  const { data: tokens } = await supabase
    .from('push_notifications')
    .select('fcm_token')
    .eq('user_id', userId)
    .eq('status', 'pending')
    .limit(1);

  if (!tokens || tokens.length === 0) return false;

  const fcmPayload = {
    to: tokens[0].fcm_token,
    notification: { title: payload.title, body: payload.body },
    data: payload.data || {},
  };

  const response = await fetch(FCM_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${fcmServerKey}`,
    },
    body: JSON.stringify(fcmPayload),
  });

  return response.ok;
}

export function buildPhraseApprovedNotification(phraseText: string): PushPayload {
  return {
    title: 'Phrase Approved!',
    body: `"${phraseText}" has been approved and is now live.`,
    data: { type: 'phrase_approved' },
  };
}

export function buildNewFollowerNotification(followerName: string): PushPayload {
  return {
    title: 'New Follower',
    body: `${followerName} started following you!`,
    data: { type: 'new_follower' },
  };
}

export function buildLeaderboardNotification(rank: number, period: string): PushPayload {
  return {
    title: 'Leaderboard Update',
    body: `You're #${rank} on the ${period} leaderboard!`,
    data: { type: 'leaderboard', rank: String(rank) },
  };
}
