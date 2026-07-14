import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/expense_form_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Menu kontekstowe wydatku (long-press na kafelku listy / strony głównej).
///
/// Te same reguły co w szczegółach wydatku i geście swipe:
///  - rozlicza tylko właściciel; uczestnik jedynie ZGŁASZA zapłatę (sugestię,
///    którą właściciel potwierdza) — dlatego etykieta zależy od `isOwner`,
///  - edycja i usuwanie tylko dla właściciela,
///  - „Powtórz" dla każdego, kto widzi wydatek (tworzy własny nowy).
///
/// `onSetSettled` dostaje dokładnie ten sam callback co SettleSwipe, więc
/// aktualizacja kafelka w miejscu działa identycznie jak przy swipe.
/// `onChanged` odświeża listę po edycji / usunięciu / powtórzeniu.
Future<void> showExpenseActionsSheet({
  required BuildContext context,
  required SingleExpense item,
  required bool isDark,
  required bool isOwner,
  required Future<void> Function(bool settled) onSetSettled,
  required VoidCallback onChanged,
}) async {
  final texts = AppTexts.of(context);
  final canAct = item.isShared && item.canSettle;

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.cardBg(isDark),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardTitle(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.totalAmount} ${item.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardAmount(isDark),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 10),
          if (canAct && isOwner && !item.settled)
            _tile(
              ctx,
              'settle',
              Icons.check_circle_rounded,
              texts.settleAction,
              color: AppColors.amountPositive,
              isDark: isDark,
            ),
          if (canAct && isOwner && (item.settled || item.isPartiallySettled))
            _tile(
              ctx,
              'unsettle',
              Icons.undo_rounded,
              texts.undoSettlementAction,
              isDark: isDark,
            ),
          if (canAct && !isOwner && !item.settled && !item.declared)
            _tile(
              ctx,
              'settle',
              Icons.check_circle_rounded,
              texts.declarePaidAction,
              color: Colors.blue,
              isDark: isDark,
            ),
          if (canAct && !isOwner && !item.settled && item.declared)
            _tile(
              ctx,
              'unsettle',
              Icons.undo_rounded,
              texts.retractDeclareLong,
              color: Colors.blue,
              isDark: isDark,
            ),
          _tile(
            ctx,
            'repeat',
            Icons.repeat_rounded,
            texts.repeatAction,
            isDark: isDark,
          ),
          if (isOwner)
            _tile(
              ctx,
              'edit',
              Icons.edit_outlined,
              texts.editAction,
              isDark: isDark,
            ),
          if (isOwner)
            _tile(
              ctx,
              'delete',
              Icons.delete_outline,
              texts.deleteAction,
              color: AppColors.amountNegative,
              isDark: isDark,
            ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case 'settle':
      await onSetSettled(true);
    case 'unsettle':
      await onSetSettled(false);
    case 'repeat':
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ExpenseFormPage(isDark: isDark, repeatExpense: item),
        ),
      );
      if (saved == true) onChanged();
    case 'edit':
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ExpenseFormPage(isDark: isDark, editExpense: item),
        ),
      );
      if (saved == true) onChanged();
    case 'delete':
      await _confirmAndDelete(context, item, texts, onChanged);
  }
}

Widget _tile(
  BuildContext ctx,
  String action,
  IconData icon,
  String label, {
  Color? color,
  required bool isDark,
}) {
  final effective = color ?? AppColors.cardTitle(isDark);
  return ListTile(
    dense: true,
    leading: Icon(icon, size: 20, color: effective),
    title: Text(label, style: TextStyle(color: effective)),
    onTap: () => Navigator.pop(ctx, action),
  );
}

/// Ten sam przebieg co usuwanie w szczegółach wydatku: dialog → DELETE →
/// odświeżenie listy (albo komunikat o błędzie).
Future<void> _confirmAndDelete(
  BuildContext context,
  SingleExpense item,
  AppTexts texts,
  VoidCallback onChanged,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(texts.expenseDeleteTitle),
      content: Text(texts.expenseDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(texts.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            texts.deleteAction,
            style: TextStyle(color: AppColors.amountNegative),
          ),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final resp = await ApiServiceRequest().request(
    endpoint: 'expenses/${item.id}',
    method: HttpMethod.delete,
  );
  if (!context.mounted) return;
  if (resp != null && (resp.statusCode == 200 || resp.statusCode == 204)) {
    onChanged();
  } else {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texts.expenseDeleteFailed)));
  }
}
