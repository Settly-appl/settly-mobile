class Suggestion {
  final String id;
  final String content;

  /// Nazwa autora do wyświetlenia. `null`, gdy konto zostało usunięte — sama
  /// sugestia zostaje, bo nadal warto ją przeczytać.
  final String? authorName;

  final DateTime? createdAt;

  const Suggestion({
    required this.id,
    required this.content,
    this.authorName,
    this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'].toString(),
      content: json['content']?.toString() ?? '',
      authorName: json['authorName'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString())?.toLocal(),
    );
  }

  static List<Suggestion> listFromJson(List<dynamic> json) {
    return json
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
