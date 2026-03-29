import 'package:flutter/material.dart';
import 'package:settly_mobile/models/recent_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class RecentExpenseCard extends StatelessWidget {
  final RecentExpense item;
  final bool isDark;

  const RecentExpenseCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      child: Row(
        children: [
          _iconBox(),
          const SizedBox(width: 10),
          Expanded(child: _nameAndSubtitle()),
          _amountAndBadge(),
        ],
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: item.iconBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(item.icon, size: 16, color: item.iconColor),
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
          item.subtitle,
          style: TextStyle(fontSize: 11, color: AppColors.cardSubtitle(isDark)),
        ),
      ],
    );
  }

  Widget _amountAndBadge() {
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
            color: item.badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.type,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: item.badgeFg,
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
