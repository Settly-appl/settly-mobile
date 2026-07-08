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
  });

  // ── GETTER STYLI ───────────────────────────────────────────────────────────
  ExpenseStyle style(bool isDark) => ExpenseStyle.getStyle(category, isDark);

  factory SingleExpense.fromJson(Map<String, dynamic> json) {
    return SingleExpense(
      id: json['id']?.toString(),
      name: json['shop'] ?? 'Wydatek',
      note: json['note'] ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '0.00',
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
    );
  }

  static List<SingleExpense> listFromJson(List<dynamic> json) {
    return json.map((e) => SingleExpense.fromJson(e)).toList();
  }
}
