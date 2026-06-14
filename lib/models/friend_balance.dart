class FriendBalance {
  final String userId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  /// Positive: this friend owes the current user. Negative: the user owes them.
  final double netAmount;

  const FriendBalance({
    required this.userId,
    this.displayName,
    this.username,
    this.avatarUrl,
    required this.netAmount,
  });

  factory FriendBalance.fromJson(Map<String, dynamic> json) {
    return FriendBalance(
      userId: json['userId'].toString(),
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<FriendBalance> listFromJson(List<dynamic> json) {
    return json
        .map((e) => FriendBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The friend owes the current user money.
  bool get owesYou => netAmount > 0;

  /// The current user owes this friend money.
  bool get youOwe => netAmount < 0;

  double get absAmount => netAmount.abs();

  /// Display name with sensible fallbacks.
  String get label {
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final un = username?.trim();
    if (un != null && un.isNotEmpty) return un;
    return 'Znajomy';
  }

  String get initials {
    final source = label.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }
}
