enum SplitType {
  equal,
  custom,
  byItems;

  String get apiValue {
    switch (this) {
      case SplitType.equal:
        return 'EQUAL';
      case SplitType.custom:
        return 'CUSTOM';
      case SplitType.byItems:
        return 'BY_ITEM';
    }
  }
}

String _formatLocalDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

double _round2(double v) => double.parse(v.toStringAsFixed(2));

class CreateExpenseRequest {
  final String shop;
  final String? note;
  final String currency;
  final String category;
  final double totalAmount;
  final DateTime date;
  final String? projectId;

  const CreateExpenseRequest({
    required this.shop,
    required this.currency,
    required this.category,
    required this.totalAmount,
    required this.date,
    this.note,
    this.projectId,
  });

  Map<String, dynamic> toJson() => {
    'shop': shop,
    'note': note,
    'currency': currency,
    'category': category,
    'totalAmount': _round2(totalAmount),
    'date': _formatLocalDate(date),
    'projectId': projectId,
  };
}

class CreateExpenseItemRequest {
  final String name;
  final double price;
  final double? quantity;
  final String? category;

  const CreateExpenseItemRequest({
    required this.name,
    required this.price,
    this.quantity,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': _round2(price),
    if (quantity != null) 'quantity': quantity,
    if (category != null) 'category': category,
  };
}

class SplitParticipantRequest {
  final String friendId;
  final double amount;

  const SplitParticipantRequest({required this.friendId, required this.amount});

  Map<String, dynamic> toJson() => {
    'friendId': friendId,
    'amount': _round2(amount),
  };
}

/// Kto jest przypisany do produktu i (opcjonalnie) za ile każdy.
///
/// Wysyłamy dokładnie jedno z dwóch:
///  * [userIds] — dzielimy produkt po równo; zaokrąglenie robi backend, więc
///    części zawsze sumują się dokładnie do ceny produktu;
///  * [shares] — kwota per osoba, gdy podział jest nierówny. Muszą sumować się
///    do ceny produktu (backend to waliduje).
class ItemSplitAssignment {
  final String expenseItemId;
  final List<String>? userIds;
  final Map<String, double>? shares;

  const ItemSplitAssignment({
    required this.expenseItemId,
    this.userIds,
    this.shares,
  });

  Map<String, dynamic> toJson() => {
    'expenseItemId': expenseItemId,
    if (shares != null && shares!.isNotEmpty)
      'shares': [
        for (final e in shares!.entries) {'userId': e.key, 'amount': e.value},
      ]
    else
      'userIds': userIds ?? const <String>[],
  };
}

class CreateExpenseSplitRequest {
  final SplitType splitType;
  final List<SplitParticipantRequest> participants;
  final List<ItemSplitAssignment>? itemAssignments;

  const CreateExpenseSplitRequest({
    required this.splitType,
    required this.participants,
    this.itemAssignments,
  });

  Map<String, dynamic> toJson() => {
    'expenseSplitType': splitType.apiValue,
    'participants': participants.map((p) => p.toJson()).toList(),
    if (itemAssignments != null)
      'itemAssignments': itemAssignments!.map((a) => a.toJson()).toList(),
  };
}
