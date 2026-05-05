// Web Push Notification utility for WoofTalk
// Handles subscription management via Supabase

const VAPID_PUBLIC_KEY = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY || "";

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  let rawData: string;
  if (typeof window !== 'undefined' && window.atob) {
    rawData = window.atob(base64);
  } else {
    // Server-side or window.atob not available — use Buffer or manual decode
    rawData = Buffer.from(base64, 'base64').toString('binary');
  }
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export async function subscribeToPush(): Promise<PushSubscription | null> {
  if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
    return null;
  }

  try {
    const registration = await navigator.serviceWorker.ready;
    let subscription = await registration.pushManager.getSubscription();

    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: JSON.stringify(urlBase64ToUint8Array(VAPID_PUBLIC_KEY)),
      });
    }

    // Send subscription to backend
    const { supabase } = await import("./supabase");
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await supabase.from("push_subscriptions").upsert({
        user_id: user.id,
        endpoint: subscription.endpoint,
        keys: JSON.stringify(subscription.toJSON().keys),
        created_at: new Date().toISOString(),
      });
    }

    return subscription;
  } catch (err) {
    console.error("Push subscription failed:", err);
    return null;
  }
}

export async function unsubscribeFromPush(): Promise<boolean> {
  if (!("serviceWorker" in navigator)) return false;

  try {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();
    if (subscription) {
      await subscription.unsubscribe();

      const { supabase } = await import("./supabase");
      await supabase
        .from("push_subscriptions")
        .delete()
        .eq("endpoint", subscription.endpoint);
    }
    return true;
  } catch (err) {
    console.error("Push unsubscribe failed:", err);
    return false;
  }
}

export function sendLocalNotification(title: string, body: string) {
  if ("Notification" in window && Notification.permission === "granted") {
    navigator.serviceWorker?.getRegistration().then(reg => {
      if (reg) {
        reg.showNotification(title, {
          body,
          icon: "/icon-192.png",
          badge: "/icon-192.png",
        });
      }
    });
  }
}
