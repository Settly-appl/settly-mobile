import 'package:settly_mobile/utils/money_input.dart';

class ExpenseMemberItem {
  final String name;
  final String amount;

  const ExpenseMemberItem({required this.name, required this.amount});

  factory ExpenseMemberItem.fromJson(Map<String, dynamic> json) {
    return ExpenseMemberItem(
      name:
          json['name']?.toString() ??
          json['itemName']?.toString() ??
          json['productName']?.toString() ??
          'Produkt',
      // Zawsze 2 miejsca po przecinku ("5.1" -> "5.10"), spójnie z formularzem.
      amount: normalizeMoney(
        json['amount']?.toString() ??
            json['price']?.toString() ??
            json['totalPrice']?.toString() ??
            '0.00',
      ),
    );
  }

  static List<ExpenseMemberItem> listFromJson(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ExpenseMemberItem.fromJson)
        .toList();
  }
}
