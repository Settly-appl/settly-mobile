import 'package:firebase_core/firebase_core.dart';

/// Web push (FCM) configuration.
///
/// Fill these in from the Firebase console, then flip [kFirebaseWebConfigured]
/// to `true` and rebuild:
///  • [kFirebaseWebOptions] — Firebase console → Project settings → your **Web**
///    app → SDK setup and configuration (the `firebaseConfig` object).
///  • [kFirebaseWebVapidKey] — Firebase console → Project settings → Cloud
///    Messaging → **Web Push certificates** → key pair (the public "Key pair").
///
/// These values are NOT secret — the web SDK ships them to the browser anyway.
/// While [kFirebaseWebConfigured] is `false`, web push is completely inert and
/// the web app behaves exactly as before (no Firebase on web).
///
/// NOTE: keep [kFirebaseWebOptions] in sync with `web/firebase-messaging-sw.js`
/// (the background service worker can't read Dart, so its config is duplicated).
const bool kFirebaseWebConfigured = false;

const FirebaseOptions kFirebaseWebOptions = FirebaseOptions(
  apiKey: 'PASTE_WEB_API_KEY',
  appId: 'PASTE_WEB_APP_ID',
  messagingSenderId: 'PASTE_MESSAGING_SENDER_ID',
  projectId: 'PASTE_PROJECT_ID',
  authDomain: 'PASTE_PROJECT_ID.firebaseapp.com',
  storageBucket: 'PASTE_PROJECT_ID.appspot.com',
);

const String kFirebaseWebVapidKey = 'PASTE_VAPID_PUBLIC_KEY';
