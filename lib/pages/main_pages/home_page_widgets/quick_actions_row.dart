import 'package:flutter/material.dart';
import 'package:settly_mobile/models/recent_expense.dart';
import 'package:settly_mobile/pages/quick_add_menu.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class QuickActionsRow extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onExpenseAdded;

  const QuickActionsRow({
    super.key,
    required this.isDark,
    required this.onExpenseAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Dodaj',
              icon: Icons.add,
              iconColor: AppColors.actionAddIcon(isDark),
              iconBg: AppColors.actionAddIconBg(isDark),
              isDark: isDark,
              onTap: () async {
                await showModalBottomSheet<RecentExpense>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      QuickAddMenu(isDark: isDark, onSaved: onExpenseAdded),
                );
                // if (result != null) {
                //   onExpenseAdded(result);
                // }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Skanuj',
              icon: Icons.camera_alt_outlined,
              iconColor: AppColors.actionScanIcon(isDark),
              iconBg: AppColors.actionScanIconBg(isDark),
              isDark: isDark,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Projekt',
              icon: Icons.group_outlined,
              iconColor: AppColors.actionProjectIcon(isDark),
              iconBg: AppColors.actionProjectIconBg(isDark),
              isDark: isDark,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Rozlicz',
              icon: Icons.check_box_outlined,
              iconColor: AppColors.actionSettleIcon(isDark),
              iconBg: AppColors.actionSettleIconBg(isDark),
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Funkcja Skanowania będzie dostępna wkrótce!',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.actionBtnBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.actionBtnBorder(isDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.actionBtnLabel(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
