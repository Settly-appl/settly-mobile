import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/models/friend_balance.dart';
import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/pages/expense_form_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/api_service/balances_service.dart';
import 'package:settly_mobile/services/api_service/projects_service.dart';
import 'package:settly_mobile/services/auth_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _service = ProjectsService();
  final _balancesService = BalancesService();
  final _api = ApiServiceRequest();

  bool _loading = true;
  String? _error;
  Project? _project;
  List<ProjectMember> _members = [];
  List<FriendBalance> _balances = [];
  String? _currentUserId;
  final Set<String> _settling = {};

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool get _isOwner =>
      _project?.ownerId != null && _project!.ownerId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final texts = AppTexts.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userInfo = await AuthService().getUserInfo();
      final results = await Future.wait([
        _service.getProject(widget.projectId),
        _service.getMembers(widget.projectId),
        _balancesService.getBalances(projectId: widget.projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _currentUserId = userInfo?['sub'] as String?;
        _project = results[0] as Project;
        _members = results[1] as List<ProjectMember>;
        _balances = results[2] as List<FriendBalance>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = texts.projectRetryError;
        _loading = false;
      });
    }
  }

  void _toast(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _settle(FriendBalance balance) async {
    final texts = AppTexts.of(context);
    setState(() => _settling.add(balance.userId));
    try {
      await _balancesService.settleUp(
        debtorUserId: balance.userId,
        projectId: widget.projectId,
      );
      _toast(
        texts.balancePaidOut
            .replaceAll(
              '{amount}',
              '${balance.absAmount.toStringAsFixed(2)} zł',
            )
            .replaceAll('{name}', balance.label),
        color: AppColors.amountPositive,
      );
      await _load();
    } catch (_) {
      _toast(texts.settleFailedError);
    } finally {
      if (mounted) setState(() => _settling.remove(balance.userId));
    }
  }

  Future<void> _addMember() async {
    final texts = AppTexts.of(context);
    List<Friend> friends;
    try {
      final res = await _api.request(
        endpoint: 'friendships',
        method: HttpMethod.get,
      );
      if (res == null || res.statusCode != 200) {
        _toast(texts.friendsOperationFailed);
        return;
      }
      friends = (jsonDecode(res.body) as List<dynamic>)
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _toast(texts.friendsOperationFailed);
      return;
    }

    final memberIds = _members.map((m) => m.userId).toSet();
    final candidates = friends
        .where((f) => !memberIds.contains(f.userId))
        .toList();

    if (!mounted) return;
    final picked = await showModalBottomSheet<Friend>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.scaffold(isDark),
      builder: (_) => _FriendPickerSheet(friends: candidates, isDark: isDark),
    );
    if (picked == null) return;

    try {
      await _service.addMember(widget.projectId, picked.userId);
      _toast('Dodano ${picked.displayName}', color: AppColors.amountPositive);
      await _load();
    } catch (_) {
      _toast(texts.projectAddMemberFailed);
    }
  }

  Future<void> _removeMember(ProjectMember member) async {
    final texts = AppTexts.of(context);
    final ok = await _confirm(
      texts.projectDeleteMenu,
      '${member.label} ${texts.friendsDeleteFriendSubtitle}',
      confirmLabel: texts.deleteAction,
      danger: true,
    );
    if (ok != true) return;
    try {
      await _service.removeMember(widget.projectId, member.userId);
      await _load();
    } catch (_) {
      _toast(texts.projectRemoveMemberFailed);
    }
  }

  Future<void> _toggleSettled() async {
    final project = _project;
    if (project == null) return;
    final newStatus = project.isSettled ? 'ACTIVE' : 'SETTLED';
    final texts = AppTexts.of(context);
    try {
      await _service.updateProject(widget.projectId, status: newStatus);
      await _load();
    } catch (_) {
      _toast(texts.projectStatusFailed);
    }
  }

  Future<void> _rename() async {
    final texts = AppTexts.of(context);
    final controller = TextEditingController(text: _project?.name ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(texts.projectRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(texts.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(texts.saveAction),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await _service.updateProject(widget.projectId, name: newName);
      await _load();
    } catch (_) {
      _toast(texts.projectRenameFailed);
    }
  }

  Future<void> _deleteProject() async {
    final texts = AppTexts.of(context);
    final ok = await _confirm(
      texts.projectDeleteTitle,
      'This action cannot be undone.',
      confirmLabel: texts.deleteAction,
      danger: true,
    );
    if (ok != true) return;
    try {
      await _service.deleteProject(widget.projectId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast(texts.projectDeleteFailed);
    }
  }

  Future<void> _leaveProject() async {
    final texts = AppTexts.of(context);
    final ok = await _confirm(
      texts.projectLeaveTitle,
      'You will no longer see this project.',
      confirmLabel: texts.projectLeaveConfirm,
      danger: true,
    );
    if (ok != true) return;
    try {
      await _service.leaveProject(widget.projectId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast(texts.projectLeaveFailed);
    }
  }

  Future<bool?> _confirm(
    String title,
    String message, {
    required String confirmLabel,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.amountNegative,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          _project?.name ?? texts.projectsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(isDark),
          ),
        ),
        actions: [
          if (!_loading && _project != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'rename':
                    _rename();
                  case 'toggle':
                    _toggleSettled();
                  case 'delete':
                    _deleteProject();
                  case 'leave':
                    _leaveProject();
                }
              },
              itemBuilder: (_) => [
                if (_isOwner) ...[
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(texts.projectRenameMenu),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      _project!.isSettled
                          ? texts.projectToggleActive
                          : texts.projectToggleSettled,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(texts.projectDeleteMenu),
                  ),
                ] else
                  PopupMenuItem(
                    value: 'leave',
                    child: Text(texts.projectLeaveMenu),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: (_loading || _project == null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExpense,
              backgroundColor: AppColors.avatarFg(isDark),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                texts.projectAddExpenseButton,
                style: const TextStyle(color: Colors.white),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Future<void> _addExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(isDark: isDark, initialProjectId: widget.projectId),
      ),
    );
    _load();
  }

  Widget _buildBody() {
    final texts = AppTexts.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _project == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.cardSubtitle(isDark),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? texts.projectNotFound,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cardTitle(isDark)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _load,
                  child: Text(texts.retryAction),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_project!.description != null &&
            _project!.description!.isNotEmpty) ...[
          Text(
            _project!.description!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cardSubtitle(isDark),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Balances ──────────────────────────────────────────────────────
        _sectionTitle(texts.projectBalanceSection),
        const SizedBox(height: 8),
        if (_balances.isEmpty)
          _hintCard(texts.projectNoBalancesLabel)
        else
          ..._balances.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BalanceRow(
                balance: b,
                isDark: isDark,
                settling: _settling.contains(b.userId),
                onSettle: () => _settle(b),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // ── Members ───────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Uczestnicy (${_members.length})'),
            if (_isOwner)
              TextButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: Text(texts.projectAddMemberButton),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._members.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberRow(
              member: m,
              isDark: isDark,
              canRemove: _isOwner && !m.owner,
              onRemove: () => _removeMember(m),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.sectionTitle(isDark),
    ),
  );

  Widget _hintCard(String text) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.cardBg(isDark),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder(isDark)),
    ),
    padding: const EdgeInsets.all(14),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle(isDark)),
    ),
  );
}

class _BalanceRow extends StatelessWidget {
  final FriendBalance balance;
  final bool isDark;
  final bool settling;
  final VoidCallback onSettle;

  const _BalanceRow({
    required this.balance,
    required this.isDark,
    required this.settling,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final color = balance.owesYou
        ? AppColors.amountPositive
        : AppColors.amountNegative;
    final sign = balance.owesYou ? '+' : '-';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              balance.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.cardTitle(isDark),
              ),
            ),
          ),
          Text(
            '$sign${balance.absAmount.toStringAsFixed(2)} zł',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (balance.owesYou) ...[
            const SizedBox(width: 10),
            settling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Oznacz jako zapłacone',
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.amountPositive,
                    ),
                    onPressed: onSettle,
                  ),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ProjectMember member;
  final bool isDark;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MemberRow({
    required this.member,
    required this.isDark,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.avatarBg(isDark),
            backgroundImage:
                (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                ? Text(
                    member.initials,
                    style: TextStyle(
                      color: AppColors.avatarFg(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.cardTitle(isDark),
              ),
            ),
          ),
          if (member.owner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.avatarBg(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                texts.projectOwnerLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.avatarFg(isDark),
                ),
              ),
            ),
          if (canRemove)
            IconButton(
              tooltip: texts.deleteAction,
              icon: Icon(
                Icons.remove_circle_outline,
                color: AppColors.amountNegative,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _FriendPickerSheet extends StatelessWidget {
  final List<Friend> friends;
  final bool isDark;

  const _FriendPickerSheet({required this.friends, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              texts.projectAddMemberTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.username(isDark),
              ),
            ),
            const SizedBox(height: 12),
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  texts.projectAllFriendsAlready,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cardSubtitle(isDark)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (_, i) {
                    final f = friends[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.avatarBg(isDark),
                        backgroundImage:
                            (f.avatarUrl != null && f.avatarUrl!.isNotEmpty)
                            ? NetworkImage(f.avatarUrl!)
                            : null,
                        child: (f.avatarUrl == null || f.avatarUrl!.isEmpty)
                            ? Text(
                                f.displayName.isNotEmpty
                                    ? f.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppColors.avatarFg(isDark),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        f.displayName,
                        style: TextStyle(color: AppColors.cardTitle(isDark)),
                      ),
                      onTap: () => Navigator.of(context).pop(f),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
