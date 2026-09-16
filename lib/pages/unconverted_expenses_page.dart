import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/expense_form_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/utils/money_format.dart';

/// Wydatki czekające na kurs wymiany.
///
/// Powstały, zanim aplikacja przeliczała waluty, więc kurs ich zakupu nie jest
/// nigdzie zapisany — a zgadnięcie go wpisałoby do sald cudzą kwotę. Backend
/// trzyma je jako nieprzeliczone (kurs NULL) i pomija w saldach; ten ekran
/// pokazuje, których wydatków to dotyczy, i prowadzi wprost do formularza,
/// gdzie użytkownik podaje kurs — jedyne miejsce, z którego może pochodzić.
class UnconvertedExpensesPage extends StatefulWidget {
  final bool isDark;

  const UnconvertedExpensesPage({super.key, required this.isDark});

  @override
  State<UnconvertedExpensesPage> createState() =>
      _UnconvertedExpensesPageState();
}

class _UnconvertedExpensesPageState extends State<UnconvertedExpensesPage> {
  final _repository = ExpenseRepository();
  List<SingleExpense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _repository.fetchUnconvertedExpenses();
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _loading = false;
    });
  }

  Future<void> _fix(SingleExpense expense) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(isDark: widget.isDark, editExpense: expense),
      ),
    );
    // Po zapisaniu kursu wydatek znika z tej listy — przeładowujemy, żeby było
    // widać, ile jeszcze zostało.
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(widget.isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          texts.needsRatePageTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(widget.isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _buildList(texts)),
      ),
    );
  }

  Widget _buildList(AppTexts texts) {
    if (_expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: AppColors.cardSubtitle(widget.isDark),
          ),
          const SizedBox(height: 12),
          Text(
            texts.needsRateAllDone,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cardSubtitle(widget.isDark)),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          texts.needsRateExplainer,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.cardSubtitle(widget.isDark),
          ),
        ),
        const SizedBox(height: 16),
        for (final expense in _expenses) ...[
          _UnconvertedTile(
            expense: expense,
            isDark: widget.isDark,
            onTap: () => _fix(expense),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _UnconvertedTile extends StatelessWidget {
  final SingleExpense expense;
  final bool isDark;
  final VoidCallback onTap;

  const _UnconvertedTile({
    required this.expense,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(isDark)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.of(context).expenseName(expense.name),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardTitle(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.date.day}.${expense.date.month}.${expense.date.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.cardSubtitle(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(
                double.tryParse(expense.totalAmount) ?? 0,
                expense.currency,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.cardAmount(isDark),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.cardSubtitle(isDark),
            ),
          ],
        ),
      ),
    );
  }
}
