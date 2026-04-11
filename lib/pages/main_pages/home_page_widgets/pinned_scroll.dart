// lib/pages/home_page/home_page_widgets/pinned_scroll.dart
//
// Poziomy scroll przypiętych kafelków + kafelek "Przypnij wydatek lub projekt".
// Obsługuje wydatki i projekty (PinnedItem) zamiast starego PinnedCard.

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/pinned_item.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'pin_picker_sheet.dart';

class PinnedScroll extends StatelessWidget {
  final bool isDark;
  final List<PinnedItem> pinnedItems;

  /// Callback do odświeżenia listy przypiętych w HomePageState.
  final Future<void> Function() onRefresh;

  const PinnedScroll({
    super.key,
    required this.isDark,
    required this.pinnedItems,
    required this.onRefresh,
  });

  void _openPinPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinPickerSheet(isDark: isDark, onPinned: onRefresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // ── Kafelek "Przypnij" ──────────────────────────────────────────────
          _AddPinTile(isDark: isDark, onTap: () => _openPinPicker(context)),
          const SizedBox(width: 10),

          // ── Przypięte elementy ─────────────────────────────────────────────
          ...pinnedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _PinnedTile(item: item, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Kafelek z "+" — otwiera PinPickerSheet
// ════════════════════════════════════════════════════════════════════════════
class _AddPinTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddPinTile({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder(isDark),
            width: 1.5,
            // Linia przerywana jest natywnie dostępna tylko przez CustomPainter;
            // tu używamy zwykłej ramki — prosta i czytelna.
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.actionScanIcon(isDark).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.push_pin_outlined,
                size: 18,
                color: AppColors.actionScanIcon(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Przypnij',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.actionScanIcon(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'wydatek / projekt',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.cardSubtitle(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Kafelek przypiętego elementu
// ════════════════════════════════════════════════════════════════════════════
class _PinnedTile extends StatelessWidget {
  final PinnedItem item;
  final bool isDark;

  const _PinnedTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikona + badge typu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 15, color: item.iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: item.type == PinnedItemType.project
                      ? Colors.blueAccent.withValues(alpha: 0.15)
                      : item.iconBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  item.type == PinnedItemType.project ? 'Proj.' : 'Wyd.',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: item.iconColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Nazwa
          Text(
            item.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Kwota
          Text(
            '${item.amount} ${item.currency}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.cardAmount(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
