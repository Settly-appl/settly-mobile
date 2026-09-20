/// Daty pokazywane w interfejsie — zapis liczbowy, bo jest krótki i nie zmienia
/// długości między polskim a angielskim.
///
/// Nazwy miesięcy mają własne metody w `AppTexts` (odmieniane!) i służą tam,
/// gdzie data stoi w zdaniu. Tu chodzi o fakt w rogu kafelka.
String formatShortDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d.$m.${date.year}';
}

/// Zakres dat wyjazdu: `12.09 – 20.09.2026`.
///
/// Rok pojawia się raz, gdy oba końce są w tym samym roku — wyjazd trwa zwykle
/// kilka dni, a powtórzony rok tylko zabiera miejsce na kafelku. Zwraca `null`,
/// gdy brakuje któregokolwiek końca: pół zakresu nie jest terminem wyjazdu i
/// nie bierze udziału w automatycznym wyborze projektu, więc nie udajemy, że
/// jest.
String? formatDateSpan(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final from = start.year == end.year
      ? '${start.day.toString().padLeft(2, '0')}'
            '.${start.month.toString().padLeft(2, '0')}'
      : formatShortDate(start);
  return '$from – ${formatShortDate(end)}';
}
