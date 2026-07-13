import 'package:settly_mobile/utils/money_input.dart';

import 'expens_style.dart';

class SingleExpense {
  final String? id;
  final String name;
  final String note;
  final String totalAmount;
  String userShare; // Mutable - zaktualizować po pobraniu z API
  final String category;
  final String currency;
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

  bool get isShared => splitCount > 0;

  /// Some but not all participants have settled (only meaningful to the owner).
  bool get isPartiallySettled =>
      isShared && settledCount > 0 && settledCount < splitCount;

  SingleExpense({
    this.id,
    required this.name,
    this.note = '',
    required this.totalAmount,
    this.userShare = '',
    this.category = 'Wydatek',
    this.currency = 'PLN',
    required this.scanned,
    required this.date,
    required this.createdAt,
    this.projectId,
    this.ownerId,
    this.splitCount = 0,
    this.settledCount = 0,
    this.settled = false,
    this.canSettle = false,
  });

  // ── GETTER STYLI ───────────────────────────────────────────────────────────
  ExpenseStyle style(bool isDark) => ExpenseStyle.getStyle(category, isDark);

  factory SingleExpense.fromJson(Map<String, dynamic> json) {
    return SingleExpense(
      id: json['id']?.toString(),
      name: json['shop'] ?? 'Wydatek',
      note: json['note'] ?? '',
      // Kwoty z API bywają nieprzycięte ("5.1"). Normalizujemy raz, przy
      // wejściu, żeby każdy widok (lista, główna, szczegóły, piny) pokazywał
      // spójne 2 miejsca po przecinku — tak jak wymusza to formularz.
      totalAmount: normalizeMoney(json['totalAmount']?.toString() ?? '0.00'),
      category: json['category']?.toString() ?? 'Wydatek',
      currency: json['currency']?.toString() ?? 'PLN',
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
    );
  }

  static List<SingleExpense> listFromJson(List<dynamic> json) {
    return json.map((e) => SingleExpense.fromJson(e)).toList();
  }
}
