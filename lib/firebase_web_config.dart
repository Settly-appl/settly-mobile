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
///
/// Flip this to `true` once [kFirebaseWebVapidKey] is filled in below.
const bool kFirebaseWebConfigured = true;

const FirebaseOptions kFirebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyDCVXFmvJsYNfD-uSLBj6LmdyABAGBVe5E',
  appId: '1:240217906279:web:b35efc59b05e5683b648c2',
  messagingSenderId: '240217906279',
  projectId: 'settly-491611',
  authDomain: 'settly-491611.firebaseapp.com',
  storageBucket: 'settly-491611.firebasestorage.app',
  measurementId: 'G-QZG4PZSQSR',
);

// Firebase console → Project settings → Cloud Messaging → Web Push certificates
// → "Key pair" (a long string starting with "B...").
const String kFirebaseWebVapidKey =
    'BBKvqQowd32HTYWJU0f68rw_NKdXmnx0ozl9G2N7bz8_lBeGh0ZmsFnAC7VpPBSvNk8ouWB6vpXSRDIQQ5SFKgw';
