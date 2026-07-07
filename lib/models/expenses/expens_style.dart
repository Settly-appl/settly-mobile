// lib/utils/expense_utils.dart
import 'package:flutter/material.dart';

class ExpenseStyle {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeFg;

  ExpenseStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeFg,
  });

  static ExpenseStyle getStyle(String type, bool isDark) {
    // Zamieniamy na małe litery, aby uniknąć problemów z wielkością znaków
    switch (type.toLowerCase()) {
      case 'food':
        return ExpenseStyle(
          icon: Icons.restaurant_rounded,
          iconBg: isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50,
          iconColor: Colors.red,
          badgeBg: Colors.redAccent,
          badgeFg: Colors.white,
        );
      case 'shopping':
        return ExpenseStyle(
          icon: Icons.shopping_bag_rounded,
          iconBg: isDark
              ? Colors.orange.withOpacity(0.2)
              : Colors.orange.shade50,
          iconColor: Colors.orange,
          badgeBg: Colors.orangeAccent,
          badgeFg: Colors.white,
        );
      case 'transport':
        return ExpenseStyle(
          icon: Icons.directions_car_rounded,
          iconBg: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
          iconColor: Colors.blue,
          badgeBg: Colors.blueAccent,
          badgeFg: Colors.white,
        );
      case 'entertainment':
        return ExpenseStyle(
          icon: Icons.movie_rounded,
          iconBg: isDark
              ? Colors.purple.withOpacity(0.2)
              : Colors.purple.shade50,
          iconColor: Colors.purple,
          badgeBg: Colors.purpleAccent,
          badgeFg: Colors.white,
        );
      case 'health':
        return ExpenseStyle(
          icon: Icons.medical_services_rounded,
          iconBg: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
          iconColor: Colors.green,
          badgeBg: Colors.greenAccent,
          badgeFg: Colors.white,
        );
      case 'others':
      default:
        return ExpenseStyle(
          icon: Icons.receipt_long_rounded,
          iconBg: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade50,
          iconColor: Colors.grey,
          badgeBg: Colors.grey,
          badgeFg: Colors.white,
        );
    }
  }
}
