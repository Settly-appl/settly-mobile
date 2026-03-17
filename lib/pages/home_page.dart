import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/models/pinned_card.dart';
import 'package:settly_mobile/models/recent_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Zmienne do zmiany gdy bedzie dostep do Api
  String userName = "Mateusz";
  String firstLettersFromUserInAvatarCircle = "MD";
  int _currentTab = -1;

  final List<Map<String, dynamic>> _navIcons = [
    {'icon': Icons.grid_view_rounded, 'label': 'Główna'},
    {'icon': Icons.attach_money_rounded, 'label': 'Wydatki'},
    {'icon': Icons.group_outlined, 'label': 'Grupy'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Analiza'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
  ];

  List<RecentExpense> recentItems = [];
  List<PinnedCard> pinnedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dzień dobry,',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.greetingLight,
              ),
            ),
            Text(
              userName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.usernameLight,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Center(
            child: CircleAvatar(
              backgroundColor: AppColors.avatarBgLight,
              radius: 23,
              child: Text(
                firstLettersFromUserInAvatarCircle,
                style: TextStyle(
                  color: AppColors.avatarFgLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: AppColors.bellBgLight,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              color: AppColors.bellIconLight,
              onPressed: () {}, // Brak funckjonalnosci narazie
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryCard(),
          const SizedBox(height: 16),
          _sectionHeader('Szybkie akcje'),
          const SizedBox(height: 10),
          _quickActions(context),
          const SizedBox(height: 16),
          _sectionHeader('Przypięte', action: 'Edytuj'),
          const SizedBox(height: 10),
          _pinnedScroll(),
          const SizedBox(height: 16),
          _sectionHeader('Ostatnie', action: 'Zobacz wszystkie'),
          const SizedBox(height: 10),

          // Lista OSTATNIE (zajmuje resztę ekranu i scrolluje)
          Expanded(
            child: recentItems.isEmpty
                ? _buildEmptyRecentCard() // Jeśli pusta -> pokaż komunikat
                : ListView.separated(
                    // Jeśli ma elementy -> pokaż listę
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = recentItems[index];
                      return _recentCard(item);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.navBorderLight, width: 1.0),
            ),
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navIcons.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;
                  bool isSelected = _currentTab == idx;

                  return GestureDetector(
                    onTap: () => setState(() => _currentTab = idx),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'],
                          color: isSelected
                              ? AppColors.navActiveLight
                              : AppColors.navInactiveLight,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.navActiveLight
                                : AppColors.navInactiveLight,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.navActiveLight
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Karta podsumowania ───────────────────────────────────────────────────────
  Widget _summaryCard() {
    String formattedDate = DateFormat('MMMM yyyy', 'pl').format(DateTime.now());

    return Container(
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
          Text(
            'Podsumowanie — $formattedDate',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.summaryTitle,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'Należności',
                  amount: '210 zł',
                  subtitle: 'inni Tobie',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  label: 'Zobowiązania',
                  amount: '85 zł',
                  subtitle: 'Ty innym',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Kafelek w karcie podsumowania ────────────────────────────────────────────
  Widget _summaryTile({
    required String label,
    required String amount,
    required String subtitle,
  }) {
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

  // ── Nagłówek sekcji ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.sectionTitleLight,
            ),
          ),
          if (action != null)
            Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sectionActionLight,
              ),
            ),
        ],
      ),
    );
  }

  // ── Szybkie akcje — wiersz przycisków ────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'Dodaj',
              icon: Icons.add,
              iconColor: AppColors.actionAddIconLight,
              iconBg: AppColors.actionAddIconBgLight,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              label: 'Skanuj',
              icon: Icons.camera_alt_outlined,
              iconColor: AppColors.actionScanIconLight,
              iconBg: AppColors.actionScanIconBgLight,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              label: 'Projekt',
              icon: Icons.group_outlined,
              iconColor: AppColors.actionProjectIconLight,
              iconBg: AppColors.actionProjectIconBgLight,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              label: 'Rozlicz',
              icon: Icons.check_box_outlined,
              iconColor: AppColors.actionSettleIconLight,
              iconBg: AppColors.actionSettleIconBgLight,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Funkcja Skanowania będzie dostępna wkrótce!",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Pojedynczy przycisk szybkiej akcji ───────────────────────────────────────
  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.actionBtnBgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.actionBtnBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.actionBtnLabelLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Poziomy scroll przypiętych ────────────────────────────────────────────────
  Widget _pinnedScroll() {
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
                    SnackBar(
                      content: Text(
                        "Funkcja otwierania przypiętych będzie dostępna wkrótce!",
                      ),
                    ),
                  );
                },
                child: _pinnedCard(item),
              ),
            ),
          ),
          _pinnedEmpty(),
        ],
      ),
    );
  }

  // ── Karta przypięta ───────────────────────────────────────────────────────────
  Widget _pinnedCard(PinnedCard item) {
    // Przekazujemy cały obiekt modelu
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderLight),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitleLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.cardSubtitleLight,
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

  // ── Pusta karta "Przypnij" ────────────────────────────────────────────────────
  Widget _pinnedEmpty() {
    return GestureDetector(
      onTap: () {}, // do implementacji dodawanie przypietego projektu
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pinnedEmptyBgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.pinnedEmptyBorderLight,
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
                color: AppColors.pinnedEmptyCircleBgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: AppColors.pinnedEmptyIconLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Przypnij projekt lub wydatek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.pinnedEmptyTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Karta z listy "Ostatnie" ──────────────────────────────────────────────────
  Widget _recentCard(RecentExpense item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 16, color: item.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cardTitleLight,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.cardSubtitleLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.totalAmount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardAmountLight,
                ),
              ),
              const SizedBox(height: 3),
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
        ],
      ),
    );
  }

  Widget _buildEmptyRecentCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.greetingLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Brak wydatków',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.greetingLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Twoje ostatnie transakcje pojawią się tutaj.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.greetingLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
