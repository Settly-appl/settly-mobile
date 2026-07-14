import 'package:settly_mobile/utils/money_input.dart';

import 'expense_member_item.dart';

class ExpenseMember {
  final String userId;

  /// Id wiersza podziału — potrzebne, by rozliczyć pojedynczą osobę
  /// (PATCH expenses/{id}/splits/{splitId}/settle).
  final String? splitId;
  final String amount;
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
      displayName: displayName ?? this.displayName,
      settled: settled ?? this.settled,
      declaredPaid: declaredPaid ?? this.declaredPaid,
      items: items ?? this.items,
    );
  }
}
