import 'package:settly_mobile/utils/money_format.dart';
import 'package:settly_mobile/utils/money_input.dart';

import 'expense_member_item.dart';

class ExpenseMember {
  final String userId;

  /// Id wiersza podziału — potrzebne, by rozliczyć pojedynczą osobę
  /// (PATCH expenses/{id}/splits/{splitId}/settle).
  final String? splitId;
  final String amount;

  /// Ten sam udział w walucie bazowej wraz z walutami obu kwot — to w walucie
  /// bazowej ludzie sobie faktycznie oddają pieniądze.
  final String baseAmount;
  final String currency;
  final String baseCurrency;

  final String splitType;
  final String displayName;
  final bool settled;

  /// Uczestnik ZGŁOSIŁ, że zapłacił — sugestia dla właściciela do
  /// potwierdzenia, nie fakt. Backend zeruje ją przy rozliczeniu.
  final bool declaredPaid;
  final List<ExpenseMemberItem> items;

  ExpenseMember({
    required this.userId,
    this.splitId,
    required this.amount,
    this.baseAmount = '',
    this.currency = kDefaultCurrency,
    this.baseCurrency = kDefaultCurrency,
    required this.splitType,
    required this.displayName,
    this.settled = false,
    this.declaredPaid = false,
    this.items = const [],
  });

  factory ExpenseMember.fromJson(Map<String, dynamic> json) {
    return ExpenseMember(
      userId: (json['userId'] as String?) ?? '',
      splitId: json['id']?.toString(),
      amount: normalizeMoney(json['amount']?.toString() ?? '0.00'),
      // Starsze udziały (sprzed przeliczania) nie mają kwoty bazowej — wtedy
      // zostaje sama kwota wydatku, zamiast udawać przeliczenie.
      baseAmount: json['baseAmount'] == null
          ? ''
          : normalizeMoney(json['baseAmount'].toString()),
      currency: json['currency']?.toString() ?? kDefaultCurrency,
      baseCurrency: json['baseCurrency']?.toString() ?? kDefaultCurrency,
      splitType: json['splitType']?.toString() ?? '',
      displayName: '',
      settled: json['settled'] == true,
      declaredPaid: json['declaredPaid'] == true,
      items: ExpenseMemberItem.listFromJson(json['items']),
    );
  }

  static List<ExpenseMember> listFromJson(List<dynamic> json) {
    return json
        .map((e) => ExpenseMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  ExpenseMember copyWith({
    String? displayName,
    String? amount,
    bool? settled,
    bool? declaredPaid,
    List<ExpenseMemberItem>? items,
  }) {
    return ExpenseMember(
      userId: this.userId,
      splitId: this.splitId,
      splitType: this.splitType,
      amount: amount ?? this.amount,
      baseAmount: this.baseAmount,
      currency: this.currency,
      baseCurrency: this.baseCurrency,
      displayName: displayName ?? this.displayName,
      settled: settled ?? this.settled,
      declaredPaid: declaredPaid ?? this.declaredPaid,
      items: items ?? this.items,
    );
  }
}
