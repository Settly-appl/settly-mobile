import 'package:flutter/cupertino.dart';

class SheetOption {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const SheetOption({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });
}
