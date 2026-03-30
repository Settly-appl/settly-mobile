import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String formattedDate = DateFormat(
      'MMMM yyyy',
      'pl',
    ).format(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.summaryGradientLeft,
            AppColors.summaryGradientRight,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie — $formattedDate',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.summaryTitle,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Należności',
                  amount: '210 zł',
                  subtitle: 'inni Tobie',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Zobowiązania',
                  amount: '85 zł',
                  subtitle: 'Ty innym',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.summaryTileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.summaryTileLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.summaryTileValue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.summaryTileSub,
            ),
          ),
        ],
      ),
    );
  }
}
