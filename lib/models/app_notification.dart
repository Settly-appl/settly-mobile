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
}
