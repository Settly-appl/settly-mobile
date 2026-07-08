// FCM background message handler for the web (PWA / desktop notifications).
//
// This service worker is only registered by firebase_messaging once web push
// is enabled (kFirebaseWebConfigured = true in lib/firebase_web_config.dart).
// Keep the config below in sync with kFirebaseWebOptions — a service worker
// can't read Dart, so the values are duplicated here.
//
// After filling these in, they are shipped to the browser anyway (not secret).

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyDCVXFmvJsYNfD-uSLBj6LmdyABAGBVe5E',
  appId: '1:240217906279:web:b35efc59b05e5683b648c2',
  messagingSenderId: '240217906279',
  projectId: 'settly-491611',
});

const messaging = firebase.messaging();

// Shown when a push arrives and the app tab is in the background / closed.
// (Messages with a `notification` payload may be auto-displayed by the browser;
// this handles data-only messages and keeps a consistent look.)
messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  const data = payload.data || {};
  self.registration.showNotification(n.title || 'Settly', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data,
  });
});

// Focus / open the app when the user clicks the notification.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    }),
  );
});
