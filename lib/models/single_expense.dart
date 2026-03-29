import 'package:settly_mobile/models/recent_expense.dart';

import 'expens_style.dart';

class SingleExpense {
  final String name;
  final String? note;
  final String totalAmount;
  final String? type;
  final bool scanned;
  final DateTime date;
  final DateTime createdAt;
  final String? projectId;

  const SingleExpense({
    required this.name,
    required this.note,
    required this.totalAmount,
    required this.type,
    required this.scanned,
    required this.date,
    required this.createdAt,
    this.projectId,
  });
  RecentExpense toRecentExpense(bool isDark) {
    final style = ExpenseStyle.getStyle(type ?? 'default', isDark);

    return RecentExpense(
      name: name,
      subtitle: note ?? '',
      totalAmount: totalAmount,
      type: type ?? 'default',
      iconBg: style.iconBg,
      iconColor: style.iconColor,
      badgeBg: style.badgeBg,
      badgeFg: style.badgeFg,
      icon: style.icon,
      scanned: scanned,
      date: date,
      createdAt: createdAt,
      projectId: projectId ?? null,
    );
  }

  factory SingleExpense.fromJson(Map<String, dynamic> json) {
    return SingleExpense(
      name: json['shop'],
      note: json['note'] ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '0.00',
      type: json['type']?.toString() ?? 'Wydatek',
      scanned: json['isScanned'] ?? false,
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      projectId: json['projectId'] ?? null,
    );
  }
  static List<RecentExpense> listFromJson(List<dynamic> json, bool isDark) {
    return json
        .map((e) => SingleExpense.fromJson(e).toRecentExpense(isDark))
        .toList();
  }
}
