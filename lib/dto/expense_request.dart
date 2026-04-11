class ExpenseRequest {
  final double totalAmount;
  final String shop;
  final DateTime date;
  final bool isScanned;
  final String category;
  final String currency;
  final String? note;
  //final String? projectId;
  //final String splitType;
  //final List<String> participants;

  ExpenseRequest({
    required this.totalAmount,
    required this.shop,
    required this.date,
    required this.isScanned,
    required this.category,
    required this.currency,
    this.note,
    //required this.projectId,
    //required this.splitType,
    //required this.participants,
    //this.currency = 'PLN',
  });

  // Mapper: Przekształca dane z klasy na Mapę (JSON) dla backendu
  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'shop': shop,
      'date': date.toIso8601String(),
      'scanned': isScanned,
      'category': category,
      'currency': currency,
      'note': note,
      //'project_id': projectId,
      //'split_type': splitType,
      //'participants': participants,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
