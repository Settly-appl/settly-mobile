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

// Initializing messaging in the SW is what lets the FCM SDK auto-display
// incoming `notification` payloads. We deliberately do NOT add an
// onBackgroundMessage handler that calls showNotification — the SDK already
// shows the notification, and doing it again produces a DUPLICATE toast.
// (The notification's look/icon is controlled by the backend's WebpushConfig.)
firebase.messaging();

// No custom notificationclick handler: the backend sets webpush.fcmOptions.link
// to a deep-link URL (…/?notif_type=…&notif_id=…), and the FCM SDK's built-in
// click handler opens/focuses it. The app reads those query params on launch
// (NotificationService.consumeWebLaunch) and navigates accordingly.
