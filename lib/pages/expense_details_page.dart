import 'package:flutter/material.dart';
import 'package:settly_mobile/models/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class ExpenseDetailsPage extends StatelessWidget {
  final SingleExpense expense;

  const ExpenseDetailsPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final style = expense.style(isDark);

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
                '${expense.totalAmount} ${expense.currency}',
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
                expense.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardTitle(isDark),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailRow(context, 'Kategoria', expense.category, isDark),
            _buildDetailRow(
              context,
              'Data',
              expense.date.toString().split(' ')[0],
              isDark,
            ),
            if (expense.note.isNotEmpty)
              _buildDetailRow(context, 'Notatka', expense.note, isDark),
            if (expense.projectId != null)
              //TODO poprawne wyswietlanie projektu
              _buildDetailRow(context, 'Projekt', expense.projectId!, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cardSubtitle(isDark),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.cardTitle(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
