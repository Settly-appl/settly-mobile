import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/notifications_store.dart';

// ── Kategorie filtrów ─────────────────────────────────────────────────────────
enum AllExpensesPage { all, food, transport, shopping, other }

extension ExpenseCategoryLabel on AllExpensesPage {
  String localizedLabel(AppTexts texts) {
    switch (this) {
      case AllExpensesPage.all:
        return texts.expensesLabelAll;
      case AllExpensesPage.food:
        return texts.expensesLabelFood;
      case AllExpensesPage.transport:
        return texts.expensesLabelTransport;
      case AllExpensesPage.shopping:
        return texts.expensesLabelShopping;
      case AllExpensesPage.other:
        return texts.expensesLabelOther;
    }
  }

  // Wartość wysyłana do API (null = wszystkie)
  String? get apiValue {
    switch (this) {
      case AllExpensesPage.all:
        return null;
      case AllExpensesPage.food:
        return 'food';
      case AllExpensesPage.transport:
        return 'transport';
      case AllExpensesPage.shopping:
        return 'shopping';
      case AllExpensesPage.other:
        return 'other';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ExpensesPage
// ════════════════════════════════════════════════════════════════════════════
class ExpensesPage extends StatefulWidget {
  final ValueNotifier<int> tabNotifier;
  const ExpensesPage({super.key, required this.tabNotifier});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // ── Stan ───────────────────────────────────────────────────────────────────
  List<SingleExpense> _expenses = [];
  bool _isLoading = true;
  AllExpensesPage _selectedCategory = AllExpensesPage.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription<AppNotification>? _notifSub;

  final _expenseRepository = ExpenseRepository();

  // ── Podsumowanie (hardcoded — docelowo z API) ──────────────────────────────
  String get _monthLabel {
    if (_expenses.isEmpty) return '';
    final now = DateTime.now();
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month]} ${now.year}';
  }

  String get _totalSpent {
    final sum = _expenses.fold<double>(0.0, (acc, e) {
      final cleaned = e.totalAmount.replaceAll(RegExp(r'[^0-9.]'), '');
      return acc + (double.tryParse(cleaned) ?? 0.0);
    });
    return '${sum.toStringAsFixed(0)} zł';
  }

  String get _totalCount => '${_expenses.length} transactions';

  String get _dailyAverage {
    final now = DateTime.now();
    final days = now.day;
    if (days == 0) return '0 zł';
    final sum = _expenses.fold<double>(0.0, (acc, e) {
      final cleaned = e.totalAmount.replaceAll(RegExp(r'[^0-9.]'), '');
      return acc + (double.tryParse(cleaned) ?? 0.0);
    });
    return '${(sum / days).toStringAsFixed(0)} zł';
  }

  String get _daysInMonth {
    final now = DateTime.now();
    return 'of ${DateUtils.getDaysInMonth(now.year, now.month)} days';
  }

  // Kolejność wyświetlania grup
  static const _groupPrefixOrder = [
    'TODAY',
    'YESTERDAY',
    'THISWEEK',
    'LAST2W',
    'THISMONTH',
    'MONTH',
    'OLD',
  ];

  // ── Inicjalizacja ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    widget.tabNotifier.addListener(_onTabChanged);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    // Refresh when added to a shared expense while this page is up.
    _notifSub = NotificationsStore().stream.listen((n) {
      if (mounted && n.type == 'EXPENSE_SPLIT') _fetchExpenses();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchController.dispose();
    widget.tabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabNotifier.value == 1) {
      _fetchExpenses();
    }
  }

  // ── Pobranie danych z API ──────────────────────────────────────────────────
  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);

    final category = _selectedCategory.apiValue;
    final categoryParam = category != null ? '&category=$category' : '';

    final response = await ApiServiceRequest().request(
      endpoint:
          'expenses?pageNumber=0&pageSize=20&sortBy=createdAt&sortDirection=desc$categoryParam',
      method: HttpMethod.get,
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fetched = SingleExpense.listFromJson(data['content']);

      // Pobierz userShare dla każdego wydatku z endpointu
      for (var expense in fetched) {
        if (expense.id != null) {
          final userShare = await _expenseRepository.fetchUserShareForExpense(
            expenseId: expense.id!,
            currency: expense.currency,
          );
          if (userShare != null) {
            expense.userShare = userShare;
          }
        }
      }

      setState(() => _expenses = fetched);
    }

    setState(() => _isLoading = false);
  }

  // ── Filtrowanie lokalne po wyszukiwarce ───────────────────────────────────
  List<SingleExpense> get _filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    return _expenses
        .where(
          (e) =>
              e.name.toLowerCase().contains(_searchQuery) ||
              e.note.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  // ── Grupowanie po dacie (klucz = "dd MMM") ────────────────────────────────
  Map<String, List<SingleExpense>> get _grouped {
    final Map<String, List<SingleExpense>> map = {};
    for (final e in _filteredExpenses) {
      final key = _formatDateKey(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff =
        (today.millisecondsSinceEpoch - d.millisecondsSinceEpoch) ~/
        (1000 * 60 * 60 * 24);

    const polishMonths = [
      '',
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia',
    ];
    const englishMonths = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final texts = AppTexts.of(context);
    final isEn = texts.locale.languageCode == 'en';
    final months = isEn ? englishMonths : polishMonths;
    final dayMonth = '${date.day} ${months[date.month]}';

    if (diff == 0) return 'TODAY - $dayMonth';
    if (diff == 1) return 'YESTERDAY - $dayMonth';
    if (diff <= 6) return 'THISWEEK - ${texts.thisWeekLabel}';
    if (diff <= 13) return 'LAST2W - ${texts.lastTwoWeeksLabel}';
    if (date.month == now.month && date.year == now.year)
      return 'THISMONTH|${texts.thisMonthLabel}';
    if (date.year == now.year) return 'MONTH|${months[date.month]}';
    return 'OLD|${months[date.month]} ${date.year}';
  }

  List<String> get _sortedGroupKeys {
    final keys = _grouped.keys.toList();
    keys.sort((a, b) {
      final prefixA = a.split('|').first;
      final prefixB = b.split('|').first;
      final indexA = _groupPrefixOrder.indexOf(prefixA);
      final indexB = _groupPrefixOrder.indexOf(prefixB);
      // Nieznane prefiksy idą na koniec
      final ia = indexA == -1 ? 999 : indexA;
      final ib = indexB == -1 ? 999 : indexB;
      return ia.compareTo(ib);
    });
    return keys;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchExpenses,
        color: AppColors.actionScanIcon(isDark),
        backgroundColor: AppColors.cardBg(isDark),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCard()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildFilterRow()),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: const SizedBox(height: 4)),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredExpenses.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              _buildGroupedList(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final texts = AppTexts.of(context);
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      title: Text(
        texts.expensesTitle,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.username(isDark),
        ),
      ),
      actions: [
        _AppBarIconBtn(
          isDark: isDark,
          icon: Icons.sort_rounded,
          onTap: () {
            // TODO: bottomSheet sortowania
          },
        ),
        const SizedBox(width: 8),
        _AppBarIconBtn(
          isDark: isDark,
          icon: Icons.calendar_month_outlined,
          onTap: () {
            // TODO: picker miesiąca
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // ── Karta podsumowania ─────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final texts = AppTexts.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            _monthLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.summaryTitle,
              letterSpacing: 0.04,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: texts.expensesSummarySpent,
                  value: _totalSpent,
                  sub: _totalCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: texts.expensesSummaryAverage,
                  value: _dailyAverage,
                  sub: _daysInMonth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filtry kategorii ───────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    final texts = AppTexts.of(context);
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: AllExpensesPage.values.map((cat) {
          final active = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () {
                if (_selectedCategory == cat) return;
                setState(() => _selectedCategory = cat);
                _fetchExpenses();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.actionScanIconBg(isDark)
                      : AppColors.pinnedEmptyBg(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.actionScanIcon(
                            isDark,
                          ).withValues(alpha: 0.4)
                        : AppColors.cardBorder(isDark),
                  ),
                ),
                child: Text(
                  cat.localizedLabel(texts),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.actionScanIcon(isDark)
                        : AppColors.cardSubtitle(isDark),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Wyszukiwarka ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final texts = AppTexts.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder(isDark)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 16,
              color: AppColors.cardSubtitle(isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.cardTitle(isDark),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: texts.expensesSearchHint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.formPlaceholder(isDark),
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => _searchController.clear(),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.cardSubtitle(isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Lista pogrupowana po dacie ─────────────────────────────────────────────
  Widget _buildGroupedList() {
    final groups = _grouped;
    final keys = _sortedGroupKeys;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final key = keys[index];
        final items = groups[key]!;
        return _ExpenseDateGroup(label: key, items: items, isDark: isDark);
      }, childCount: keys.length),
    );
  }

  // ── Pusty stan ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final texts = AppTexts.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: AppColors.cardSubtitle(isDark).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            texts.expensesNoExpenses,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.cardTitle(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? texts.expensesNoResults.replaceAll('{query}', _searchQuery)
                : texts.expensesNoCategory,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cardSubtitle(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgety prywatne
// ════════════════════════════════════════════════════════════════════════════

class _AppBarIconBtn extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIconBtn({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder(isDark)),
        ),
        child: Icon(icon, size: 16, color: AppColors.cardSubtitle(isDark)),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
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
              fontSize: 10,
              color: AppColors.summaryTileLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.summaryTileValue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.summaryTileSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDateGroup extends StatelessWidget {
  final String label;
  final List<SingleExpense> items;
  final bool isDark;

  const _ExpenseDateGroup({
    required this.label,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardSubtitle(isDark),
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.cardBorder(isDark),
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _ExpenseRow(item: item, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final SingleExpense item;
  final bool isDark;

  const _ExpenseRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final style = item.style(isDark);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailsPage(expense: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: style.iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(style.icon, size: 17, color: style.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cardTitle(isDark),
                    ),
                  ),
                  if (item.note.isNotEmpty)
                    Text(
                      item.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.cardSubtitle(isDark),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.userShare.isNotEmpty ? item.userShare : item.totalAmount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardAmount(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: style.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: style.badgeFg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
