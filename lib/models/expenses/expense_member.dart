import 'expense_member_item.dart';

class ExpenseMember {
  final String userId;
  final String amount;
  final String splitType;
  final String displayName;
  final List<ExpenseMemberItem> items;

  ExpenseMember({
    required this.userId,
    required this.amount,
    required this.splitType,
    required this.displayName,
    this.items = const [],
  });

  factory ExpenseMember.fromJson(Map<String, dynamic> json) {
    return ExpenseMember(
      userId: (json['userId'] as String?) ?? '',
      amount: (json['amount']?.toString()) ?? '0.00',
      splitType: json['splitType']?.toString() ?? '',
      displayName: '',
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
    List<ExpenseMemberItem>? items,
  }) {
    return ExpenseMember(
      userId: this.userId,
      splitType: this.splitType,
      amount: amount ?? this.amount,
      displayName: displayName ?? this.displayName,
      items: items ?? this.items,
    );
  }
}
