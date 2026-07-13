import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Skrzynka powiadomień pokazywana pod dzwonkiem.
///
/// Źródłem prawdy jest **backend**, nie push. Push jest „wyślij i zapomnij":
/// jeśli użytkownik zamknie powiadomienie systemowe, nigdy go nie kliknie, nie
/// ma tokenu albo przeglądarka odmawia rejestracji (np. Brave), aplikacja nigdy
/// by się o nim nie dowiedziała. Dlatego backend zapisuje każde powiadomienie i
/// stąd je pobieramy — dzwonek pokazuje **nieprzeczytane**, a kliknięcie
/// (systemowego dymka albo wpisu na liście) oznacza je jako przeczytane, więc
/// znika i nie wraca.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._internal();
  static final NotificationsStore _instance = NotificationsStore._internal();
  factory NotificationsStore() => _instance;

  final _api = ApiServiceRequest();

  final List<AppNotification> _items = [];
  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.length; // pobieramy wyłącznie nieprzeczytane

  /// Emits each notification as it arrives, for screens that need to react
  /// rather than just show a badge.
  Stream<AppNotification> get stream => _controller.stream;

  /// Pobiera nieprzeczytane powiadomienia z backendu. Wywołuj przy starcie i
  /// przy otwarciu dzwonka.
  Future<void> refresh() async {
    try {
      final response = await _api.request(
        endpoint: 'notifications',
        method: HttpMethod.get,
      );
      if (response == null || response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return;

      _items
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson),
        );
      notifyListeners();
    } catch (_) {
      // Brak sieci nie może wywrócić dzwonka — zostaje to, co już mamy.
    }
  }

  /// Powiadomienie, które przyszło przy otwartej aplikacji. Jest już zapisane na
  /// backendzie, więc trzymamy je tylko lokalnie, żeby dzwonek zareagował od razu.
  void add(AppNotification notification) {
    final id = notification.id;
    if (id != null && _items.any((n) => n.id == id)) return; // już mamy

    _items.insert(0, notification);
    _controller.add(notification);
    notifyListeners();
  }

  /// Oznacza jedno powiadomienie jako przeczytane — znika z dzwonka na dobre.
  Future<void> markRead(String? notificationId) async {
    if (notificationId == null) return;

    _items.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      await _api.request(
        endpoint: 'notifications/$notificationId/read',
        method: HttpMethod.patch,
      );
    } catch (_) {
      // Nawet gdy zapis się nie uda, kolejne odświeżenie przywróci stan z serwera.
    }
  }

  Future<void> markAllRead() async {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();

    try {
      await _api.request(
        endpoint: 'notifications/read-all',
        method: HttpMethod.post,
      );
    } catch (_) {
      // j.w.
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
