import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:settly_mobile/app_navigator.dart';
import 'package:settly_mobile/firebase_web_config.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
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

    await _messaging.requestPermission();

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
    if (data['type'] == 'EXPENSE_SPLIT') {
      final id = data['expenseId']?.toString();
      if (id != null && id.isNotEmpty) await _openExpense(id);
    }
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
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ExpenseDetailsPage(expense: expense)),
    );
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
