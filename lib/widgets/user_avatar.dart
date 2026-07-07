import 'package:flutter/material.dart';

/// Kółko z avatarem użytkownika. Jeśli dostępny jest [avatarUrl] (np. zdjęcie z
/// Google), pokazuje zdjęcie; w przeciwnym razie inicjały (litery imienia/nazwiska).
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name; // do wyliczenia inicjałów, gdy brak [initials]
  final String? initials; // gotowe inicjały (nadpisują wyliczenie z [name])
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? fontSize;
  final FontWeight fontWeight;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.initials,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.fontSize,
    this.fontWeight = FontWeight.bold,
  });

  /// Inicjały z nazwy: pierwsze litery dwóch pierwszych słów, np. "Anna
  /// Kowalska" → "AK", "test" → "T", puste → "?".
  static String initialsOf(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasPhoto ? NetworkImage(avatarUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              initials ?? initialsOf(name),
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize ?? radius * 0.7,
                fontWeight: fontWeight,
              ),
            ),
    );
  }
}
