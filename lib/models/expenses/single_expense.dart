import 'package:settly_mobile/utils/money_input.dart';

import 'expens_style.dart';

class SingleExpense {
  final String? id;
  final String name;
  final String note;
  final String totalAmount;
  String userShare; // Mutable - zaktualizować po pobraniu z API

  /// Ten sam udział w walucie bazowej. `userShare` jest łańcuchem do
  /// wyświetlenia ("12.50 £") i nie nadaje się do sumowania: dodanie funtów do
  /// złotówek daje liczbę, która nie jest żadną kwotą. Każde podsumowanie na
  /// liście wydatków liczy tę wartość.
  double? userShareBase;
  final String category;
  final String currency;

  /// Waluta bazowa właściciela, kurs, po którym kupił [currency], oraz kwota po
  /// przeliczeniu. Dla wydatku już w walucie bazowej kurs wynosi 1, a
  /// [baseAmount] równa się [totalAmount].
  final String baseCurrency;
  /// `null` oznacza kurs NIEZNANY, nie kurs 1 — wydatek w obcej walucie
  /// sprzed przeliczania (migracja V10). Jego udziały są pomijane w saldach,
  /// zamiast wpadać tam po kursie 1, czyli funt liczony jak złotówka.
  final double? rateToBase;

  /// Wydatek czeka na kurs — bez niego nie wchodzi do rozliczeń.
  bool get needsRate => rateToBase == null;
  final String baseAmount;

  /// Wydatek w obcej walucie — wtedy warto pokazać obie kwoty.
  bool get isForeign => currency != baseCurrency || needsRate;

  final bool scanned;
  final DateTime date;
  final DateTime createdAt;
  final String? projectId;
  final String? ownerId; // creator; only the owner may edit/delete

  // Settlement, as seen by the current user (see backend ExpenseResponse):
  //  - splitCount: people who owe the owner. 0 = personal expense, nothing to settle.
  //  - settledCount: how many of them have settled.
  //  - settled: owner -> everyone paid; participant -> their own share is paid.
  int splitCount;
  int settledCount;
  bool settled;

  /// Czy ten użytkownik może w ogóle rozliczyć ten wydatek.
  ///
  /// `false` dla członka projektu, który widzi cudzy wydatek we wspólnej księdze
  /// projektu — nie ma w nim udziału, backend i tak by odmówił, więc nie
  /// pokazujemy gestu rozliczenia.
  bool canSettle;

  /// Ilu nierozliczonych uczestników ZGŁOSIŁO zapłatę (sugestia dla
  /// właściciela, nie fakt — patrz backend `declaredCount`).
  int declaredCount;

  /// Własny udział tego użytkownika ma zgłoszoną zapłatę (czeka na
  /// potwierdzenie właściciela). Zawsze `false` dla właściciela.
  bool declared;

  bool get isShared => splitCount > 0;

  /// Wydatek, który widzę wyłącznie dlatego, że leży we wspólnej księdze
  /// projektu — nie jestem ani jego autorem, ani uczestnikiem podziału.
  ///
  /// Rozstrzyga [canSettle]: backend ustawia je na `false` dokładnie wtedy, gdy
  /// nie ma dla mnie w tym wydatku żadnego udziału. Samo w sobie nie wystarcza,
  /// bo ma je też mój własny wydatek osobisty (nie ma w nim czego rozliczać) —
  /// stąd porównanie właściciela obok.
  bool isBystander(String? viewerId) =>
      viewerId != null &&
      ownerId != null &&
      ownerId != viewerId &&
      !canSettle;

  /// Some but not all participants have settled (only meaningful to the owner).
  bool get isPartiallySettled =>
      isShared && settledCount > 0 && settledCount < splitCount;

  SingleExpense({
    this.id,
    required this.name,
    this.note = '',
    required this.totalAmount,
    this.userShare = '',
    this.userShareBase,
    this.category = 'Wydatek',
    this.currency = 'PLN',
    this.baseCurrency = 'PLN',
    this.rateToBase,
    this.baseAmount = '',
    required this.scanned,
    required this.date,
    required this.createdAt,
    this.projectId,
    this.ownerId,
    this.splitCount = 0,
    this.settledCount = 0,
    this.settled = false,
    this.canSettle = false,
    this.declaredCount = 0,
    this.declared = false,
  });

  // ── GETTER STYLI ───────────────────────────────────────────────────────────
  ExpenseStyle style(bool isDark) => ExpenseStyle.getStyle(category, isDark);

  factory SingleExpense.fromJson(Map<String, dynamic> json) {
    return SingleExpense(
      id: json['id']?.toString(),
      // Brak nazwy zostaje brakiem. Wstawiane tu wcześniej 'Wydatek' było
      // twardym polskim napisem w modelu (widocznym też po angielsku) i — co
      // gorsza — wpadało do formularza edycji, więc zapisanie takiego wydatku
      // utrwalało zmyśloną nazwę w bazie. Podmianę robi AppTexts.expenseName
      // przy wyświetlaniu.
      name: json['shop']?.toString() ?? '',
      note: json['note'] ?? '',
      // Kwoty z API bywają nieprzycięte ("5.1"). Normalizujemy raz, przy
      // wejściu, żeby każdy widok (lista, główna, szczegóły, piny) pokazywał
      // spójne 2 miejsca po przecinku — tak jak wymusza to formularz.
      totalAmount: normalizeMoney(json['totalAmount']?.toString() ?? '0.00'),
      category: json['category']?.toString() ?? 'Wydatek',
      currency: json['currency']?.toString() ?? 'PLN',
      baseCurrency: json['baseCurrency']?.toString() ?? 'PLN',
      rateToBase: (json['rateToBase'] as num?)?.toDouble(),
      // Brak kwoty bazowej zostaje brakiem. Podstawienie tu kwoty w walucie
      // wydatku dałoby liczbę wyglądającą na złotówki, która nią nie jest —
      // i wróciłby dokładnie ten błąd, który usuwa migracja V10.
      baseAmount: json['baseAmount'] == null
          ? ''
          : normalizeMoney(json['baseAmount'].toString()),
      scanned: json['isScanned'] ?? false,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      projectId: json['projectId']?.toString(),
      ownerId: json['userId']?.toString(),
      splitCount: (json['splitCount'] as num?)?.toInt() ?? 0,
      settledCount: (json['settledCount'] as num?)?.toInt() ?? 0,
      settled: json['settled'] as bool? ?? false,
      canSettle: json['canSettle'] as bool? ?? false,
      declaredCount: (json['declaredCount'] as num?)?.toInt() ?? 0,
      declared: json['declared'] as bool? ?? false,
    );
  }

  static List<SingleExpense> listFromJson(List<dynamic> json) {
    return json.map((e) => SingleExpense.fromJson(e)).toList();
  }
}
