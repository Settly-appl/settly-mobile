import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/pages/balances_page.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
import 'package:settly_mobile/pages/expense_form_page.dart';
import 'package:settly_mobile/pages/quick_scan_menu.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/api_service/projects_service.dart';
import 'package:settly_mobile/services/notifications_store.dart';
import 'package:settly_mobile/utils/category_label.dart';
import 'package:settly_mobile/widgets/settlement.dart';

// ── Kategorie filtrów ─────────────────────────────────────────────────────────
// UWAGA: wartości `apiValue` muszą się zgadzać z identyfikatorami kategorii
// zapisywanymi przez formularz wydatku (_kCategories w expense_form_page.dart):
// shopping / food / transport / entertainment / health / others.
enum AllExpensesPage {
  all,
  food,
  transport,
  shopping,
  entertainment,
  health,
  others,
}

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
      case AllExpensesPage.entertainment:
        return texts.categoryEntertainmentLabel;
      case AllExpensesPage.health:
        return texts.categoryHealthLabel;
      case AllExpensesPage.others:
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
      case AllExpensesPage.entertainment:
        return 'entertainment';
      case AllExpensesPage.health:
        return 'health';
      case AllExpensesPage.others:
        return 'others';
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
  bool _isLoading = true; // pierwsza strona
  bool _isLoadingMore = false; // doładowywanie kolejnych stron
  bool _hasMore = true; // czy backend ma jeszcze kolejne strony
  int _nextPage = 0; // numer następnej strony do pobrania
  int _totalElements = 0; // łączna liczba wydatków (z Page.totalElements)
  int _generation = 0; // unieważnia wyniki po zmianie filtra/odświeżeniu
  AllExpensesPage _selectedCategory = AllExpensesPage.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  StreamSubscription<AppNotification>? _notifSub;

  static const int _pageSize = 20;

  final _expenseRepository = ExpenseRepository();
  final _projectsService = ProjectsService();

  // Filtr projektu (null = wszystkie). Filtruje backend, bo lista jest
  // stronicowana — odsiewanie lokalnie pokazałoby tylko wczytany kawałek.
  List<Project> _projects = [];
  String? _selectedProjectId;

  /// id -> nazwa, żeby kafelek mógł pokazać plakietkę projektu.
  Map<String, String> get _projectNames => {
    for (final p in _projects) p.id: p.name,
  };

  // ── Podsumowanie (hardcoded — docelowo z API) ──────────────────────────────
  String get _monthLabel {
    if (_expenses.isEmpty) return '';
    final now = DateTime.now();
    return AppTexts.of(context).monthYear(now.month, now.year);
  }

  double _userPaid(SingleExpense e) {
    final source = e.userShare.isNotEmpty ? e.userShare : e.totalAmount;
    final cleaned = source.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get _userPaidSum =>
      _expenses.fold<double>(0.0, (acc, e) => acc + _userPaid(e));

  String get _totalSpent => '${_userPaidSum.toStringAsFixed(0)} zł';

  String get _totalCount => AppTexts.of(context).transactionsCount(
    _totalElements > 0 ? _totalElements : _expenses.length,
  );

  String get _dailyAverage {
    final now = DateTime.now();
    final days = now.day;
    if (days == 0) return '0 zł';
    final monthSum = _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (acc, e) => acc + _userPaid(e));
    return '${(monthSum / days).toStringAsFixed(0)} zł';
  }

  String get _daysInMonth {
    final now = DateTime.now();
    return AppTexts.of(
      context,
    ).daysInMonthCount(DateUtils.getDaysInMonth(now.year, now.month));
  }

  // ── Inicjalizacja ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProjects();
    _refreshExpenses();
    _scrollController.addListener(_onScroll);
    widget.tabNotifier.addListener(_onTabChanged);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    // Refresh when added to a shared expense while this page is up.
    _notifSub = NotificationsStore().stream.listen((n) {
      if (mounted && n.type == 'EXPENSE_SPLIT') _refreshExpenses();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    widget.tabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabNotifier.value == 1) {
      _refreshExpenses();
    }
  }

  // Doładuj kolejną stronę, gdy użytkownik dojedzie blisko końca listy.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  // ── Pobranie danych z API ──────────────────────────────────────────────────
  // Backend zwraca dane stronicowane (Spring Page) i używa STANDARDOWYCH
  // parametrów Springa — `page`, `size`, `sort=pole,kierunek`. (Wcześniejsze
  // `pageNumber`/`pageSize`/`sortBy`/`sortDirection` były po cichu ignorowane,
  // więc API zawsze oddawało tylko pierwszą stronę 10 najstarszych wydatków.)
  //
  // Ładujemy stronę po stronie — pierwszą od razu, kolejne dopiero gdy
  // użytkownik doscrolluje do końca. `userShare` pobieramy tylko dla świeżo
  // wczytanej strony, żeby nie zasypywać backendu żądaniami na starcie.

  // Odświeżenie od zera (start, zmiana kategorii, powrót na zakładkę, refresh).
  /// Rozlicza / cofa rozliczenie wydatku (swipe). Aktualizuje kafelek w miejscu,
  /// żeby nie przewijać listy od nowa; przy błędzie pokazuje komunikat.
  Future<void> _setSettled(SingleExpense item, bool settled) async {
    final id = item.id;
    if (id == null) return;

    final texts = AppTexts.of(context);
    final result = await _expenseRepository.setExpenseSettled(
      expenseId: id,
      settled: settled,
    );

    if (!mounted) return;
    if (result != SettleResult.ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result == SettleResult.lockedBySettleUp
                  ? texts.settleLockedBySettleUp
                  : texts.expenseSettleFailed,
            ),
          ),
        );
      return;
    }

    setState(() {
      item.settled = settled;
      // Właściciel rozlicza wszystkich naraz; uczestnik tylko siebie — w obu
      // przypadkach z perspektywy tego użytkownika wydatek jest (nie)rozliczony.
      item.settledCount = settled ? item.splitCount : 0;
    });
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectsService.getMyProjects();
      if (mounted) setState(() => _projects = projects);
    } catch (_) {
      // Filtr projektów to dodatek — bez niego lista wydatków nadal działa.
    }
  }

  void _selectProject(String? projectId) {
    if (_selectedProjectId == projectId) return;
    setState(() => _selectedProjectId = projectId);
    _refreshExpenses();
  }

  Future<void> _refreshExpenses() async {
    _generation++;
    final gen = _generation;
    _nextPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    setState(() {
      _expenses = [];
      _isLoading = true;
    });
    await _loadPage(gen);
  }

  // Doładowanie kolejnej strony (infinite scroll).
  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    await _loadPage(_generation);
  }

  Future<void> _loadPage(int gen) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final page = _nextPage;
    final category = _selectedCategory.apiValue;
    final categoryParam = category != null ? '&category=$category' : '';
    final projectParam =
        _selectedProjectId != null ? '&projectId=$_selectedProjectId' : '';

    final response = await ApiServiceRequest().request(
      endpoint:
          'expenses?page=$page&size=$_pageSize&sort=createdAt,desc'
          '$categoryParam$projectParam',
      method: HttpMethod.get,
    );

    // Wynik nieaktualny (zmieniono filtr / odświeżono) — porzuć. Flagę
    // czyścimy tylko jeśli to wciąż nasza generacja; inaczej właścicielem
    // `_isLoadingMore` jest już nowsze ładowanie i nie wolno go ruszać.
    if (!mounted || gen != _generation) {
      if (gen == _generation) _isLoadingMore = false;
      return;
    }

    if (response == null || response.statusCode != 200) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    final data = jsonDecode(response.body);
    final content = (data['content'] as List?) ?? const [];
    final fetched = SingleExpense.listFromJson(content);

    // userShare tylko dla tej jednej strony.
    for (final expense in fetched) {
      if (expense.id != null) {
        final userShare = await _expenseRepository.fetchUserShareForExpense(
          expenseId: expense.id!,
          currency: expense.currency,
        );
        if (userShare != null) expense.userShare = userShare;
      }
      if (gen != _generation) return; // nowsze ładowanie przejęło stan
    }

    if (!mounted || gen != _generation) {
      if (gen == _generation) _isLoadingMore = false;
      return;
    }

    setState(() {
      _expenses = [..._expenses, ...fetched];
      _nextPage = page + 1;
      _totalElements = (data['totalElements'] as int?) ?? _expenses.length;
      _hasMore = !(data['last'] == true || content.isEmpty);
      _isLoading = false;
      _isLoadingMore = false;
    });
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

  // ── Grupowanie po dacie ────────────────────────────────────────────────────
  // Klucz techniczny (`bucketKey`) służy TYLKO do grupowania i sortowania.
  // Etykieta (`label`) jest w pełni przetłumaczona i to ją widzi użytkownik —
  // dzięki temu nie wyciekają już prefiksy typu "MONTH|marca".
  List<_ExpenseGroup> get _groups {
    final texts = AppTexts.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, List<SingleExpense>> buckets = {};
    final Map<String, _GroupMeta> meta = {};

    for (final e in _filteredExpenses) {
      final info = _bucketFor(e.date, now, today, texts);
      buckets.putIfAbsent(info.key, () => []).add(e);

      final existing = meta[info.key];
      if (existing == null) {
        meta[info.key] = _GroupMeta(info.rank, info.label, e.date);
      } else if (e.date.isAfter(existing.latest)) {
        meta[info.key] = _GroupMeta(info.rank, info.label, e.date);
      }
    }

    final keys = buckets.keys.toList()
      ..sort((a, b) {
        final ma = meta[a]!;
        final mb = meta[b]!;
        if (ma.rank != mb.rank) return ma.rank.compareTo(mb.rank);
        // W obrębie tej samej kategorii — najnowsze na górze.
        return mb.latest.compareTo(ma.latest);
      });

    return keys
        .map((k) => _ExpenseGroup(label: meta[k]!.label, items: buckets[k]!))
        .toList();
  }

  _BucketInfo _bucketFor(
    DateTime date,
    DateTime now,
    DateTime today,
    AppTexts texts,
  ) {
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    final dayMonth = '${date.day} ${texts.monthGenitive(date.month)}';

    if (diff == 0) return _BucketInfo('0_today', 0, '${texts.todayLabel} · $dayMonth');
    if (diff == 1) {
      return _BucketInfo('1_yesterday', 1, '${texts.yesterdayLabel} · $dayMonth');
    }
    if (diff <= 6) return _BucketInfo('2_thisweek', 2, texts.thisWeekLabel);
    if (diff <= 13) return _BucketInfo('3_last2w', 3, texts.lastTwoWeeksLabel);
    if (date.month == now.month && date.year == now.year) {
      return _BucketInfo('4_thismonth', 4, texts.thisMonthLabel);
    }
    if (date.year == now.year) {
      return _BucketInfo(
        '5_month_${date.month}',
        5,
        texts.monthNominative(date.month),
      );
    }
    return _BucketInfo(
      '6_old_${date.year}_${date.month}',
      6,
      texts.monthYear(date.month, date.year),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: _buildAppBar(),
      floatingActionButton: _buildFabs(),
      body: RefreshIndicator(
        onRefresh: _refreshExpenses,
        color: AppColors.actionScanIcon(isDark),
        backgroundColor: AppColors.cardBg(isDark),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCard()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildFilterRow()),
            // Filtr projektu pokazujemy tylko, gdy są jakieś projekty — inaczej
            // byłby to pusty, mylący pasek.
            if (_projects.isNotEmpty) ...[
              SliverToBoxAdapter(child: const SizedBox(height: 6)),
              SliverToBoxAdapter(child: _buildProjectFilterRow()),
            ],
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
            // Spinner doładowywania kolejnych stron (tylko gdy nie filtrujemy
            // lokalnie — wyszukiwarka działa na już wczytanych danych).
            if (_isLoadingMore && _searchQuery.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            // Zapas na dole, żeby FAB-y nie zasłaniały ostatniego wiersza.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  // ── Przyciski akcji (dodaj wydatek / skanuj paragon) ───────────────────────
  // Dodawanie prowadzi wprost do formularza; skanowanie nadal ma arkusz
  // wyboru (pojedynczy / grupowy / projekt) — tam opcje faktycznie się różnią.
  Widget _buildFabs() {
    final texts = AppTexts.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'expenses_scan_fab',
          onPressed: _openScanMenu,
          backgroundColor: AppColors.actionScanIconBg(isDark),
          foregroundColor: AppColors.actionScanIcon(isDark),
          tooltip: texts.quickScanTitle,
          child: const Icon(Icons.camera_alt_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'expenses_add_fab',
          onPressed: _openAddMenu,
          backgroundColor: AppColors.avatarFg(isDark),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            texts.projectAddExpense,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Dodawanie wydatku prowadzi wprost do formularza — arkusz wyboru nie miał
  /// sensu, bo o tym, czy wydatek jest wspólny, decyduje wybór znajomych już
  /// w samym formularzu.
  Future<void> _openAddMenu() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExpenseFormPage(isDark: isDark)),
    );
    if (saved == true) await _refreshExpenses();
  }

  Future<void> _openScanMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuickScanMenu(isDark: isDark, onSaved: _refreshExpenses),
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
        TextButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BalancesPage()),
            );
            // Rozliczenie na tamtej stronie zmienia stan splitów — odśwież listę.
            if (mounted) _refreshExpenses();
          },
          icon: Icon(
            Icons.account_balance_wallet_outlined,
            size: 17,
            color: AppColors.actionScanIcon(isDark),
          ),
          label: Text(
            texts.balancesAction,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.actionScanIcon(isDark),
            ),
          ),
        ),
        const SizedBox(width: 6),
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
                _refreshExpenses();
              },
              child: Container(
                alignment: Alignment.center,
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

  /// Filtr projektu — „Wszystkie projekty" + jeden chip na projekt.
  Widget _buildProjectFilterRow() {
    final texts = AppTexts.of(context);

    Widget chip(String label, String? projectId) {
      final active = _selectedProjectId == projectId;
      final accent = AppColors.actionProjectIcon(isDark);
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: GestureDetector(
          onTap: () => _selectProject(projectId),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.actionProjectIconBg(isDark)
                  : AppColors.pinnedEmptyBg(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? accent.withValues(alpha: 0.4)
                    : AppColors.cardBorder(isDark),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  size: 11,
                  color: active ? accent : AppColors.cardSubtitle(isDark),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? accent : AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(texts.expensesAllProjects, null),
          for (final p in _projects) chip(p.name, p.id),
        ],
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
    final groups = _groups;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groups[index];
        return _ExpenseDateGroup(
          label: group.label,
          items: group.items,
          isDark: isDark,
          onChanged: _refreshExpenses,
          onSetSettled: _setSettled,
          projectNames: _projectNames,
        );
      }, childCount: groups.length),
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
  final VoidCallback onChanged;
  final Future<void> Function(SingleExpense item, bool settled) onSetSettled;
  final Map<String, String> projectNames;

  const _ExpenseDateGroup({
    required this.label,
    required this.items,
    required this.isDark,
    required this.onChanged,
    required this.onSetSettled,
    required this.projectNames,
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
              child: SettleSwipe(
                item: item,
                isDark: isDark,
                onSetSettled: (settled) => onSetSettled(item, settled),
                child: _ExpenseRow(
                  item: item,
                  isDark: isDark,
                  onChanged: onChanged,
                  projectName: item.projectId == null
                      ? null
                      : projectNames[item.projectId],
                ),
              ),
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
  final VoidCallback onChanged;

  /// Nazwa projektu, do którego należy wydatek (null = poza projektem).
  final String? projectName;

  const _ExpenseRow({
    required this.item,
    required this.isDark,
    required this.onChanged,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final style = item.style(isDark);
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailsPage(expense: item),
          ),
        );
        if (changed == true) onChanged();
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
                  if (item.isShared || projectName != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (projectName != null) ...[
                          _ProjectBadge(name: projectName!, isDark: isDark),
                          if (item.isShared) const SizedBox(width: 6),
                        ],
                        if (item.isShared)
                          SettledBadge(item: item, isDark: isDark),
                      ],
                    ),
                  ],
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
                    localizedCategoryLabel(item.category, AppTexts.of(context)),
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

// ════════════════════════════════════════════════════════════════════════════
// Pomocnicze modele grupowania
// ════════════════════════════════════════════════════════════════════════════

/// Gotowa do wyświetlenia grupa wydatków (nagłówek + pozycje).
class _ExpenseGroup {
  final String label;
  final List<SingleExpense> items;

  const _ExpenseGroup({required this.label, required this.items});
}

/// Metadane bucketu używane przy budowie i sortowaniu grup.
class _GroupMeta {
  final int rank;
  final String label;
  final DateTime latest;

  const _GroupMeta(this.rank, this.label, this.latest);
}

/// Wynik przydziału pojedynczej daty do grupy.
class _BucketInfo {
  final String key;
  final int rank;
  final String label;

  const _BucketInfo(this.key, this.rank, this.label);
}


/// Plakietka projektu na kafelku wydatku — dzięki niej widać na liście wydatków,
/// co należy do wyjazdu czy imprezy, bez wchodzenia w projekt.
class _ProjectBadge extends StatelessWidget {
  final String name;
  final bool isDark;

  const _ProjectBadge({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.actionProjectIcon(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_2_outlined, size: 9, color: accent),
          const SizedBox(width: 3),
          Text(
            name,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
