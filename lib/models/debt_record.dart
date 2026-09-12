import '../utils/money_format.dart';

class DebtRecord {
  final String id;
  final String? projectId;
  final String fromUserId;
  final String toUserId;
  final double amount;

  /// Waluta rozliczenia — waluta bazowa wierzyciela w chwili rozliczenia.
  final String currency;
  final bool settled;
  final DateTime? settledAt;
  final DateTime? createdAt;

  const DebtRecord({
    required this.id,
    this.projectId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.currency = kDefaultCurrency,
    required this.settled,
    this.settledAt,
    this.createdAt,
  });

  factory DebtRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return DebtRecord(
      id: json['id'].toString(),
      projectId: json['projectId'] as String?,
      fromUserId: json['fromUserId'].toString(),
      toUserId: json['toUserId'].toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? kDefaultCurrency,
      settled: json['settled'] == true,
      settledAt: parse(json['settledAt']),
      createdAt: parse(json['createdAt']),
    );
  }

  static List<DebtRecord> listFromJson(List<dynamic> json) {
    return json
        .map((e) => DebtRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
