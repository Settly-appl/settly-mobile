import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

/// Znacznik rozliczenia na kafelku wydatku: "Rozliczone" albo "2/3 rozliczone".
/// Wydatki osobiste (bez podziału) nie mają nic do rozliczenia — nic nie pokazujemy.
class SettledBadge extends StatelessWidget {
  final SingleExpense item;
  final bool isDark;

  const SettledBadge({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!item.isShared) return const SizedBox.shrink();

    final settled = item.settled;
    final partial = item.isPartiallySettled;
    if (!settled && !partial) return const SizedBox.shrink();

    final texts = AppTexts.of(context);
    final color = settled
        ? AppColors.amountPositive
        : AppColors.cardSubtitle(isDark);
    final label = settled
        ? texts.expenseSettledBadge
        : texts.settledOfCount(item.settledCount, item.splitCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          settled ? Icons.check_circle_rounded : Icons.timelapse_rounded,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Przesuń w prawo, żeby rozliczyć; w lewo, żeby cofnąć rozliczenie.
///
/// Kafelek nigdy nie znika z listy — `confirmDismiss` zawsze zwraca `false`,
/// więc gest służy tylko jako akcja. Wydatki bez podziału nie są przesuwalne.
class SettleSwipe extends StatelessWidget {
  final SingleExpense item;
  final bool isDark;
  final Future<void> Function(bool settled) onSetSettled;
  final Widget child;

  const SettleSwipe({
    super.key,
    required this.item,
    required this.isDark,
    required this.onSetSettled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!item.isShared) return child; // nie ma czego rozliczać

    final texts = AppTexts.of(context);

    return Dismissible(
      key: ValueKey('settle_${item.id}'),
      direction: DismissDirection.horizontal,
      background: _background(
        color: AppColors.amountPositive,
        icon: Icons.check_circle_rounded,
        label: texts.settleAction,
        toRight: true,
      ),
      secondaryBackground: _background(
        color: AppColors.amountNegative,
        icon: Icons.undo_rounded,
        label: texts.unsettleAction,
        toRight: false,
      ),
      confirmDismiss: (direction) async {
        await onSetSettled(direction == DismissDirection.startToEnd);
        return false; // gest to akcja, nie usunięcie
      },
      child: child,
    );
  }

  Widget _background({
    required Color color,
    required IconData icon,
    required String label,
    required bool toRight,
  }) {
    final text = Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
    final glyph = Icon(icon, color: color, size: 18);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: toRight ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: toRight
            ? [glyph, const SizedBox(width: 6), text]
            : [text, const SizedBox(width: 6), glyph],
      ),
    );
  }
}
