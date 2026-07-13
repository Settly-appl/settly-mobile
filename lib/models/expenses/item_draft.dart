class ItemDraft {
  final String id;
  String name;
  double price;
  final Set<String> assigneeIds;

  /// Ceny własne za ten produkt: userId -> kwota.
  ///
  /// Pusta mapa = dzielimy produkt po równo między przypisane osoby (backend
  /// robi zaokrąglenie, więc części zawsze sumują się do ceny produktu).
  /// Niepusta = każdy płaci swoją kwotę ("ty wziąłeś stek, ja sałatkę");
  /// muszą wtedy pokrywać wszystkich przypisanych i sumować się do [price].
  final Map<String, double> customShares;

  ItemDraft({
    required this.id,
    this.name = '',
    this.price = 0.0,
    Set<String>? assigneeIds,
    Map<String, double>? customShares,
  }) : assigneeIds = assigneeIds ?? <String>{},
       customShares = customShares ?? <String, double>{};

  bool get hasCustomShares => customShares.isNotEmpty;

  /// Suma cen własnych (0, gdy dzielimy po równo).
  double get customSharesTotal =>
      customShares.values.fold(0.0, (sum, v) => sum + v);

  /// Równa część na osobę — używana do wypełnienia pól przy włączeniu cen własnych.
  double get equalShare =>
      assigneeIds.isEmpty ? 0.0 : price / assigneeIds.length;
}
