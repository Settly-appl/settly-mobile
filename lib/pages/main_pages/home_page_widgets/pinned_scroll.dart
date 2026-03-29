import 'package:flutter/material.dart';
import 'package:settly_mobile/models/pinned_card.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class PinnedScroll extends StatelessWidget {
  final bool isDark;
  final List<PinnedCard> pinnedItems;

  const PinnedScroll({
    super.key,
    required this.isDark,
    required this.pinnedItems,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...pinnedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funkcja otwierania przypiętych będzie dostępna wkrótce!',
                      ),
                    ),
                  );
                },
                child: _PinnedCard(item: item, isDark: isDark),
              ),
            ),
          ),
          _PinnedEmptyCard(isDark: isDark),
        ],
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  final PinnedCard item;
  final bool isDark;

  const _PinnedCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
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
                child: Icon(item.icon, size: 14, color: item.iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.type,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: item.badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.cardSubtitle(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            item.totalAmount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: item.amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedEmptyCard extends StatelessWidget {
  final bool isDark;

  const _PinnedEmptyCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pinnedEmptyBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.pinnedEmptyBorder(isDark),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.pinnedEmptyCircleBg(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: AppColors.pinnedEmptyIcon(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Przypnij projekt lub wydatek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.pinnedEmptyText(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
