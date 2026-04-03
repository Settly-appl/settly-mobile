import 'package:flutter/material.dart';

class RecentExpense {
  final String name;
  final String subtitle;
  final String totalAmount;
  final String type;
  final String currency;
  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeFg;
  final IconData icon;
  final bool scanned;
  final DateTime date;
  final DateTime createdAt;
  final String? projectId;

  const RecentExpense({
    required this.name,
    required this.subtitle,
    required this.totalAmount,
    required this.type,
    required this.currency,
    required this.iconBg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeFg,
    required this.icon,
    required this.scanned,
    required this.date,
    required this.createdAt,
    this.projectId,
  });
}
