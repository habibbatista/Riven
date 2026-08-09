// Riven service worker — exists ONLY to receive Web Push events and react
// to notification taps. It intentionally does no offline caching of app
// files, so there's zero risk of it ever serving a stale copy of
// riven.html; every navigation still goes straight to the network.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// The payload is whatever JSON the sending server (see functions/index.js)
// put in the push message: { title, body, icon, tag, url, type }.
self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = { title: 'Riven', body: event.data ? event.data.text() : 'You have a new notification' };
  }

  const title = payload.title || 'Riven';
  const options = {
    body: payload.body || '',
    icon: payload.icon || 'icons/icon-192.png',
    badge: 'icons/icon-192.png',
    // Same tag + renotify means a second "incoming call" push replaces the
    // first instead of stacking duplicate banners if it's re-sent.
    tag: payload.tag || 'riven-notification',
    renotify: true,
    data: {
      url: payload.url || '.',
      type: payload.type || 'generic'
    },
    vibrate: payload.type === 'call' ? [400, 200, 400, 200, 400] : [200]
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

// Tapping the notification focuses an already-open Riven tab if one
// exists, or opens a new one — landing on whatever URL the push specified
// (e.g. the DM tab). For calls specifically, the app's own in-app
// Firestore listener (already running once the page loads) is what
// actually shows the incoming-call screen — this just gets a closed app
// back open.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.url) || './index.html';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.focus();
          if ('navigate' in client) {
            try { client.navigate(targetUrl); } catch (e) {}
          }
          return;
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    })
  );
});
