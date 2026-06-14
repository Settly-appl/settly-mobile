import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:settly_mobile/models/app_notification.dart';

/// App-wide store of received notifications. The bell listens to it for the
/// unread badge + list; screens can also listen to [stream] to react to
/// specific notification types (e.g. refresh a list).
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._internal();
  static final NotificationsStore _instance = NotificationsStore._internal();
  factory NotificationsStore() => _instance;

  final List<AppNotification> _items = [];
  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  /// Emits each notification as it arrives, for screens that need to react
  /// rather than just show a badge.
  Stream<AppNotification> get stream => _controller.stream;

  void add(AppNotification notification) {
    _items.insert(0, notification);
    _controller.add(notification);
    notifyListeners();
  }

  void markAllRead() {
    var changed = false;
    for (final n in _items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
