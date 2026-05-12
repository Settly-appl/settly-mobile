import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/main.dart';
import 'package:settly_mobile/models/pinned_items/pinned_item.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import '../../repository/pinned_item_repository.dart';
import '../../services/api_service/api_service_request.dart';
import '../all_expenses_page.dart';
import '../expense_details_page.dart';
import 'friends_page.dart';
import 'profile_page.dart';
import 'home_page_widgets/pinned_scroll.dart';
import 'home_page_widgets/quick_actions_row.dart';
import 'home_page_widgets/recent_expenses_card.dart';
import 'home_page_widgets/summary_card.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String userInitials;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.userName,
    required this.userInitials,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentTab = 0;
  bool _isLoading = false;
  bool _isPinnedLoading = false;
  bool _hasInitialPinnedLoaded = false;
  final ValueNotifier<int> _tabNotifier = ValueNotifier(0);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final List<Map<String, dynamic>> _navIcons = [
    {'icon': Icons.grid_view_rounded, 'label': 'Główna'},
    {'icon': Icons.attach_money_rounded, 'label': 'Wydatki'},
    {'icon': Icons.group_outlined, 'label': 'Grupy'},
    {'icon': Icons.people_outline, 'label': 'Znajomi'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Analiza'},
  ];

  List<SingleExpense> recentItems = [];

  List<PinnedItem> pinnedItems = [];
  final _pinnedRepo = PinnedRepository();

  @override
  void initState() {
    super.initState();
    _fetchRecentExpenses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialPinnedLoaded) {
      _hasInitialPinnedLoaded = true;
      _fetchPinnedItems();
    }
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  void switchTab(int index) => setState(() => _currentTab = index);

  List<Widget> get _pages => [
    _HomeBody(state: this),
    ExpensesPage(tabNotifier: _tabNotifier),
    const _PlaceholderTab(label: 'Grupy'),
    const FriendsPage(),
    const _PlaceholderTab(label: 'Analiza'),
  ];

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userName: widget.userName,
          userInitials: widget.userInitials,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _currentTab == 0 ? _buildAppBar() : null,
      body: IndexedStack(index: _currentTab, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 70,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openProfile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dzień dobry,',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.greeting(isDark),
              ),
            ),
            Text(
              widget.userName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.username(isDark),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Center(
          child: GestureDetector(
            onTap: _openProfile,
            child: CircleAvatar(
              backgroundColor: AppColors.avatarBg(isDark),
              radius: 23,
              child: Text(
                widget.userInitials,
                style: TextStyle(
                  color: AppColors.avatarFg(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.dark_mode_outlined),
          tooltip: 'Change app theme',
          onPressed: () {
            MyApp.of(
              context,
            ).changeTheme(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.bellBg(isDark),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.bellIcon(isDark),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _sectionHeader(
    String title, {
    String? action,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.sectionTitle(isDark),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  action,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.sectionAction(isDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.navBorder(isDark), width: 1.0),
        ),
      ),
      height: 60,
      child: Row(
        children: _navIcons.asMap().entries.map((entry) {
          final int idx = entry.key;
          final item = entry.value;
          final bool isSelected = _currentTab == idx;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabNotifier.value = idx;
                setState(() => _currentTab = idx);
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      color: isSelected
                          ? AppColors.navActive(isDark)
                          : AppColors.navInactive(isDark),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.navActive(isDark)
                            : AppColors.navInactive(isDark),
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
                            ? AppColors.navActive(isDark)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _fetchRecentExpenses() async {
    setState(() => _isLoading = true);

    final apiService = ApiServiceRequest();
    final response = await apiService.request(
      endpoint: 'expenses?page=0&size=5&sort=createdAt,desc&category=',
      method: HttpMethod.get,
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<SingleExpense> fetched = data['content'] != null
          ? SingleExpense.listFromJson(data['content'])
          : [];
      setState(() {
        recentItems = fetched;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPinnedItems() async {
    if (_isPinnedLoading) return;
    setState(() => _isPinnedLoading = true);

    try {
      final items = await _pinnedRepo.getAll(isDark);
      if (mounted) {
        setState(() {
          pinnedItems = items;
          _isPinnedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPinnedLoading = false);
    }
  }
}

class _HomeBody extends StatelessWidget {
  final HomePageState state;

  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SummaryCard(),
        const SizedBox(height: 16),
        state._sectionHeader('Szybkie akcje'),
        const SizedBox(height: 10),
        QuickActionsRow(
          isDark: state.isDark,
          onExpenseAdded: state._fetchRecentExpenses,
        ),
        const SizedBox(height: 16),

        state._sectionHeader('Przypięte', action: 'Edytuj'),
        const SizedBox(height: 10),

        state._isPinnedLoading
            ? const SizedBox(
                height: 110,
                child: Center(child: CircularProgressIndicator()),
              )
            : PinnedScroll(
                isDark: state.isDark,
                pinnedItems: state.pinnedItems,
                onRefresh: state._fetchPinnedItems,
              ),

        const SizedBox(height: 16),
        state._sectionHeader(
          'Ostatnie',
          action: 'Zobacz wszystkie',
          onActionTap: () => state.switchTab(1),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: state._isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.recentItems.isEmpty
              ? EmptyRecentCard(isDark: state.isDark)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: state.recentItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = state.recentItems[index];
                    return RecentExpenseCard(
                      item: expense,
                      isDark: state.isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExpenseDetailsPage(expense: expense),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;

  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: AppColors.cardSubtitle(isDark).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wkrótce dostępne',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.cardSubtitle(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
