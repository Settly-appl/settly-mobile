import 'package:flutter/material.dart';

enum PinnedItemType { expense, project }

class PinnedItem {
  final String id; // unikalny identyfikator (np. UUID z backendu)
  final PinnedItemType type;
  final String title;
  final String subtitle;
  final String amount; // dla expense: kwota, dla project: suma lub "-"
  final String currency;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final DateTime pinnedAt;

  // Opcjonalne dane specyficzne dla projektu (null gdy expense)
  final String? projectId;
  final int? membersCount;

  const PinnedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.pinnedAt,
    this.projectId,
    this.membersCount,
  });

  // ── Serializacja (SharedPreferences) ─────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'currency': currency,
    'iconCodePoint': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'iconBgValue': iconBg.value,
    'iconColorValue': iconColor.value,
    'pinnedAt': pinnedAt.toIso8601String(),
    if (projectId != null) 'projectId': projectId,
    if (membersCount != null) 'membersCount': membersCount,
  };

  factory PinnedItem.fromJson(Map<String, dynamic> json) {
    return PinnedItem(
      id: json['id'] as String,
      type: PinnedItemType.values.byName(json['type'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      iconBg: Color(json['iconBgValue'] as int),
      iconColor: Color(json['iconColorValue'] as int),
      pinnedAt: DateTime.parse(json['pinnedAt'] as String),
      projectId: json['projectId'] as String?,
      membersCount: json['membersCount'] as int?,
    );
  }

  // ── Fabryki ────────────────────────────────────────────────────────────────

  /// Tworzy PinnedItem z RecentExpense.
  static PinnedItem fromExpense({
    required String id,
    required String name,
    required String subtitle,
    required String amount,
    required String currency,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return PinnedItem(
      id: id,
      type: PinnedItemType.expense,
      title: name,
      subtitle: subtitle,
      amount: amount,
      currency: currency,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      pinnedAt: DateTime.now(),
    );
  }

  /// Tworzy PinnedItem z projektu — wypełnij gdy będzie funkcjonalność projektów.
  /// Na razie używany przez "otwartą furtkę" w PinPickerSheet.
  static PinnedItem fromProject({
    required String projectId,
    required String name,
    required String description,
    required String totalAmount,
    required String currency,
    required int membersCount,
  }) {
    return PinnedItem(
      id: projectId,
      type: PinnedItemType.project,
      title: name,
      subtitle: description,
      amount: totalAmount,
      currency: currency,
      icon: Icons.group_rounded,
      iconBg: Colors.blue.withOpacity(0.2),
      iconColor: Colors.blueAccent,
      pinnedAt: DateTime.now(),
      projectId: projectId,
      membersCount: membersCount,
    );
  }
}
