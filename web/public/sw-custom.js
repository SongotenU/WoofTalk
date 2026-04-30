// Custom service worker additions for WoofTalk
// This file is injected by next-pwa

// Offline fallback
self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => caches.match("/offline.html"))
    );
  }
});

// Push notification event
self.addEventListener("push", (event) => {
  let data = {};
  try {
    data = event.data.json();
  } catch {
    data = { title: "WoofTalk", body: event.data?.text() || "New notification" };
  }

  const options = {
    body: data.body || "",
    icon: "/icon-192.png",
    badge: "/icon-192.png",
    data: data.url || "/translate",
  };

  event.waitUntil(self.registration.showNotification(data.title || "WoofTalk", options));
});

// Notification click
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = event.notification.data || "/translate";
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(url) && "focus" in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
