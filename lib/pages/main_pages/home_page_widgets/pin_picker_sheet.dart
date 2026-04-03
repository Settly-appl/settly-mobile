import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/pinned_item.dart';
import 'package:settly_mobile/models/recent_expense.dart';
import 'package:settly_mobile/models/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
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
  List<RecentExpense> _expenses = [];
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
    final pinned = await _repo.getAll();
    if (!mounted) return;
    setState(() => _pinnedIds = pinned.map((e) => e.id).toSet());
  }

  Future<void> _fetchExpenses() async {
    setState(() => _loadingExpenses = true);
    final response = await ApiServiceRequest().request(
      endpoint: 'expenses?page=0&size=30&sort=createdAt,desc',
      method: HttpMethod.get,
    );
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fetched = SingleExpense.listFromJson(
        data['content'],
        widget.isDark,
      );
      if (mounted) setState(() => _expenses = fetched);
    }
    if (mounted) setState(() => _loadingExpenses = false);
  }

  // ── Przypinanie wydatku ────────────────────────────────────────────────────
  Future<void> _pinExpense(RecentExpense expense, String expenseId) async {
    final item = PinnedItem.fromExpense(
      id: expenseId,
      name: expense.name,
      subtitle: expense.subtitle,
      amount: expense.totalAmount,
      currency: expense.currency,
      icon: expense.icon,
      iconBg: expense.iconBg,
      iconColor: expense.iconColor,
    );

    final success = await _repo.pin(item);

    if (!mounted) return;

    if (success) {
      setState(() => _pinnedIds.add(expenseId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Przypięto: ${expense.name}'),
          backgroundColor: AppColors.actionScanIcon(widget.isDark),
          duration: const Duration(seconds: 2),
        ),
      );
      await widget.onPinned();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Osiągnięto limit przypiętych elementów (maks. ${PinnedRepository.maxPinned})',
          ),
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
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.scaffold(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Uchwyt ──────────────────────────────────────────────────────────
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

          // ── Nagłówek ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Co chcesz przypiąć?',
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
              'Wybierz wydatek lub projekt do sekcji Przypiętych',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cardSubtitle(isDark),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── TabBar ──────────────────────────────────────────────────────────
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
                tabs: const [
                  Tab(text: 'Wydatki'),
                  Tab(text: 'Projekty'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── TabBarView ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(),
                _buildProjectsTab(), // "otwarta furtka"
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Zakładka: Wydatki ──────────────────────────────────────────────────────
  Widget _buildExpensesTab() {
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
              'Brak wydatków',
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
        // Uwaga: RecentExpense nie ma id z backendu — tu używamy name+date jako klucz
        // Docelowo przekazuj id z JSON. Jeśli dodasz `id` do RecentExpense/SingleExpense,
        // podmień poniższe na expense.id.
        final tempId =
            '${expense.name}_${expense.createdAt.millisecondsSinceEpoch}';
        final isPinned = _pinnedIds.contains(tempId);

        return _ExpensePickerRow(
          expense: expense,
          isDark: widget.isDark,
          isPinned: isPinned,
          onTap: () =>
              isPinned ? _unpinById(tempId) : _pinExpense(expense, tempId),
        );
      },
    );
  }

  // ── Zakładka: Projekty (otwarta furtka) ───────────────────────────────────
  //
  // Gdy zostanie zaimplementowana funkcjonalność projektów:
  // 1. Podmień placeholder na listę projektów z API
  // 2. Wywołaj _pinProject(project) analogicznie do _pinExpense
  // 3. W PinnedItem.fromProject uzupełnij faktyczne dane projektu
  //
  Widget _buildProjectsTab() {
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
              color: AppColors.cardSubtitle(widget.isDark).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Projekty wkrótce',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(widget.isDark),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Gdy funkcjonalność projektów zostanie dodana, będziesz mógł tu przypiąć swoje projekty grupowe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cardSubtitle(widget.isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Wiersz wydatku z przyciskiem "przypnij / odepnij"
// ════════════════════════════════════════════════════════════════════════════
class _ExpensePickerRow extends StatelessWidget {
  final RecentExpense expense;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPinned
              ? AppColors.actionScanIcon(isDark).withOpacity(0.5)
              : AppColors.cardBorder(isDark),
          width: isPinned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Ikona kategorii
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: expense.iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(expense.icon, size: 17, color: expense.iconColor),
          ),
          const SizedBox(width: 10),

          // Nazwa + notatka
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
                if (expense.subtitle.isNotEmpty)
                  Text(
                    expense.subtitle,
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

          // Kwota
          Text(
            '${expense.totalAmount} ${expense.currency}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cardAmount(isDark),
            ),
          ),
          const SizedBox(width: 10),

          // Przycisk pin/unpin
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
