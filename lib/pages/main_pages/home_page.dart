import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/main.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/pinned_items/pinned_item.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import '../../repository/pinned_item_repository.dart';
import '../../services/api_service/api_service_request.dart';
import '../../services/notification_service.dart';
import '../../services/notifications_store.dart';
import '../all_expenses_page.dart';
import '../expense_details_page.dart';
import '../projects_page.dart';
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
  StreamSubscription<AppNotification>? _notifSub;

  // Reassigned on pull-to-refresh to force the SummaryCard to reload its data.
  Key _summaryKey = UniqueKey();

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

    // Refresh recent expenses when added to a shared expense.
    _notifSub = NotificationsStore().stream.listen((n) {
      if (mounted && n.type == 'EXPENSE_SPLIT') _fetchRecentExpenses();
    });

    // Handle a notification tapped while the app was terminated, now that the
    // home screen (and navigator) is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().consumePendingNavigation();
    });
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
    _notifSub?.cancel();
    _tabNotifier.dispose();
    super.dispose();
  }

  void switchTab(int index) => setState(() => _currentTab = index);

  /// Pull-to-refresh for the home tab: reloads recent expenses, pinned items
  /// and the balances summary card.
  Future<void> _refreshHome() async {
    if (mounted) setState(() => _summaryKey = UniqueKey());
    await Future.wait([_fetchRecentExpenses(), _fetchPinnedItems()]);
  }

  List<Widget> get _pages => [
    _HomeBody(state: this),
    ExpensesPage(tabNotifier: _tabNotifier),
    const ProjectsPage(),
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
        ListenableBuilder(
          listenable: NotificationsStore(),
          builder: (context, _) {
            final unread = NotificationsStore().unreadCount;
            return CircleAvatar(
              backgroundColor: AppColors.bellBg(isDark),
              child: IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
                color: AppColors.bellIcon(isDark),
                onPressed: _openNotifications,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openNotifications() {
    NotificationsStore().markAllRead();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.scaffold(isDark),
      builder: (_) => _NotificationsSheet(onOpenFriends: () => switchTab(3)),
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
    return RefreshIndicator(
      onRefresh: state._refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SummaryCard(key: state._summaryKey),
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

          if (state._isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.recentItems.isEmpty)
            EmptyRecentCard(isDark: state.isDark)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  for (var index = 0; index < state.recentItems.length; index++)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                      child: RecentExpenseCard(
                        item: state.recentItems[index],
                        isDark: state.isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseDetailsPage(
                                expense: state.recentItems[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
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

class _NotificationsSheet extends StatelessWidget {
  final VoidCallback onOpenFriends;

  const _NotificationsSheet({required this.onOpenFriends});

  IconData _iconFor(String? type) {
    switch (type) {
      case 'FRIEND_REQUEST':
      case 'FRIEND_REQUEST_ACCEPTED':
        return Icons.people_outline;
      case 'EXPENSE_SPLIT':
        return Icons.attach_money_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = NotificationsStore();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final items = store.items;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Powiadomienia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        TextButton(
                          onPressed: store.clear,
                          child: const Text('Wyczyść'),
                        ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Brak powiadomień')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return ListTile(
                          leading: Icon(_iconFor(n.type)),
                          title: Text(n.title),
                          subtitle: n.body.isEmpty ? null : Text(n.body),
                          onTap: () {
                            Navigator.of(context).pop();
                            if (n.type == 'FRIEND_REQUEST' ||
                                n.type == 'FRIEND_REQUEST_ACCEPTED') {
                              onOpenFriends();
                            } else if (n.type == 'EXPENSE_SPLIT') {
                              NotificationService().navigateForNotification(n);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
