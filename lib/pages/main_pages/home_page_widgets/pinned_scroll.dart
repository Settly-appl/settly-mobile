import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settly_mobile/models/pinned_items/pinned_item.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/widgets/hoverable.dart';
import '../../../const/app_texts.dart';
import 'pin_picker_sheet.dart';

class PinnedScroll extends StatelessWidget {
  final bool isDark;
  final List<PinnedItem> pinnedItems;
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

  Future<void> _handlePinnedClick(BuildContext context, PinnedItem item) async {
    if (item.type == PinnedItemType.expense) {
      bool isLoaderOpen = false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      isLoaderOpen = true;
      try {
        final response = await ApiServiceRequest().request(
          endpoint: 'expenses/${item.id}',
          method: HttpMethod.get,
        );

        if (response != null && response.statusCode == 200) {
          final expense = SingleExpense.fromJson(jsonDecode(response.body));

          if (context.mounted) {
            Navigator.pop(context);
            isLoaderOpen = false;

            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseDetailsPage(expense: expense),
              ),
            );
            if (changed == true) await onRefresh();
          }
        }
      } catch (e) {
        print("Błąd: $e");
      } finally {
        if (isLoaderOpen && context.mounted) {
          Navigator.pop(context);
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppTexts.of(context).comingSoon)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _AddPinTile(isDark: isDark, onTap: () => _openPinPicker(context)),
          const SizedBox(width: 10),
          ...pinnedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _PinnedTile(
                item: item,
                isDark: isDark,
                onTap: () => _handlePinnedClick(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPinTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddPinTile({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Hoverable(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(isDark), width: 1.5),
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
              texts.pinTileAction,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.actionScanIcon(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              texts.pinTileSubtitle,
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

class _PinnedTile extends StatelessWidget {
  final PinnedItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _PinnedTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Hoverable(
      onTap: onTap,
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.type == PinnedItemType.project
                        ? Colors.blueAccent.withValues(alpha: 0.15)
                        : item.iconBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.type == PinnedItemType.project
                        ? texts.pinTypeProjLabel
                        : texts.pinTypeExpLabel,
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
      ),
    );
  }
}
