class ExpenseRequest {
  final double totalAmount;
  final String shop;
  final DateTime date;
  //final String category;
  final String? note;
  //final String? projectId;
  //final String splitType;
  //final List<String> participants;
  //final String currency;

  ExpenseRequest({
    required this.totalAmount,
    required this.shop,
    required this.date,
    //required this.category,
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
      //'category': category,
      'note': note,
      //'project_id': projectId,
      //'split_type': splitType,
      //'participants': participants,
      // 'currency': currency,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
