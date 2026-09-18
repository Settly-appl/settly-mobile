import 'package:settly_mobile/utils/money_format.dart';

/// Jeden nierozliczony udział, z którego składa się saldo z „Rozliczeń".
///
/// Saldo to jedna liczba — różnica dwóch stron. Ta klasa jest tą różnicą
/// rozłożoną na wydatki: [owedToMe] mówi, po której stronie leży udział, a nie
/// jest to to samo co „mój wydatek": mój udział w cudzym wydatku to coś, co
/// jestem winien, choć wydatku nie tworzyłem.
class BalanceItem {
  final String expenseId;

  /// Nazwa wydatku; pusta dla wydatków sprzed obowiązku nazwy — podmienia ją
  /// `AppTexts.expenseName` przy wyświetlaniu, tak jak wszędzie indziej.
  final String name;
  final String category;
  final DateTime date;
  final String? projectName;

  /// Udział w walucie wydatku — to, co zapłacono na miejscu.
  final double shareAmount;
  final String currency;

  /// Ten sam udział w walucie bazowej — jedyna wartość, którą wolno sumować.
  /// `null` znaczy KURS NIEZNANY (wydatki sprzed przeliczania, backend V10):
  /// backend pomija taki udział w saldzie, więc podstawienie tu [shareAmount]
  /// wpisałoby funty do sumy w złotówkach. Pokazujemy go mimo to — udział poza
  /// saldem to rzecz do naprawienia, nie do ukrycia.
  final double? shareBaseAmount;
  final String baseCurrency;

  /// `true`: druga strona jest winna mnie. `false`: ja jestem winien jej.
  final bool owedToMe;

  /// Dłużnik zgłosił zapłatę i czeka na potwierdzenie właściciela.
  final bool declaredPaid;

  const BalanceItem({
    required this.expenseId,
    required this.name,
    required this.category,
    required this.date,
    this.projectName,
    required this.shareAmount,
    required this.currency,
    this.shareBaseAmount,
    required this.baseCurrency,
    required this.owedToMe,
    this.declaredPaid = false,
  });

  /// Udział czeka na kurs — nie wchodzi do salda.
  bool get needsRate => shareBaseAmount == null;

  factory BalanceItem.fromJson(Map<String, dynamic> json) {
    return BalanceItem(
      expenseId: json['expenseId'].toString(),
      name: json['shop']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      projectName: json['projectName']?.toString(),
      shareAmount: (json['shareAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? kDefaultCurrency,
      shareBaseAmount: (json['shareBaseAmount'] as num?)?.toDouble(),
      baseCurrency: json['baseCurrency']?.toString() ?? kDefaultCurrency,
      owedToMe: json['owedToMe'] as bool? ?? false,
      declaredPaid: json['declaredPaid'] as bool? ?? false,
    );
  }

  static List<BalanceItem> listFromJson(List<dynamic> json) {
    return json
        .map((e) => BalanceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
