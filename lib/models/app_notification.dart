import 'package:firebase_messaging/firebase_messaging.dart';

/// Powiadomienie widoczne pod dzwonkiem.
///
/// Źródłem prawdy jest skrzynka na backendzie (`GET /notifications`) — push jest
/// „wyślij i zapomnij", więc powiadomienie zamknięte albo nigdy niekliknięte i
/// tak tam jest. [id] to identyfikator wpisu w skrzynce; po kliknięciu oznaczamy
/// go jako przeczytany, żeby zniknął z dzwonka.
class AppNotification {
  /// Id wpisu w skrzynce. Null tylko dla powiadomień sprzed tej zmiany.
  final String? id;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  bool read;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    this.type,
    this.data = const {},
    DateTime? receivedAt,
    this.read = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      // Backend dokłada notificationId do payloadu, żeby kliknięcie dało się
      // powiązać z konkretnym wpisem w skrzynce.
      id: message.data['notificationId'] as String?,
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

  /// Wpis pobrany ze skrzynki na backendzie.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Powiadomienie',
      body: json['body']?.toString() ?? '',
      type: json['type'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      receivedAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
