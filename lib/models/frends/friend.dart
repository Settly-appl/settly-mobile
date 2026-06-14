class Friend {
  final String friendshipId;
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const Friend({
    required this.friendshipId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Friend(
      friendshipId: json['friendshipId'] as String,
      userId: user['id'] as String,
      displayName: (user['displayName'] as String?) ?? '',
      avatarUrl: user['avatarUrl'] as String?,
    );
  }
}
