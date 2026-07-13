import 'package:firebase_messaging/firebase_messaging.dart';

/// An in-app notification, built from an FCM [RemoteMessage].
class AppNotification {
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  bool read;

  AppNotification({
    required this.title,
    required this.body,
    this.type,
    this.data = const {},
    DateTime? receivedAt,
    this.read = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      title:
          message.notification?.title ??
          message.data['title'] as String? ??
          'Powiadomienie',
      body:
          message.notification?.body ?? message.data['body'] as String? ?? '',
      type: message.data['type'] as String?,
      data: message.data,
    );
  }

  /// Klucz do rozpoznania duplikatu tego samego powiadomienia (np. gdy przyjdzie
  /// i z serwisu, i z pierwszego planu).
  String get dedupeKey =>
      '$title|$body|${receivedAt.millisecondsSinceEpoch ~/ 1000}';

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type,
    'data': data,
    'receivedAt': receivedAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title']?.toString() ?? 'Powiadomienie',
      body: json['body']?.toString() ?? '',
      type: json['type'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      receivedAt:
          DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }
}
