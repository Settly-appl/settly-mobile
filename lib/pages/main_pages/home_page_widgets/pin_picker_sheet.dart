import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import '../../../const/app_texts.dart';
import '../../../repository/pinned_item_repository.dart';

class PinPickerSheet extends StatefulWidget {
  final bool isDark;

  /// Callback wywoływany po pomyślnym przypięciu.
  final Future<void> Function() onPinned;

  const PinPickerSheet({
    super.key,
    required this.isDark,
    required this.onPinned,
  });

  @override
  State<PinPickerSheet> createState() => _PinPickerSheetState();
}

class _PinPickerSheetState extends State<PinPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = PinnedRepository();

  // ── Stan zakładki Wydatki ──────────────────────────────────────────────────
  List<SingleExpense> _expenses = [];
  bool _loadingExpenses = true;

  // ── Śledzenie już przypiętych id ──────────────────────────────────────────
  Set<String> _pinnedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExpenses();
    _loadPinnedIds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPinnedIds() async {
    final pinned = await _repo.getPinnedIds();
    if (!mounted) return;
    setState(() => _pinnedIds = pinned.toSet());
  }

  Future<void> _fetchExpenses() async {
    setState(() => _loadingExpenses = true);
    final response = await ApiServiceRequest().request(
      endpoint: 'expenses?page=0&size=30&sort=createdAt,desc',
      method: HttpMethod.get,
    );
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fetched = SingleExpense.listFromJson(data['content']);
      if (mounted) setState(() => _expenses = fetched);
    }
    if (mounted) setState(() => _loadingExpenses = false);
  }

  // ── Przypinanie wydatku ────────────────────────────────────────────────────
  Future<void> _pinExpense(String expenseId, String name) async {
    final texts = AppTexts.of(context);
    final success = await _repo.pin(expenseId);

    if (!mounted) return;

    if (success) {
      setState(() => _pinnedIds.add(expenseId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${texts.pinnedPrefix}: $name'),
          backgroundColor: AppColors.actionScanIcon(widget.isDark),
          duration: const Duration(seconds: 2),
        ),
      );
      await widget.onPinned();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texts.pinnedLimitReached(PinnedRepository.maxPinned)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Odpinanie ─────────────────────────────────────────────────────────────
  Future<void> _unpinById(String id) async {
    await _repo.unpin(id);
    if (!mounted) return;
    setState(() => _pinnedIds.remove(id));
    await widget.onPinned();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final texts = AppTexts.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.scaffold(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texts.pinPickerTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.username(isDark),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              texts.pinPickerSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cardSubtitle(isDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardBg(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder(isDark)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.actionScanIcon(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.cardSubtitle(isDark),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: texts.expensesTab),
                  Tab(text: texts.projectsTitle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildExpensesTab(), _buildProjectsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Zakładka: Wydatki ──────────────────────────────────────────────────────
  Widget _buildExpensesTab() {
    final texts = AppTexts.of(context);
    if (_loadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.cardSubtitle(widget.isDark).withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              texts.noExpenses,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cardSubtitle(widget.isDark),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        final expenseId = expense.id ?? '';
        if (expenseId.isEmpty) return const SizedBox.shrink();

        final isPinned = _pinnedIds.contains(expenseId);

        return _ExpensePickerRow(
          expense: expense,
          isDark: widget.isDark,
          isPinned: isPinned,
          onTap: () => isPinned
              ? _unpinById(expenseId)
              : _pinExpense(expenseId, expense.name),
        );
      },
    );
  }

  Widget _buildProjectsTab() {
    final texts = AppTexts.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.cardBg(widget.isDark),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder(widget.isDark)),
            ),
            child: Icon(
              Icons.group_outlined,
              size: 36,
              color: AppColors.cardSubtitle(
                widget.isDark,
              ).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            texts.comingSoon,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(widget.isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensePickerRow extends StatelessWidget {
  final SingleExpense expense;
  final bool isDark;
  final bool isPinned;
  final VoidCallback onTap;

  const _ExpensePickerRow({
    required this.expense,
    required this.isDark,
    required this.isPinned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = expense.style(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPinned
              ? AppColors.actionScanIcon(isDark).withValues(alpha: 0.5)
              : AppColors.cardBorder(isDark),
          width: isPinned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(style.icon, size: 17, color: style.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cardTitle(isDark),
                  ),
                ),
                if (expense.note.isNotEmpty)
                  Text(
                    expense.note,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.cardSubtitle(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${expense.totalAmount} ${expense.currency}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cardAmount(isDark),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPinned
                    ? AppColors.actionScanIcon(isDark)
                    : AppColors.cardBg(isDark),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPinned
                      ? AppColors.actionScanIcon(isDark)
                      : AppColors.cardBorder(isDark),
                ),
              ),
              child: Icon(
                isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 15,
                color: isPinned ? Colors.white : AppColors.cardSubtitle(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
