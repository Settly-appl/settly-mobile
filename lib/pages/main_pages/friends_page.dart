import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/models/frends/friendship_request.dart';
import 'package:settly_mobile/models/frends/user_search_result.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = ApiServiceRequest();
  final _friendsSearchController = TextEditingController();

  bool _loadingFriends = false;
  bool _loadingRequests = false;
  List<Friend> _friends = [];
  List<FriendshipRequest> _incoming = [];
  List<FriendshipRequest> _outgoing = [];
  String _friendsQuery = '';

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendsSearchController.dispose();
    super.dispose();
  }

  // ── Fetching ───────────────────────────────────────────────────────────────
  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    final response = await _api.request(
      endpoint: 'friendships',
      method: HttpMethod.get,
    );
    if (!mounted) return;
    if (response != null && response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      _friends = data
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setState(() => _loadingFriends = false);
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    final results = await Future.wait([
      _api.request(endpoint: 'friendships/incoming', method: HttpMethod.get),
      _api.request(endpoint: 'friendships/outgoing', method: HttpMethod.get),
    ]);
    if (!mounted) return;

    final inResponse = results[0];
    final outResponse = results[1];

    if (inResponse != null && inResponse.statusCode == 200) {
      final List<dynamic> data = jsonDecode(inResponse.body) as List<dynamic>;
      _incoming = data
          .map((e) => FriendshipRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (outResponse != null && outResponse.statusCode == 200) {
      final List<dynamic> data = jsonDecode(outResponse.body) as List<dynamic>;
      _outgoing = data
          .map((e) => FriendshipRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setState(() => _loadingRequests = false);
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _respondToRequest(String friendshipId, String action) async {
    final response = await _api.request(
      endpoint: 'friendships/$friendshipId/respond',
      method: HttpMethod.patch,
      queryParams: {'action': action},
    );
    if (!mounted) return;
    if (response != null && response.statusCode == 200) {
      await _loadRequests();
      if (action == 'ACCEPTED') await _loadFriends();
    } else {
      _showSnack('Nie udało się zaktualizować zaproszenia.');
    }
  }

  Future<void> _deleteFriendship(
    String friendshipId, {
    String? successMsg,
  }) async {
    final response = await _api.request(
      endpoint: 'friendships/$friendshipId',
      method: HttpMethod.delete,
    );
    if (!mounted) return;
    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 204)) {
      if (successMsg != null) _showSnack(successMsg);
      await Future.wait([_loadFriends(), _loadRequests()]);
    } else {
      _showSnack('Nie udało się wykonać operacji.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Add friend sheet ───────────────────────────────────────────────────────
  Future<void> _openAddFriendSheet() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFriendSheet(api: _api),
    );
    if (sent == true) {
      _showSnack('Wysłano zaproszenie.');
      await _loadRequests();
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Znajomi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.username(isDark),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.navActive(isDark),
              unselectedLabelColor: AppColors.navInactive(isDark),
              indicatorColor: AppColors.navActive(isDark),
              tabs: [
                const Tab(text: 'Znajomi'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaproszenia'),
                      if (_incoming.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navActive(isDark),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_incoming.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildFriendsTab(), _buildRequestsTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navActive(isDark),
        onPressed: _openAddFriendSheet,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_loadingFriends && _friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline,
        title: 'Brak znajomych',
        subtitle: 'Dodaj pierwszego znajomego przyciskiem poniżej.',
        isDark: isDark,
      );
    }

    final query = _friendsQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _friends
        : _friends
              .where((f) => f.displayName.toLowerCase().contains(query))
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _friendsSearchController,
            onChanged: (v) => setState(() => _friendsQuery = v),
            decoration: InputDecoration(
              hintText: 'Szukaj znajomego',
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.cardSubtitle(isDark),
              ),
              suffixIcon: _friendsQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.cardSubtitle(isDark),
                      ),
                      onPressed: () {
                        _friendsSearchController.clear();
                        setState(() => _friendsQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppColors.cardBg(isDark),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder(isDark)),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFriends,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      _EmptyState(
                        icon: Icons.search_off,
                        title: 'Brak wyników',
                        subtitle:
                            'Nie znaleziono znajomego o nazwie „$_friendsQuery”.',
                        isDark: isDark,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f = filtered[i];
                      return _FriendRow(
                        friend: f,
                        isDark: isDark,
                        onRemove: () => _confirmRemoveFriend(f),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_loadingRequests && _incoming.isEmpty && _outgoing.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_incoming.isEmpty && _outgoing.isEmpty) {
      return _EmptyState(
        icon: Icons.mail_outline,
        title: 'Brak zaproszeń',
        subtitle: 'Nie masz żadnych oczekujących zaproszeń.',
        isDark: isDark,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (_incoming.isNotEmpty) ...[
            _RequestsHeader(title: 'Przychodzące', isDark: isDark),
            const SizedBox(height: 8),
            for (final r in _incoming) ...[
              _IncomingRequestRow(
                request: r,
                isDark: isDark,
                onAccept: () => _respondToRequest(r.friendshipId, 'ACCEPTED'),
                onDecline: () => _respondToRequest(r.friendshipId, 'DECLINED'),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
          ],
          if (_outgoing.isNotEmpty) ...[
            _RequestsHeader(title: 'Wychodzące', isDark: isDark),
            const SizedBox(height: 8),
            for (final r in _outgoing) ...[
              _OutgoingRequestRow(
                request: r,
                isDark: isDark,
                onCancel: () => _deleteFriendship(
                  r.friendshipId,
                  successMsg: 'Anulowano zaproszenie.',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemoveFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć znajomego?'),
        content: Text(
          '${friend.displayName} zostanie usunięty z listy znajomych.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteFriendship(
        friend.friendshipId,
        successMsg: 'Usunięto znajomego.',
      );
    }
  }
}

String _formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'przed chwilą';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
  if (diff.inHours < 24) return '${diff.inHours} godz. temu';
  if (diff.inDays == 1) return 'wczoraj';
  if (diff.inDays < 7) return '${diff.inDays} dni temu';
  final d = dt.toLocal();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final bool isDark;
  final VoidCallback onRemove;

  const _FriendRow({
    required this.friend,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        border: Border.all(color: AppColors.cardBorder(isDark)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Avatar(displayName: friend.displayName, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friend.displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.cardTitle(isDark),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.person_remove_alt_1_outlined,
              color: AppColors.cardSubtitle(isDark),
              size: 20,
            ),
            tooltip: 'Usuń znajomego',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestRow extends StatelessWidget {
  final FriendshipRequest request;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestRow({
    required this.request,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        border: Border.all(color: AppColors.cardBorder(isDark)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Avatar(displayName: request.displayName, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardTitle(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Otrzymano ${_formatRelativeTime(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: AppColors.amountCurrency(isDark),
            ),
            tooltip: 'Akceptuj',
            onPressed: onAccept,
          ),
          IconButton(
            icon: const Icon(
              Icons.cancel_outlined,
              color: AppColors.amountNegative,
            ),
            tooltip: 'Odrzuć',
            onPressed: onDecline,
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestRow extends StatelessWidget {
  final FriendshipRequest request;
  final bool isDark;
  final VoidCallback onCancel;

  const _OutgoingRequestRow({
    required this.request,
    required this.isDark,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        border: Border.all(color: AppColors.cardBorder(isDark)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Avatar(displayName: request.displayName, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardTitle(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Wysłano ${_formatRelativeTime(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Anuluj')),
        ],
      ),
    );
  }
}

class _RequestsHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _RequestsHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.sectionTitle(isDark),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String displayName;
  final bool isDark;

  const _Avatar({required this.displayName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.avatarBg(isDark),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.avatarFg(isDark),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.cardSubtitle(isDark)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cardSubtitle(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Add friend bottom sheet
// ════════════════════════════════════════════════════════════════════════════

class _AddFriendSheet extends StatefulWidget {
  final ApiServiceRequest api;

  const _AddFriendSheet({required this.api});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _emailController = TextEditingController();
  bool _searching = false;
  bool _sending = false;
  UserSearchResult? _result;
  String? _error;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
    });
    final response = await widget.api.request(
      endpoint: 'users/search',
      method: HttpMethod.get,
      queryParams: {'email': email},
    );
    if (!mounted) return;
    setState(() => _searching = false);
    if (response == null) {
      setState(() => _error = 'Błąd połączenia.');
      return;
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() => _result = UserSearchResult.fromJson(data));
    } else if (response.statusCode == 404) {
      setState(
        () => _error = 'Nie znaleziono użytkownika z tym adresem email.',
      );
    } else {
      setState(() => _error = 'Błąd wyszukiwania (${response.statusCode}).');
    }
  }

  Future<void> _sendRequest() async {
    if (_result == null) return;
    setState(() => _sending = true);
    final response = await widget.api.request(
      endpoint: 'friendships/request',
      method: HttpMethod.post,
      body: {'receiverId': _result!.id},
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (response != null && response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = response != null
            ? 'Nie udało się wysłać zaproszenia (${response.statusCode}).'
            : 'Błąd połączenia.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sheetHandle(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dodaj znajomego',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cardTitle(isDark),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'adres@domena.pl',
              prefixIcon: const Icon(Icons.mail_outline),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg(isDark),
                border: Border.all(color: AppColors.cardBorder(isDark)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _Avatar(displayName: _result!.displayName, isDark: isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cardTitle(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _result!.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cardSubtitle(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _sendRequest,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Wyślij zaproszenie'),
            ),
          ],
        ],
      ),
    );
  }
}
