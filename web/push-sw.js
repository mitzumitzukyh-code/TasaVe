// Service Worker para Web Push — TasaVe
// Se registra desde index.html para recibir notificaciones push

self.addEventListener('push', (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch {
    payload = { title: 'TasaVe', body: event.data.text() };
  }

  const options = {
    body: payload.body || '',
    icon: payload.icon || '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    vibrate: [100, 50, 100],
    tag: 'tasave-rate',
    renotify: true,
  };

  event.waitUntil(
    self.registration.showNotification(payload.title || 'TasaVe', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if (client.url.includes('tasave') && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});
