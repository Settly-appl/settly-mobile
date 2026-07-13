import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:settly_mobile/app_navigator.dart';
import 'package:settly_mobile/firebase_web_config.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/balances_page.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
import 'package:settly_mobile/pages/main_pages/friends_page.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/notifications_store.dart';

/// Handles FCM: permission, token lifecycle, and (un)registration with the
/// Settly backend (`/api/notifications/device-tokens`).
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _api = ApiServiceRequest();

  bool _initialised = false;
  // Set when the app was launched from terminated state by a notification tap;
  // consumed once the UI is ready (see consumePendingNavigation).
  RemoteMessage? _pendingMessage;

  /// Call once after `Firebase.initializeApp` (e.g. in `main`). Requests
  /// permission and wires up the token-refresh and foreground listeners.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Only prompt when the user hasn't decided yet — otherwise the permission
    // dialog would pop on every launch (already granted/denied stays as-is).
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await _messaging.requestPermission();
    }

    // Re-register whenever FCM rotates the token.
    _messaging.onTokenRefresh.listen(_sendToken);

    // Foreground messages (Android doesn't show these in the tray on its own):
    // record only, the bell shows them.
    FirebaseMessaging.onMessage.listen(_handleMessage);
    // User tapped a notification that opened the app from the background: record + open.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
      navigateForData(message.data);
    });
    // App launched from terminated state by tapping a notification: record now,
    // navigate once the UI is ready (consumePendingNavigation).
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
      _pendingMessage = initial;
    }
  }

  void _handleMessage(RemoteMessage message) {
    NotificationsStore().add(AppNotification.fromRemoteMessage(message));
  }

  /// Handle a notification tap that happened before the UI existed (cold launch).
  /// Call once the home screen is shown (and the user is authenticated).
  void consumePendingNavigation() {
    final pending = _pendingMessage;
    _pendingMessage = null;
    if (pending != null) navigateForData(pending.data);
  }

  /// Opens the relevant screen for a notification (e.g. from a bell-list tap).
  Future<void> navigateForNotification(AppNotification notification) =>
      navigateForData(notification.data);

  Future<void> navigateForData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();

    // Powiadomienia o wydatku (dodano Cię do podziału / ktoś zmienił rozliczenie)
    // prowadzą do samego wydatku.
    if (type == 'EXPENSE_SPLIT' || type == 'EXPENSE_SETTLEMENT') {
      final id = data['expenseId']?.toString();
      if (id != null && id.isNotEmpty) await _openExpense(id);
    } else if (type == 'FRIEND_REQUEST' || type == 'FRIEND_REQUEST_ACCEPTED') {
      _pushFromNotification(const FriendsPage());
    } else if (type == 'SETTLEMENT_REMINDER') {
      // Codzienne przypomnienie nie dotyczy jednego wydatku — otwórz salda.
      _pushFromNotification(const BalancesPage());
    }
  }

  /// Otwiera stronę z powiadomienia tak, żeby przycisk „wstecz" telefonu wracał
  /// na stronę główną, a nie zamykał aplikację.
  ///
  /// Aplikacja jest instalowana jako PWA, więc „wstecz" to cofnięcie w historii
  /// przeglądarki. Po wejściu z powiadomienia okno ma zwykle jeden wpis historii,
  /// więc bez tego cofnięcie wyrzuca użytkownika z aplikacji.
  void _pushFromNotification(Widget page) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => _NotificationRoute(child: page)),
    );
  }

  /// Web only: when the app is opened by clicking a push notification, the
  /// service worker launches it with `?notif_type=...&notif_id=...`. Consume
  /// those once the UI is ready and deep-link accordingly.
  void consumeWebLaunch() {
    if (!kIsWeb) return;
    final params = Uri.base.queryParameters;
    final type = params['notif_type'];
    if (type == null || type.isEmpty) return;
    navigateForData({
      'type': type,
      if (params['notif_id'] != null) 'expenseId': params['notif_id'],
    });
  }

  Future<void> _openExpense(String expenseId) async {
    final response = await _api.request(
      endpoint: 'expenses/$expenseId',
      method: HttpMethod.get,
    );
    if (response == null || response.statusCode != 200) return;

    final expense = SingleExpense.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    _pushFromNotification(ExpenseDetailsPage(expense: expense));
  }

  /// FCM token for this device/browser. On web it needs the VAPID key and
  /// requires the web config to be filled in.
  Future<String?> _currentToken() async {
    if (kIsWeb && !kFirebaseWebConfigured) return null;
    try {
      final future = kIsWeb
          ? _messaging.getToken(vapidKey: kFirebaseWebVapidKey)
          : _messaging.getToken();
      // Never let a slow/blocked getToken (e.g. permission not yet granted on
      // web) hang the caller.
      return await future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  String get _platform {
    if (kIsWeb) return 'WEB';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
  }

  /// Registers the current device token with the backend. Call after a
  /// successful login (once an access token is available).
  Future<void> registerCurrentToken() async {
    final token = await _currentToken();
    if (token != null) await _sendToken(token);
  }

  /// Czy push faktycznie działa na tym urządzeniu: zgoda udzielona **i** token
  /// da się pobrać. Sama zgoda nie wystarcza — np. Brave domyślnie wyłącza
  /// usługę Google push messaging, więc zgoda jest, a tokenu nie ma.
  Future<bool> isEnabled() async {
    if (kIsWeb && !kFirebaseWebConfigured) return false;
    try {
      final settings = await _messaging.getNotificationSettings();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) return false;
      return await _currentToken() != null;
    } catch (_) {
      return false;
    }
  }

  /// Włącza powiadomienia na żądanie użytkownika (przycisk w profilu/dzwonku).
  ///
  /// `init()` pyta o zgodę tylko wtedy, gdy nie została jeszcze podjęta —
  /// dlatego ktoś, kto raz odmówił, nigdy więcej nie zobaczy pytania i bez tej
  /// ścieżki nie miałby jak tego odkręcić.
  Future<NotificationEnableResult> enableNotifications() async {
    if (kIsWeb && !kFirebaseWebConfigured) {
      return NotificationEnableResult.unsupported;
    }
    try {
      var settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await _messaging.requestPermission();
      }

      // Zgody zablokowanej nie da się cofnąć z poziomu strony — użytkownik musi
      // ją zmienić w ustawieniach przeglądarki.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return NotificationEnableResult.blocked;
      }

      final token = await _currentToken();
      if (token == null) {
        // Zgoda jest, a tokenu nie ma: typowo Brave z wyłączonym „Use Google
        // services for push messaging", albo iOS Safari bez zainstalowanej PWA.
        return NotificationEnableResult.noPushService;
      }

      await _sendToken(token);
      return NotificationEnableResult.enabled;
    } catch (e) {
      debugPrint('enableNotifications failed: $e');
      return NotificationEnableResult.failed;
    }
  }

  Future<void> _sendToken(String token) async {
    await _api.request(
      endpoint: 'notifications/device-tokens',
      method: HttpMethod.post,
      body: {'token': token, 'platform': _platform},
    );
  }

  /// Removes this device's token from the backend. Call before logging out,
  /// while the access token is still valid.
  Future<void> unregisterCurrentToken() async {
    final token = await _currentToken();
    if (token == null) return;
    await _api.request(
      endpoint: 'notifications/device-tokens/${Uri.encodeComponent(token)}',
      method: HttpMethod.delete,
    );
  }
}

/// Strona otwarta z powiadomienia.
///
/// Przycisk „wstecz" telefonu (w PWA to cofnięcie w historii przeglądarki)
/// sprowadza użytkownika na stronę główną zamiast wyrzucać go z aplikacji —
/// po wejściu z powiadomienia okno ma zwykle jeden wpis historii, więc bez tego
/// cofnięcie zamyka aplikację.
///
/// `PopScope` przechwytuje wyłącznie cofnięcie systemowe (`Navigator.maybePop`).
/// Strzałka „wstecz" w aplikacji woła `Navigator.pop` bezpośrednio, więc działa
/// jak dotąd — i nadal zwraca swój wynik (np. „coś się zmieniło, odśwież listę").
class _NotificationRoute extends StatelessWidget {
  final Widget child;

  const _NotificationRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Zejdź do strony głównej. Gdy nie ma dokąd wracać, popUntil nic nie
        // robi — i o to chodzi: zostajemy w aplikacji.
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      },
      child: child,
    );
  }
}

/// Wynik próby włączenia powiadomień.
///
/// [noPushService] to ważny przypadek: zgoda jest udzielona, ale przeglądarka i
/// tak nie potrafi zarejestrować tokenu. Najczęściej Brave, który domyślnie ma
/// wyłączone „Use Google services for push messaging" (trzeba je włączyć w
/// brave://settings/privacy i zrestartować przeglądarkę), albo iOS Safari bez
/// zainstalowanej PWA. Bez rozróżnienia tego od [blocked] podpowiedź „zmień
/// zgodę w ustawieniach strony" wysyłałaby użytkownika w ślepy zaułek.
enum NotificationEnableResult { enabled, blocked, noPushService, unsupported, failed }
