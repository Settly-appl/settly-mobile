import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

/// Znacznik rozliczenia na kafelku wydatku: "Rozliczone", "2/3 rozliczone",
/// a dla zgłoszeń zapłaty (deklaracja uczestnika czekająca na potwierdzenie
/// właściciela): "Zgłoszono zapłatę" (własna) albo "1 zgłoszenie" (cudze).
/// Wydatki osobiste (bez podziału) nie mają nic do rozliczenia — nic nie pokazujemy.
class SettledBadge extends StatelessWidget {
  final SingleExpense item;
  final bool isDark;

  const SettledBadge({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!item.isShared) return const SizedBox.shrink();

    final texts = AppTexts.of(context);
    final settled = item.settled;
    final partial = item.isPartiallySettled;

    final Color color;
    final IconData icon;
    final String label;
    if (settled) {
      color = AppColors.amountPositive;
      icon = Icons.check_circle_rounded;
      label = texts.expenseSettledBadge;
    } else if (item.declared) {
      // Własny udział: zgłoszono, czeka na potwierdzenie właściciela.
      color = Colors.blue;
      icon = Icons.hourglass_top_rounded;
      label = texts.expenseDeclaredBadge;
    } else if (item.declaredCount > 0) {
      // Ktoś twierdzi, że zapłacił — właściciel powinien to zweryfikować.
      color = Colors.blue;
      icon = Icons.mark_chat_read_rounded;
      label = partial
          ? '${texts.settledOfCount(item.settledCount, item.splitCount)} · '
                '${texts.declaredCountBadge(item.declaredCount)}'
          : texts.declaredCountBadge(item.declaredCount);
    } else if (partial) {
      color = AppColors.cardSubtitle(isDark);
      icon = Icons.timelapse_rounded;
      label = texts.settledOfCount(item.settledCount, item.splitCount);
    } else {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
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

/// Przesuń w prawo, żeby rozliczyć; w lewo, żeby cofnąć.
///
/// Znaczenie gestu zależy od tego, kim jest patrzący (patrz backend):
/// właściciel naprawdę rozlicza (potwierdza, że dostał pieniądze), uczestnik
/// jedynie ZGŁASZA zapłatę — sugestię, którą właściciel ma potwierdzić.
/// Etykiety gestu mówią to wprost, żeby uczestnik nie myślał, że rozlicza.
///
/// Kafelek nigdy nie znika z listy — `confirmDismiss` zawsze zwraca `false`,
/// więc gest służy tylko jako akcja. Wydatki bez podziału nie są przesuwalne.
class SettleSwipe extends StatelessWidget {
  final SingleExpense item;
  final bool isDark;

  /// Czy patrzący jest właścicielem tego wydatku (rozlicza naprawdę).
  final bool isOwner;
  final Future<void> Function(bool settled) onSetSettled;
  final Widget child;

  const SettleSwipe({
    super.key,
    required this.item,
    required this.isDark,
    required this.isOwner,
    required this.onSetSettled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Nie ma czego rozliczać, albo ten użytkownik nie może (cudzy wydatek widziany
    // tylko dzięki członkostwu w projekcie) — backend i tak by odmówił.
    if (!item.isShared || !item.canSettle) return child;

    // Uczestnik z potwierdzonym udziałem nie ma już żadnego gestu:
    // rozliczenia nie może cofnąć, a zgłaszać nie ma czego.
    if (!isOwner && item.settled) return child;

    final texts = AppTexts.of(context);

    return Dismissible(
      key: ValueKey('settle_${item.id}'),
      direction: DismissDirection.horizontal,
      background: _background(
        color: isOwner ? AppColors.amountPositive : Colors.blue,
        icon: Icons.check_circle_rounded,
        label: isOwner ? texts.settleAction : texts.declarePaidAction,
        toRight: true,
      ),
      secondaryBackground: _background(
        color: AppColors.amountNegative,
        icon: Icons.undo_rounded,
        label: isOwner ? texts.unsettleAction : texts.retractDeclareAction,
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
