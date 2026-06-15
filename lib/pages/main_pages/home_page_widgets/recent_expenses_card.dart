import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import '../../../const/app_texts.dart';
import '../../../models/expenses/single_expense.dart';

class RecentExpenseCard extends StatefulWidget {
  final SingleExpense item;
  final bool isDark;
  final VoidCallback? onTap;

  const RecentExpenseCard({
    super.key,
    required this.item,
    required this.isDark,
    this.onTap,
  });

  @override
  State<RecentExpenseCard> createState() => _RecentExpenseCardState();
}

class _RecentExpenseCardState extends State<RecentExpenseCard> {
  final _expenseRepository = ExpenseRepository();
  bool _loadingUserShare = false;

  @override
  void initState() {
    super.initState();
    _loadUserShare();
  }

  Future<void> _loadUserShare() async {
    // Jeśli userShare jest już załadowany, nie pobieraj ponownie
    if (widget.item.userShare.isNotEmpty) return;

    setState(() => _loadingUserShare = true);

    final userShare = await _expenseRepository.fetchUserShareForExpense(
      expenseId: widget.item.id ?? '',
      currency: widget.item.currency,
    );

    if (userShare != null && mounted) {
      setState(() {
        widget.item.userShare = userShare;
        _loadingUserShare = false;
      });
    } else if (mounted) {
      setState(() => _loadingUserShare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.item.style(widget.isDark);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cardBg(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(widget.isDark)),
        ),
        child: Row(
          children: [
            _iconBox(style),
            const SizedBox(width: 10),
            Expanded(child: _nameAndSubtitle()),
            _amountAndBadge(style),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(dynamic style) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: style.iconBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(style.icon, size: 16, color: style.iconColor),
    );
  }

  Widget _nameAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.cardTitle(widget.isDark),
          ),
        ),
        Text(
          widget.item.note,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.cardSubtitle(widget.isDark),
          ),
        ),
      ],
    );
  }

  Widget _amountAndBadge(dynamic style) {
    // Wyświetl userShare jeśli jest dostępny, w przeciwnym razie totalAmount
    final displayAmount = widget.item.userShare.isNotEmpty
        ? widget.item.userShare
        : widget.item.totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _loadingUserShare ? '...' : displayAmount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.cardAmount(widget.isDark),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: style.badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.item.category,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: style.badgeFg,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyRecentCard extends StatelessWidget {
  final bool isDark;

  const EmptyRecentCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.greeting(isDark).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            texts.noExpenses,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.greeting(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texts.recentExpensesEmptySubtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.greeting(isDark).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
