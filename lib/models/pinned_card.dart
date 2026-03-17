import 'package:flutter/material.dart';
import 'package:settly_mobile/models/recent_expense.dart';

class PinnedCard extends RecentExpense {
  final Color amountColor;

  PinnedCard({
    required super.name,
    required super.subtitle,
    required super.totalAmount,
    required super.type,
    required super.iconBg,
    required super.iconColor,
    required super.badgeBg,
    required super.badgeFg,
    required super.icon,
    required super.scanned,
    required super.date,
    required super.createdAt,
    required this.amountColor,
  });
  String get amount => totalAmount;
}
