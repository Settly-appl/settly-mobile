import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import '../models/sheet_option.dart';
import 'expense_form_page.dart';

class QuickAddMenu extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onSaved;

  const QuickAddMenu({super.key, required this.isDark, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold(isDark),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFF243d5a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Co chcesz dodać?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Wybierz typ, który chcesz utworzyć',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 20),
            _SheetOption(
              option: SheetOption(
                icon: Icons.receipt_long,
                iconColor: AppColors.actionScanIcon(isDark),
                iconBackground: AppColors.actionScanIconBg(isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(isDark),
                title: 'Pojedynczy wydatek',
                subtitle: 'Sklep, restauracja, transport…',
                titleColor: AppColors.amountCurrency(isDark),
                subtitleColor: AppColors.cardSubtitle(isDark),
                onTap: () async {
                  final rootMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  navigator.pop();

                  final saved = await navigator.push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ExpenseFormPage(isDark: isDark),
                    ),
                  );

                  if (saved == true) {
                    rootMessenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Dodano wydatek.')),
                      );
                    await onSaved();
                  }
                },
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.group,
                iconColor: AppColors.actionAddIcon(isDark),
                iconBackground: AppColors.actionProjectIconBg(isDark),
                borderColor: AppColors.sheetOptionProjectBorder(isDark),
                title: 'Projekt grupowy',
                subtitle: 'Wyjazd, impreza, wspólne zakupy…',
                titleColor: AppColors.iconProject(isDark),
                subtitleColor: AppColors.cardSubtitle(isDark),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: nawigacja do formularza projektu
                },
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sheetCancel(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Anuluj',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cardSubtitle(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final SheetOption option;

  const _SheetOption({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: option.iconBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: option.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: option.iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: TextStyle(
                    color: option.titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4A6A85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
