import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settly_mobile/models/app_notification.dart';

/// App-wide store of received notifications. The bell listens to it for the
/// unread badge + list; screens can also listen to [stream] to react to
/// specific notification types (e.g. refresh a list).
///
/// Powiadomienia są **zapisywane na dysku**, żeby nie znikały po odświeżeniu
/// aplikacji: ktoś, kto nie otworzył (albo zamknął) powiadomienia, ma je nadal
/// pod dzwonkiem i o nim nie zapomni.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._internal();
  static final NotificationsStore _instance = NotificationsStore._internal();
  factory NotificationsStore() => _instance;

  static const _storageKey = 'notifications_inbox';

  /// Ile powiadomień trzymamy — starsze wypadają, żeby lista nie rosła bez końca.
  static const _maxItems = 50;

  final List<AppNotification> _items = [];
  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();

  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  /// Emits each notification as it arrives, for screens that need to react
  /// rather than just show a badge.
  Stream<AppNotification> get stream => _controller.stream;

  /// Wczytuje zapisane powiadomienia. Wywołaj raz przy starcie aplikacji.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
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
      // Uszkodzony zapis nie może wywrócić startu aplikacji — zaczynamy pusto.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_items.map((n) => n.toJson()).toList()),
      );
    } catch (_) {
      // Zapis to tylko wygoda — nie przerywamy działania, gdy się nie uda.
    }
  }

  void add(AppNotification notification) {
    // To samo powiadomienie potrafi trafić tu dwa razy (np. z pierwszego planu,
    // a potem przy kliknięciu) — nie duplikujemy go na liście.
    final key = notification.dedupeKey;
    if (_items.any((n) => n.dedupeKey == key)) return;

    _items.insert(0, notification);
    if (_items.length > _maxItems) {
      _items.removeRange(_maxItems, _items.length);
    }
    _controller.add(notification);
    notifyListeners();
    unawaited(_persist());
  }

  void markAllRead() {
    var changed = false;
    for (final n in _items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      unawaited(_persist());
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    unawaited(_persist());
  }
}
