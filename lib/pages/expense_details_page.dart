import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settly_mobile/models/single_expense.dart';
import 'package:settly_mobile/models/enums/expense_splits_type.dart';
import 'package:settly_mobile/models/expense_member_item.dart';
import 'package:settly_mobile/models/expens_style.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import '../models/expense_member.dart';
import '../services/api_service/api_service_request.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final SingleExpense expense;
  const ExpenseDetailsPage({super.key, required this.expense});

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  bool _loading = true;
  String _splitLabel = '';
  ExpenseSplitsType _splitType = ExpenseSplitsType.EQUAL;
  List<ExpenseMember> _members = [];
  final ApiServiceRequest _api = ApiServiceRequest();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void didUpdateWidget(ExpenseDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expense.id != widget.expense.id) {
      _loading = true;
      _members = [];
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final expenseId = widget.expense.id;
    if (expenseId == null) {
      _finishLoading();
      return;
    }

    try {
      final splitMembers = await _fetchSplitMembers(expenseId);
      if (splitMembers.isEmpty) {
        _finishLoading();
        return;
      }

      final membersWithNames = await _enrichMembersWithNames(splitMembers);
      if (membersWithNames.isEmpty) {
        _finishLoading();
        return;
      }

      _splitType = ExpenseSplitsType.fromString(
        membersWithNames.first.splitType,
      );
      _splitLabel = _splitType.label;

      if (_splitType != ExpenseSplitsType.BY_ITEM) {
        _members = membersWithNames;
        _finishLoading();
        return;
      }

      final productsByUser = await _loadByItemProducts(expenseId);
      _members = membersWithNames
          .map(
            (member) => member.copyWith(
              items: productsByUser[member.userId] ?? const [],
            ),
          )
          .toList();
    } catch (_) {}
    _finishLoading();
  }

  Future<List<ExpenseMember>> _fetchSplitMembers(String expenseId) async {
    final res = await _api.request(
      endpoint: 'expenses/$expenseId/splits',
      method: HttpMethod.get,
    );
    if (res?.statusCode != 200) return const [];
    return ExpenseMember.listFromJson(jsonDecode(res!.body));
  }

  Future<List<ExpenseMember>> _enrichMembersWithNames(
    List<ExpenseMember> members,
  ) {
    return Future.wait(
      members.map((m) async {
        final displayName = await _fetchUserDisplayName(m.userId);
        return m.copyWith(displayName: displayName);
      }),
    );
  }

  Future<String> _fetchUserDisplayName(String userId) async {
    final res = await _api.request(
      endpoint: 'users/$userId',
      method: HttpMethod.get,
    );
    if (res?.statusCode != 200) return 'Nieznany';
    return jsonDecode(res!.body)['displayName']?.toString() ?? 'Nieznany';
  }

  void _finishLoading() {
    if (mounted) setState(() => _loading = false);
  }

  Future<Map<String, List<ExpenseMemberItem>>> _loadByItemProducts(
    String expenseId,
  ) async {
    try {
      final itemsRes = await _api.request(
        endpoint: 'expenses/$expenseId/items',
        method: HttpMethod.get,
      );
      if (itemsRes?.statusCode != 200) return const {};

      final items = _extractList(jsonDecode(itemsRes!.body));
      final productsByUser = <String, List<ExpenseMemberItem>>{};

      final rowsByItemId = _groupItemRowsByItemId(items);
      for (final entry in rowsByItemId.entries) {
        await _appendByItemShares(
          itemId: entry.key,
          rows: entry.value,
          productsByUser: productsByUser,
        );
      }

      return productsByUser;
    } catch (_) {
      return const {};
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupItemRowsByItemId(
    List<dynamic> items,
  ) {
    final groupedByItemId = <String, List<Map<String, dynamic>>>{};
    for (final raw in items.whereType<Map<String, dynamic>>()) {
      final itemId = _readItemId(raw);
      if (itemId == null) continue;
      groupedByItemId
          .putIfAbsent(itemId, () => <Map<String, dynamic>>[])
          .add(raw);
    }
    return groupedByItemId;
  }

  Future<void> _appendByItemShares({
    required String itemId,
    required List<Map<String, dynamic>> rows,
    required Map<String, List<ExpenseMemberItem>> productsByUser,
  }) async {
    if (rows.isEmpty) return;

    final usersRes = await _api.request(
      endpoint: 'expenses/items/$itemId/users',
      method: HttpMethod.get,
    );
    if (usersRes?.statusCode != 200) return;

    final users = _extractList(jsonDecode(usersRes!.body));
    if (users.isEmpty) return;

    final assignedUserIds = _extractAssignedUserIds(users);
    if (assignedUserIds.isEmpty) return;

    final amountByUserId = _buildAmountByUserId(rows);
    final totalAmount = _readItemAmount(rows.first);
    final totalAmountValue = _tryParseAmount(totalAmount);
    final hasCompleteUserAmounts = _hasCompleteUserAmounts(
      assignedUserIds,
      amountByUserId,
    );
    final equalShareAmount =
        (!hasCompleteUserAmounts && totalAmountValue != null)
        ? _formatAmount(totalAmountValue / assignedUserIds.length)
        : null;

    final itemName = _readItemName(rows.first, fallbackItemId: itemId);
    for (final userId in assignedUserIds) {
      final userAmount = hasCompleteUserAmounts
          ? amountByUserId[userId]!
          : (equalShareAmount ?? amountByUserId[userId] ?? totalAmount);

      productsByUser
          .putIfAbsent(userId, () => <ExpenseMemberItem>[])
          .add(ExpenseMemberItem(name: itemName, amount: userAmount));
    }
  }

  Set<String> _extractAssignedUserIds(List<dynamic> users) {
    final ids = <String>{};
    for (final user in users.whereType<Map<String, dynamic>>()) {
      final id = _readUserId(user);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  Map<String, String> _buildAmountByUserId(List<Map<String, dynamic>> rows) {
    final result = <String, String>{};
    for (final row in rows) {
      final userId = _readUserId(row);
      if (userId == null) continue;
      result[userId] = _readItemAmount(row);
    }
    return result;
  }

  bool _hasCompleteUserAmounts(
    Set<String> assignedUserIds,
    Map<String, String> amountByUserId,
  ) {
    return assignedUserIds.every(
      (id) => _tryParseAmount(amountByUserId[id]) != null,
    );
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map<String, dynamic>) return const [];

    const keys = ['data', 'content', 'items', 'results'];
    for (final key in keys) {
      final candidate = body[key];
      if (candidate is List) return candidate;
    }
    return const [];
  }

  String? _readItemId(Map<String, dynamic> item) {
    final id = item['id'] ?? item['itemId'] ?? item['expenseItemId'];
    final value = id?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String _readItemName(Map<String, dynamic> item, {String? fallbackItemId}) {
    final name = item['name'] ?? item['itemName'] ?? item['productName'];
    final value = name?.toString();
    if (value == null || value.isEmpty) {
      final shortId = (fallbackItemId != null && fallbackItemId.length >= 6)
          ? fallbackItemId.substring(0, 6)
          : fallbackItemId;
      return shortId == null ? 'Pozycja' : 'Pozycja $shortId';
    }
    return value;
  }

  String _readItemAmount(Map<String, dynamic> item) {
    final amount = item['amount'] ?? item['price'] ?? item['totalPrice'];
    final value = amount?.toString();
    if (value == null || value.isEmpty) return '0.00';
    return value;
  }

  String? _readUserId(Map<String, dynamic> user) {
    final id = user['userId'] ?? user['id'] ?? user['friendId'];
    final value = id?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  double? _tryParseAmount(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = widget.expense.style(isDark);

    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Szczegóły"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(style, isDark),
            const SizedBox(height: 32),
            _infoRow('Kategoria', widget.expense.category, isDark),
            _infoRow(
              'Data',
              widget.expense.date.toString().split(' ')[0],
              isDark,
            ),
            if (widget.expense.note.isNotEmpty)
              _infoRow('Notatka', widget.expense.note, isDark),
            const Divider(height: 40),
            _buildSplitSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ExpenseStyle style, bool isDark) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: style.iconBg, shape: BoxShape.circle),
        child: Icon(style.icon, size: 40, color: style.iconColor),
      ),
      const SizedBox(height: 16),
      Text(
        '${widget.expense.totalAmount} ${widget.expense.currency}',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.cardAmount(isDark),
        ),
      ),
      Text(
        widget.expense.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    ],
  );

  Widget _buildSplitSection(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isByItem = _splitType == ExpenseSplitsType.BY_ITEM;
    final hasAnyProducts = _members.any((m) => m.items.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PODZIAŁ: $_splitLabel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.cardSubtitle(isDark),
          ),
        ),
        const SizedBox(height: 12),
        ..._members.map((m) => _buildMemberTile(m, isDark, isByItem)),
        if (isByItem && !hasAnyProducts)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Brak danych o produktach dla tego podzialu.',
              style: TextStyle(color: AppColors.cardSubtitle(isDark)),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberTile(ExpenseMember m, bool isDark, bool isByItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(
              m.displayName.isEmpty ? '?' : m.displayName[0].toUpperCase(),
            ),
          ),
          title: Text(m.displayName),
          trailing: Text(
            '${m.amount} ${widget.expense.currency}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (isByItem && m.items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: m.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: AppColors.cardSubtitle(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item.amount} ${widget.expense.currency}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.cardSubtitle(isDark))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
