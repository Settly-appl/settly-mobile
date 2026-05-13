import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/receipt_scan_service.dart';
import '../models/quick_add_dialog/sheet_option.dart';
import 'expense_form_page.dart';

class QuickScanMenu extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onSaved;

  const QuickScanMenu({super.key, required this.isDark, required this.onSaved});

  @override
  State<QuickScanMenu> createState() => _QuickScanMenuState();
}

class _QuickScanMenuState extends State<QuickScanMenu> {
  final _scanService = ReceiptScanService();
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold(widget.isDark),
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
              'Skanuj paragon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Wybierz typ wydatku do zskanowania',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 20),
            _SheetOption(
              option: SheetOption(
                icon: Icons.receipt_long,
                iconColor: AppColors.actionScanIcon(widget.isDark),
                iconBackground: AppColors.actionScanIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(widget.isDark),
                title: 'Pojedynczy wydatek',
                subtitle: 'Skanuj paragon z jednym wydatkiem',
                titleColor: AppColors.amountCurrency(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning ? () {} : _handleSingleExpenseScan,
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.people,
                iconColor: AppColors.actionProjectIcon(widget.isDark),
                iconBackground: AppColors.actionProjectIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionProjectBorder(widget.isDark),
                title: 'Wydatek grupowy',
                subtitle: 'Skanuj paragon do projektu',
                titleColor: AppColors.iconProject(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning
                    ? () {}
                    : () {
                        Navigator.pop(context);
                        // TODO: nawigacja do skanowania wydatku grupowego
                      },
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.folder,
                iconColor: AppColors.actionAddIcon(widget.isDark),
                iconBackground: AppColors.actionAddIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(widget.isDark),
                title: 'Wydatek w projekcie',
                subtitle: 'Skanuj i przydziel do projektu',
                titleColor: AppColors.amountCurrency(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning
                    ? () {}
                    : () {
                        Navigator.pop(context);
                        // TODO: nawigacja do skanowania wydatku w projekcie
                      },
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _isScanning ? () {} : () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sheetCancel(widget.isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isScanning
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.cardSubtitle(widget.isDark),
                          ),
                        ),
                      )
                    : Text(
                        'Anuluj',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.cardSubtitle(widget.isDark),
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

  Future<void> _handleSingleExpenseScan() async {
    setState(() => _isScanning = true);

    try {
      // Pick image from camera
      final imageFile = await _scanService.pickImageFromCamera();
      if (imageFile == null) {
        setState(() => _isScanning = false);
        return;
      }

      // Scan receipt using AI
      final result = await _scanService.scanReceipt(imageFile);
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nie udało się zskanować paragonu. Spróbuj ponownie.',
              ),
            ),
          );
          setState(() => _isScanning = false);
        }
        return;
      }

      // Close the scan menu and open expense form with pre-filled data
      if (mounted) {
        final rootMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        navigator.pop();

        final saved = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (_) => ExpenseFormPage(
              isDark: widget.isDark,
              initialCategory: result.category,
              initialCurrency: result.currency,
              initialAmount: result.totalAmount,
            ),
          ),
        );

        if (saved == true) {
          rootMessenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Dodano wydatek.')));
          await widget.onSaved();
        }
      }
    } catch (e) {
      print('Error in _handleSingleExpenseScan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Błąd podczas skanowania. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
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
