import 'package:flutter/material.dart';
import 'package:settly_mobile/models/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class RecentExpenseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final style = item.style(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(isDark)),
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
          item.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.cardTitle(isDark),
          ),
        ),
        Text(
          item.note,
          style: TextStyle(fontSize: 11, color: AppColors.cardSubtitle(isDark)),
        ),
      ],
    );
  }

  Widget _amountAndBadge(dynamic style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          item.totalAmount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.cardAmount(isDark),
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
            item.category,
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
            'Brak wydatków',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.greeting(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Twoje ostatnie transakcje pojawią się tutaj.',
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
