class FriendshipRequest {
  final String friendshipId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const FriendshipRequest({
    required this.friendshipId,
    required this.userId,
    required this.displayName,
    required this.createdAt,
    this.avatarUrl,
  });

  factory FriendshipRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return FriendshipRequest(
      friendshipId: json['friendshipId'] as String,
      userId: user['id'] as String,
      displayName: (user['displayName'] as String?) ?? '',
      avatarUrl: user['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
