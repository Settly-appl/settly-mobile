class ItemDraft {
  final String id;
  String name;
  double price;
  final Set<String> assigneeIds;

  ItemDraft({
    required this.id,
    this.name = '',
    this.price = 0.0,
    Set<String>? assigneeIds,
  }) : assigneeIds = assigneeIds ?? <String>{};
}
