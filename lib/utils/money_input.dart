import 'package:flutter/services.dart';

/// Ogranicza wpisywaną kwotę do formatu pieniężnego:
///  • tylko cyfry oraz jeden separator dziesiętny (`.` lub `,`),
///  • maksymalnie [decimalRange] cyfr po separatorze (domyślnie 2).
///
/// Odrzuca w locie np. `5.353`, `5.1000000`, `5.5.5` — nieprawidłowa zmiana
/// nie zostaje przyjęta i pole zachowuje poprzednią wartość.
class MoneyInputFormatter extends TextInputFormatter {
  final int decimalRange;

  MoneyInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final pattern = RegExp('^\\d*([.,]\\d{0,$decimalRange})?\$');
    return pattern.hasMatch(text) ? newValue : oldValue;
  }
}

/// Normalizuje surowy tekst kwoty do postaci z dwoma miejscami po przecinku
/// (np. `5` → `5.00`, `5,1` → `5.10`). Pusty tekst pozostaje pusty; tekst,
/// którego nie da się sparsować, zwracany jest bez zmian.
String normalizeMoney(String raw, {int decimals = 2}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  var t = trimmed.replaceAll(',', '.');
  // Osierocony separator na końcu ("5." → "5") aby dało się sparsować.
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  if (t.isEmpty) return '';
  final value = double.tryParse(t);
  if (value == null) return raw;
  return value.toStringAsFixed(decimals);
}

/// Usuwa zbędne końcowe zera z części dziesiętnej, aby ułatwić edycję po
/// ponownym wejściu w pole: `5.00` → `5`, `5.10` → `5.1`, `5.15` → `5.15`.
/// Tekst bez separatora oraz pusty pozostają bez zmian.
String stripTrailingZeros(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  if (!trimmed.contains('.') && !trimmed.contains(',')) return trimmed;
  var s = trimmed.replaceAll(',', '.');
  s = s.replaceFirst(RegExp(r'0+$'), ''); // końcowe zera części dziesiętnej
  s = s.replaceFirst(RegExp(r'\.$'), ''); // osierocony separator
  return s;
}
