import 'package:flutter/material.dart';
import 'package:settly_mobile/models/single_expense.dart';

enum PinnedItemType { expense, project }

class PinnedItem {
  final String id;
  final PinnedItemType type;
  final String title;
  final String subtitle;
  final String amount;
  final String currency;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final DateTime pinnedAt;

  // Opcjonalne dane specyficzne dla projektu
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

  // ── Fabryki ────────────────────────────────────────────────────────────────

  /// Główna fabryka tworząca PinnedItem z SingleExpense
  factory PinnedItem.fromExpense(SingleExpense expense, bool isDark) {
    final style = expense.style(isDark);
    return PinnedItem(
      id: expense.id ?? '',
      type: PinnedItemType.expense,
      title: expense.name,
      subtitle: expense.note,
      amount: expense.totalAmount,
      currency: expense.currency,
      icon: style.icon,
      iconBg: style.iconBg,
      iconColor: style.iconColor,
      pinnedAt: DateTime.now(),
    );
  }

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
      iconBg: Colors.blue.withValues(alpha: 0.2),
      iconColor: Colors.blueAccent,
      pinnedAt: DateTime.now(),
      projectId: projectId,
      membersCount: membersCount,
    );
  }
}
