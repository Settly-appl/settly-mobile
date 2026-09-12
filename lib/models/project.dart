import '../utils/money_format.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final String? ownerId;
  final String status; // ACTIVE | SETTLED
  final int memberCount;

  /// Ile wydatków należy do projektu i na jaką łączną kwotę — backend liczy to
  /// jednym zapytaniem, więc lista projektów może to pokazać bez dopytywania.
  final int expenseCount;
  final double totalAmount;

  /// Waluta, w której podana jest [totalAmount] — waluta bazowa oglądającego.
  /// Wyjazd opłacony częściowo w funtach, a częściowo w złotówkach nie ma
  /// jednej waluty własnej, więc suma musi nieść swoją walutę ze sobą.
  final String totalCurrency;

  /// Waluta wyjazdu i kurs, po którym uczestnicy ją kupili. Nowe wydatki w
  /// projekcie dziedziczą oba, więc kurs wpisuje się raz na wyjazd, a nie raz
  /// na wydatek.
  final String? defaultCurrency;
  final double? defaultRateToBase;

  final DateTime? createdAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.ownerId,
    required this.status,
    required this.memberCount,
    this.expenseCount = 0,
    this.totalAmount = 0,
    this.totalCurrency = kDefaultCurrency,
    this.defaultCurrency,
    this.defaultRateToBase,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String?,
      status: json['status']?.toString() ?? 'ACTIVE',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      totalCurrency: json['totalCurrency']?.toString() ?? kDefaultCurrency,
      defaultCurrency: json['defaultCurrency'] as String?,
      defaultRateToBase: (json['defaultRateToBase'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString())?.toLocal(),
    );
  }

  static List<Project> listFromJson(List<dynamic> json) {
    return json
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  bool get isSettled => status == 'SETTLED';
}

class ProjectMember {
  final String userId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final bool owner;

  const ProjectMember({
    required this.userId,
    this.displayName,
    this.username,
    this.avatarUrl,
    required this.owner,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['userId'].toString(),
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      owner: json['owner'] == true,
    );
  }

  static List<ProjectMember> listFromJson(List<dynamic> json) {
    return json
        .map((e) => ProjectMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String get label {
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final un = username?.trim();
    if (un != null && un.isNotEmpty) return un;
    return 'Uczestnik';
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
