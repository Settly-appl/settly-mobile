import 'package:flutter/material.dart';

class SingleExpense {
  final String name;
  final String note;
  final String totalAmount;
  final String type;
  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeFg;
  final IconData icon;
  final bool scanned;
  final DateTime date;
  final DateTime createdAt;

  const SingleExpense({
    required this.name,
    required this.note,
    required this.totalAmount,
    required this.type,
    required this.iconBg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeFg,
    required this.icon,
    required this.scanned,
    required this.date,
    required this.createdAt,
  });
}
