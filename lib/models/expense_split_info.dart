class ExpenseSplitInfo {
  final String userId;
  final String? userDisplayName;
  final String? userName;
  final String splitType;
  final double amount;
  final bool settled;

  const ExpenseSplitInfo({
    required this.userId,
    this.userDisplayName,
    this.userName,
    required this.splitType,
    required this.amount,
    required this.settled,
  });

  factory ExpenseSplitInfo.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitInfo(
      userId: json['userId'].toString(),
      userDisplayName: json['userDisplayName'] as String?,
      userName: json['userName'] as String?,
      splitType: json['splitType']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      settled: json['settled'] == true,
    );
  }

  /// Display name with sensible fallbacks.
  String get label {
    final dn = userDisplayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final un = userName?.trim();
    if (un != null && un.isNotEmpty) return un;
    return 'Uczestnik';
  }

  static List<ExpenseSplitInfo> listFromJson(List<dynamic> json) {
    return json
        .map((e) => ExpenseSplitInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
