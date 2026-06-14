enum ExpenseSplitsType {
  EQUAL('Równomiernie'),
  BY_ITEM('Według produktów'),
  CUSTOM('Niestandardowy');

  final String label;
  const ExpenseSplitsType(this.label);

  static ExpenseSplitsType fromString(String value) {
    return ExpenseSplitsType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ExpenseSplitsType.EQUAL,
    );
  }
}
