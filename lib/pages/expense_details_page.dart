import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/expense_split_info.dart';
import 'package:settly_mobile/models/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/auth_service.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final SingleExpense expense;

  const ExpenseDetailsPage({super.key, required this.expense});

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  final _api = ApiServiceRequest();

  bool _loadingSplit = true;
  double? _shareAmount;
  String? _shareCurrency;
  List<ExpenseSplitInfo> _splits = [];
  List<_OwedItem> _myItems = [];
  String? _currentUserId;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSplitDetails();
  }

  Future<void> _loadSplitDetails() async {
    final id = widget.expense.id;
    if (id == null) {
      setState(() => _loadingSplit = false);
      return;
    }

    final userInfo = await AuthService().getUserInfo();
    _currentUserId = userInfo?['sub'] as String?;

    final results = await Future.wait([
      _api.request(endpoint: 'expenses/$id/userShare', method: HttpMethod.get),
      _api.request(endpoint: 'expenses/$id/splits', method: HttpMethod.get),
    ]);
    if (!mounted) return;

    final shareRes = results[0];
    if (shareRes != null && shareRes.statusCode == 200) {
      final data = jsonDecode(shareRes.body) as Map<String, dynamic>;
      _shareAmount = (data['amount'] as num?)?.toDouble();
      _shareCurrency = data['currency'] as String?;
    }

    final splitsRes = results[1];
    if (splitsRes != null && splitsRes.statusCode == 200) {
      _splits = ExpenseSplitInfo.listFromJson(
        jsonDecode(splitsRes.body) as List<dynamic>,
      );
    }

    // For item splits, work out which items this user is responsible for.
    final isByItem = _splits.any((s) => s.splitType == 'BY_ITEM');
    if (isByItem && _currentUserId != null) {
      _myItems = await _loadMyItems(id);
    }

    if (mounted) setState(() => _loadingSplit = false);
  }

  Future<List<_OwedItem>> _loadMyItems(String expenseId) async {
    final itemsRes = await _api.request(
      endpoint: 'expenses/$expenseId/items',
      method: HttpMethod.get,
    );
    if (itemsRes == null || itemsRes.statusCode != 200) return [];

    final items = jsonDecode(itemsRes.body) as List<dynamic>;
    final owed = <_OwedItem>[];

    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final itemId = item['id']?.toString();
      if (itemId == null) continue;

      final usersRes = await _api.request(
        endpoint: 'expenses/items/$itemId/users',
        method: HttpMethod.get,
      );
      if (usersRes == null || usersRes.statusCode != 200) continue;

      final users = jsonDecode(usersRes.body) as List<dynamic>;
      final assignedToMe = users.any(
        (u) => (u as Map<String, dynamic>)['id']?.toString() == _currentUserId,
      );
      if (!assignedToMe || users.isEmpty) continue;

      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
      final share = (price * quantity) / users.length;
      owed.add(_OwedItem(name: item['name']?.toString() ?? 'Pozycja', share: share));
    }
    return owed;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.expense.style(isDark);

    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Szczegóły wydatku',
          style: TextStyle(color: AppColors.username(isDark)),
        ),
        iconTheme: IconThemeData(color: AppColors.username(isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: style.iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(style.icon, size: 40, color: style.iconColor),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '${widget.expense.totalAmount} ${widget.expense.currency}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cardAmount(isDark),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.expense.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardTitle(isDark),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_loadingSplit)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_shareAmount != null)
              _buildShareBanner(),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Kategoria', widget.expense.category),
            _buildDetailRow(
              context,
              'Data',
              widget.expense.date.toString().split(' ')[0],
            ),
            if (widget.expense.note.isNotEmpty)
              _buildDetailRow(context, 'Notatka', widget.expense.note),
            if (widget.expense.projectId != null)
              //TODO poprawne wyswietlanie projektu
              _buildDetailRow(context, 'Projekt', widget.expense.projectId!),
            if (_myItems.isNotEmpty) _buildItemsSection(),
            if (_splits.isNotEmpty) _buildSplitsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareBanner() {
    final cur = _shareCurrency ?? widget.expense.currency;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bellBg(isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Twoja część',
            style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle(isDark)),
          ),
          const SizedBox(height: 4),
          Text(
            '${_shareAmount!.toStringAsFixed(2)} $cur',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.cardAmount(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsSection() {
    final cur = _shareCurrency ?? widget.expense.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Podział',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.cardTitle(isDark),
          ),
        ),
        const SizedBox(height: 8),
        ..._splits.map((s) {
          final isMe = s.userId == _currentUserId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isMe ? 'Ty' : s.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                      color: AppColors.cardTitle(isDark),
                    ),
                  ),
                ),
                _settledChip(s.settled),
                const SizedBox(width: 12),
                Text(
                  '${s.amount.toStringAsFixed(2)} $cur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardAmount(isDark),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildItemsSection() {
    final cur = _shareCurrency ?? widget.expense.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Twoje pozycje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.cardTitle(isDark),
          ),
        ),
        const SizedBox(height: 8),
        ..._myItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.cardTitle(isDark),
                    ),
                  ),
                ),
                Text(
                  '${item.share.toStringAsFixed(2)} $cur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cardAmount(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _settledChip(bool settled) {
    final color = settled ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        settled ? 'Rozliczone' : 'Do zapłaty',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.cardSubtitle(isDark)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.cardTitle(isDark),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwedItem {
  final String name;
  final double share;

  const _OwedItem({required this.name, required this.share});
}
