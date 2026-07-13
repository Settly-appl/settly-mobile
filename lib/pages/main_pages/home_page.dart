import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:settly_mobile/firebase_web_config.dart';
import 'package:settly_mobile/services/pwa_install.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/main.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/models/pinned_items/pinned_item.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/widgets/enable_notifications_button.dart';
import 'package:settly_mobile/widgets/settlement.dart';
import 'package:settly_mobile/widgets/user_avatar.dart';
import 'package:settly_mobile/widgets/hoverable.dart';
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
  final String? userAvatarUrl;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.userName,
    required this.userInitials,
    this.userAvatarUrl,
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

  final List<IconData> _navIcons = [
    Icons.grid_view_rounded,
    Icons.attach_money_rounded,
    Icons.group_outlined,
    Icons.people_outline,
    Icons.bar_chart_rounded,
  ];

  List<SingleExpense> recentItems = [];

  List<PinnedItem> pinnedItems = [];
  final _pinnedRepo = PinnedRepository();

  @override
  void initState() {
    super.initState();
    _fetchRecentExpenses();

    // Refresh when added to a shared expense, or when someone settles/unsettles
    // one — the tiles' settled markers and the balances card would be stale.
    _notifSub = NotificationsStore().stream.listen((n) {
      if (!mounted) return;
      if (n.type == 'EXPENSE_SPLIT') {
        _fetchRecentExpenses();
      } else if (n.type == 'EXPENSE_SETTLEMENT') {
        _refreshHome();
      }
    });

    // Handle a notification tapped while the app was terminated, now that the
    // home screen (and navigator) is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().consumePendingNavigation();
      NotificationService().consumeWebLaunch();
      _maybeOfferInstall();
    });
  }

  // One-time PWA install banner. Shown at most once (per device); dismissing it
  // — by either action — records the choice so it never auto-shows again.
  Future<void> _maybeOfferInstall() async {
    if (!await PwaInstall.shouldOfferAutoPrompt()) return;
    if (!mounted) return;
    final texts = AppTexts.of(context);
    final messenger = ScaffoldMessenger.of(context);

    void close() {
      messenger.hideCurrentMaterialBanner();
      PwaInstall.markAutoPromptDismissed();
    }

    // Count it as shown right away so it never auto-appears again, even if the
    // user ignores it.
    PwaInstall.markAutoPromptDismissed();

    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(texts.pwaInstallBanner),
        leading: const Icon(Icons.install_mobile_outlined),
        actions: [
          TextButton(
            onPressed: () {
              close();
              PwaInstall.promptInstall();
            },
            child: Text(texts.pwaInstallAction),
          ),
          TextButton(
            onPressed: close,
            child: Text(texts.pwaInstallNotNow),
          ),
        ],
      ),
    );
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

  /// Settle / unsettle an expense from the home list (swipe). Refreshes the
  /// summary card too, since the balance changes.
  Future<void> _setSettled(SingleExpense item, bool settled) async {
    final id = item.id;
    if (id == null) return;

    final texts = AppTexts.of(context);
    final result = await ExpenseRepository().setExpenseSettled(
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
      item.settledCount = settled ? item.splitCount : 0;
      _summaryKey = UniqueKey(); // balances changed
    });
  }

  List<Widget> _pages(BuildContext context) {
    final texts = AppTexts.of(context);
    return [
      _HomeBody(state: this),
      ExpensesPage(tabNotifier: _tabNotifier),
      const ProjectsPage(),
      const FriendsPage(),
      _PlaceholderTab(label: texts.analysisTab),
    ];
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userName: widget.userName,
          userInitials: widget.userInitials,
          userAvatarUrl: widget.userAvatarUrl,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  static const double _wideBreakpoint = 840;

  static const double _maxContentWidth = 1080;

  Widget _buildAvatar(double radius) {
    return UserAvatar(
      radius: radius,
      avatarUrl: widget.userAvatarUrl,
      initials: widget.userInitials,
      backgroundColor: AppColors.avatarBg(isDark),
      foregroundColor: AppColors.avatarFg(isDark),
      fontSize: radius * 0.6,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _wideBreakpoint;

        final Widget body = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: IndexedStack(index: _currentTab, children: _pages(context)),
          ),
        );

        if (isWide) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: Row(
                children: [
                  _buildNavRail(context),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.navBorder(isDark),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: _currentTab == 0 ? _buildAppBar(context) : null,
          body: body,
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  void _onSelectTab(int index) {
    _tabNotifier.value = index;
    setState(() => _currentTab = index);
  }

  Widget _buildNavRail(BuildContext context) {
    final texts = AppTexts.of(context);

    return NavigationRail(
      selectedIndex: _currentTab,
      onDestinationSelected: _onSelectTab,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Hoverable(
          onTap: _openProfile,
          child: Tooltip(
            message: widget.userName,
            child: _buildAvatar(22),
          ),
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!kIsWeb || kFirebaseWebConfigured)
                  ListenableBuilder(
                    listenable: NotificationsStore(),
                    builder: (context, _) {
                      final unread = NotificationsStore().unreadCount;
                      return IconButton(
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread'),
                          child: const Icon(Icons.notifications_none_rounded),
                        ),
                        color: AppColors.bellIcon(isDark),
                        tooltip: texts.notificationsTitle,
                        onPressed: _openNotifications,
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.dark_mode_outlined),
                  tooltip: texts.changeThemeTooltip,
                  onPressed: () {
                    MyApp.of(
                      context,
                    ).changeTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      selectedIconTheme: IconThemeData(color: AppColors.navActive(isDark)),
      unselectedIconTheme: IconThemeData(color: AppColors.navInactive(isDark)),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.navActive(isDark),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.navInactive(isDark),
        fontSize: 12,
      ),
      destinations: [
        for (var i = 0; i < _navIcons.length; i++)
          NavigationRailDestination(
            icon: Icon(_navIcons[i]),
            label: Text(_navLabel(texts, i)),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final texts = AppTexts.of(context);

    return AppBar(
      leadingWidth: 70,
      toolbarHeight: 80, // more top breathing room for the greeting
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
              texts.homeGreeting,
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
          child: Hoverable(
            onTap: _openProfile,
            child: _buildAvatar(23),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.dark_mode_outlined),
          tooltip: texts.changeThemeTooltip,
          onPressed: () {
            MyApp.of(
              context,
            ).changeTheme(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        if (!kIsWeb || kFirebaseWebConfigured) ...[
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
        ],
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
            Hoverable(
              onTap: onActionTap,
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

  Widget _buildBottomNav(BuildContext context) {
    final texts = AppTexts.of(context);

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
          final icon = entry.value;
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
                      icon,
                      color: isSelected
                          ? AppColors.navActive(isDark)
                          : AppColors.navInactive(isDark),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navLabel(texts, idx),
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

  String _navLabel(AppTexts texts, int index) {
    switch (index) {
      case 0:
        return texts.homeTab;
      case 1:
        return texts.expensesTab;
      case 2:
        return texts.groupsTab;
      case 3:
        return texts.friendsTab;
      default:
        return texts.analysisTab;
    }
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
    final texts = AppTexts.of(context);

    return RefreshIndicator(
      onRefresh: state._refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SummaryCard(key: state._summaryKey),
          const SizedBox(height: 16),
          state._sectionHeader(texts.quickActionsSection),
          const SizedBox(height: 10),
          QuickActionsRow(
            isDark: state.isDark,
            onExpenseAdded: state._fetchRecentExpenses,
          ),
          const SizedBox(height: 16),

          state._sectionHeader(texts.pinnedSection, action: texts.editAction),
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
            texts.recentSection,
            action: texts.seeAllAction,
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
                      child: SettleSwipe(
                        item: state.recentItems[index],
                        isDark: state.isDark,
                        onSetSettled: (settled) =>
                            state._setSettled(state.recentItems[index], settled),
                        child: RecentExpenseCard(
                          item: state.recentItems[index],
                          isDark: state.isDark,
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailsPage(
                                  expense: state.recentItems[index],
                                ),
                              ),
                            );
                            if (changed == true) state._refreshHome();
                          },
                        ),
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
            AppTexts.of(context).comingSoon,
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
    final texts = AppTexts.of(context);
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
                // Kto otwiera dzwonek z wyłączonymi powiadomieniami, dostaje tu
                // jedyną ścieżkę naprawy — inaczej nie ma jak się dowiedzieć,
                // że push w ogóle nie działa.
                FutureBuilder<bool>(
                  future: NotificationService().isEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.data != false) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            texts.notifDisabledHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.cardSubtitle(
                                Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const EnableNotificationsButton(),
                          const SizedBox(height: 4),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.notificationsTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        TextButton(
                          onPressed: store.clear,
                          child: Text(texts.clearAction),
                        ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(texts.noNotifications)),
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
