class UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
