import 'package:flutter/material.dart';
import 'package:settly_mobile/pages/balances_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/balances_service.dart';
import 'package:intl/intl.dart';

import '../../../const/app_texts.dart';

class SummaryCard extends StatefulWidget {
  const SummaryCard({super.key});

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  final _service = BalancesService();
  bool _loading = true;
  double _owedToYou = 0;
  double _youOwe = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final balances = await _service.getBalances();
      if (!mounted) return;
      setState(() {
        _owedToYou = balances
            .where((b) => b.owesYou)
            .fold(0.0, (s, b) => s + b.absAmount);
        _youOwe = balances
            .where((b) => b.youOwe)
            .fold(0.0, (s, b) => s + b.absAmount);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(double v) => '${v.toStringAsFixed(2)} zł';

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final String formattedDate = DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).languageCode,
    ).format(DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BalancesPage()));
        _load();
      },
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${texts.summaryCardTitle} $formattedDate',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.summaryTitle,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.summaryTitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: texts.balancesOwedToYou,
                    amount: _loading ? '—' : _money(_owedToYou),
                    subtitle: texts.balancesOtherOwes,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryTile(
                    label: texts.balancesYouOwe,
                    amount: _loading ? '—' : _money(_youOwe),
                    subtitle: texts.balancesYouOweOthers,
                  ),
                ),
              ],
            ),
          ],
        ),
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
