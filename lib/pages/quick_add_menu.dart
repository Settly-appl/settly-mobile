import 'package:flutter/material.dart';
import 'package:settly_mobile/pages/single_expense_add_page.dart';

import '../models/sheet_option.dart';

class QuickAddMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1723), // ← TŁO POPUPU
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Wybierz typ, który chcesz utworzyć',
              style: TextStyle(color: Color(0xFF4A6A85), fontSize: 12),
            ),
            SizedBox(height: 20),
            _SheetOption(
              option: SheetOption(
                icon: Icons.receipt_long,
                iconColor: Color(0xFF00C896),
                iconBackground: Color(0xFF0d2a20),
                borderColor: Color(0xFF1a4a35),
                title: 'Pojedynczy wydatek',
                subtitle: 'Sklep, restauracja, transport…',
                titleColor: Color(0xFF00C896),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SingleExpenseAddPage(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.group,
                iconColor: Color(0xFF60B8F5),
                iconBackground: Color(0xFF0a1e32),
                borderColor: Color(0xFF1a3060),
                title: 'Projekt grupowy',
                subtitle: 'Wyjazd, impreza, wspólne zakupy…',
                titleColor: Color(0xFF60B8F5),
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
                  color: Color(0xFF132233),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Anuluj',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4A6A85),
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
