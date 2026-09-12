import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/models/enums/expense_splits_type.dart';
import 'package:settly_mobile/models/expenses/expense_member_item.dart';
import 'package:settly_mobile/models/expenses/expens_style.dart';
import 'package:settly_mobile/pages/expense_form_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/utils/category_label.dart';
import 'package:settly_mobile/utils/money_input.dart';
import 'package:settly_mobile/widgets/user_avatar.dart';
import '../models/expenses/expense_member.dart';
import '../services/api_service/api_service_request.dart';
import '../services/api_service/projects_service.dart';
import 'package:settly_mobile/utils/money_format.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final SingleExpense expense;
  const ExpenseDetailsPage({super.key, required this.expense});

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  bool _loading = true;
  String _splitLabel = '';
  ExpenseSplitsType _splitType = ExpenseSplitsType.EQUAL;
  List<ExpenseMember> _members = [];
  String? _projectName;

  /// Nazwa osoby, która wyłożyła pieniądze (właściciel wydatku). Uczestnik musi
  /// wiedzieć, komu oddać — z samych zielonych plakietek nie da się tego poznać.
  String? _payerName;
  final ApiServiceRequest _api = ApiServiceRequest();
  final ProjectsService _projectsService = ProjectsService();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  String? _currentUserId;

  /// Ustawione, gdy rozliczenie zmieniło się na tej stronie — wtedy przy
  /// powrocie oddajemy `true`, żeby lista się odświeżyła.
  bool _settlementChanged = false;

  bool get _isOwner =>
      _currentUserId != null && _currentUserId == widget.expense.ownerId;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final info = await AuthService().getUserInfo();
    if (!mounted) return;
    setState(() => _currentUserId = info?['sub'] as String?);
  }

  Future<void> _openEdit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(isDark: isDark, editExpense: widget.expense),
      ),
    );
    // The header shown here comes from the (immutable) passed expense, so after
    // a successful edit go back to the list, which reloads fresh data.
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  /// „Powtórz": otwiera formularz nowego wydatku wstępnie wypełniony tym
  /// wydatkiem (kwota, podział, pozycje; data = dziś). Po zapisie wracamy do
  /// listy z `true`, żeby pokazała świeżo utworzony wydatek.
  Future<void> _openRepeat() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(isDark: isDark, repeatExpense: widget.expense),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete(AppTexts texts) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(texts.expenseDeleteTitle),
        content: Text(texts.expenseDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(texts.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              texts.deleteAction,
              style: TextStyle(color: AppColors.amountNegative),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final resp = await _api.request(
      endpoint: 'expenses/${widget.expense.id}',
      method: HttpMethod.delete,
    );
    if (!mounted) return;
    if (resp != null && (resp.statusCode == 200 || resp.statusCode == 204)) {
      Navigator.of(context).pop(true); // back to the list, which refreshes
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(texts.expenseDeleteFailed)));
    }
  }

  @override
  void didUpdateWidget(ExpenseDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expense.id != widget.expense.id) {
      _loading = true;
      _members = [];
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final expenseId = widget.expense.id;
    if (expenseId == null) {
      _finishLoading();
      return;
    }

    await _loadProjectName();

    try {
      final splitMembers = await _fetchSplitMembers(expenseId);
      if (splitMembers.isEmpty) {
        _finishLoading();
        return;
      }

      final membersWithNames = await _enrichMembersWithNames(splitMembers);
      if (membersWithNames.isEmpty) {
        _finishLoading();
        return;
      }

      _payerName = await _resolvePayerName(membersWithNames);

      _splitType = ExpenseSplitsType.fromString(
        membersWithNames.first.splitType,
      );
      _splitLabel = _splitType.localizedLabel(AppTexts.of(context));

      if (_splitType != ExpenseSplitsType.BY_ITEM) {
        _members = membersWithNames;
        _finishLoading();
        return;
      }

      final productsByUser = await _loadByItemProducts(expenseId);
      _members = membersWithNames
          .map(
            (member) => member.copyWith(
              items: productsByUser[member.userId] ?? const [],
            ),
          )
          .toList();
    } catch (_) {}
    _finishLoading();
  }

  Future<void> _loadProjectName() async {
    final projectId = widget.expense.projectId;
    if (projectId == null) return;
    try {
      final project = await _projectsService.getProject(projectId);
      _projectName = project.name;
    } catch (_) {
      // Non-fatal: just don't show the project row.
    }
  }

  Future<List<ExpenseMember>> _fetchSplitMembers(String expenseId) async {
    final res = await _api.request(
      endpoint: 'expenses/$expenseId/splits',
      method: HttpMethod.get,
    );
    if (res?.statusCode != 200) return const [];
    return ExpenseMember.listFromJson(jsonDecode(res!.body));
  }

  Future<List<ExpenseMember>> _enrichMembersWithNames(
    List<ExpenseMember> members,
  ) {
    return Future.wait(
      members.map((m) async {
        final displayName = await _fetchUserDisplayName(m.userId);
        return m.copyWith(displayName: displayName);
      }),
    );
  }

  /// Właściciel prawie zawsze ma własny wiersz w podziale, więc nazwę bierzemy
  /// stamtąd. Gdyby go tam nie było (starsze dane), pytamy o niego wprost —
  /// lepiej jedno zapytanie więcej niż szczegóły bez informacji, komu oddać.
  Future<String?> _resolvePayerName(List<ExpenseMember> members) async {
    final ownerId = widget.expense.ownerId;
    if (ownerId == null) return null;
    for (final m in members) {
      if (m.userId == ownerId && m.displayName.isNotEmpty) return m.displayName;
    }
    return _fetchUserDisplayName(ownerId);
  }

  Future<String> _fetchUserDisplayName(String userId) async {
    final res = await _api.request(
      endpoint: 'users/$userId',
      method: HttpMethod.get,
    );
    if (res?.statusCode != 200) return 'Nieznany';
    return jsonDecode(res!.body)['displayName']?.toString() ?? 'Nieznany';
  }

  void _finishLoading() {
    if (mounted) setState(() => _loading = false);
  }

  Future<Map<String, List<ExpenseMemberItem>>> _loadByItemProducts(
    String expenseId,
  ) async {
    try {
      final itemsRes = await _api.request(
        endpoint: 'expenses/$expenseId/items',
        method: HttpMethod.get,
      );
      if (itemsRes?.statusCode != 200) return const {};

      final items = _extractList(jsonDecode(itemsRes!.body));
      final productsByUser = <String, List<ExpenseMemberItem>>{};

      final rowsByItemId = _groupItemRowsByItemId(items);
      for (final entry in rowsByItemId.entries) {
        await _appendByItemShares(
          itemId: entry.key,
          rows: entry.value,
          productsByUser: productsByUser,
        );
      }

      return productsByUser;
    } catch (_) {
      return const {};
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupItemRowsByItemId(
    List<dynamic> items,
  ) {
    final groupedByItemId = <String, List<Map<String, dynamic>>>{};
    for (final raw in items.whereType<Map<String, dynamic>>()) {
      final itemId = _readItemId(raw);
      if (itemId == null) continue;
      groupedByItemId
          .putIfAbsent(itemId, () => <Map<String, dynamic>>[])
          .add(raw);
    }
    return groupedByItemId;
  }

  Future<void> _appendByItemShares({
    required String itemId,
    required List<Map<String, dynamic>> rows,
    required Map<String, List<ExpenseMemberItem>> productsByUser,
  }) async {
    if (rows.isEmpty) return;

    final usersRes = await _api.request(
      endpoint: 'expenses/items/$itemId/users',
      method: HttpMethod.get,
    );
    if (usersRes?.statusCode != 200) return;

    final users = _extractList(jsonDecode(usersRes!.body));
    if (users.isEmpty) return;

    final assignedUserIds = _extractAssignedUserIds(users);
    if (assignedUserIds.isEmpty) return;

    // Kwoty czytamy z /users — tylko tam jest udział per osoba. Wiersz pozycji
    // (rows) nie ma ani userId, ani amount, więc mapa budowana z niego była
    // zawsze pusta i każdy produkt pokazywał się podzielony po równo, nawet gdy
    // udziały były ustawione ręcznie.
    final amountByUserId = _buildAmountByUserId(
      users.whereType<Map<String, dynamic>>().toList(),
    );
    final totalAmount = _readItemAmount(rows.first);
    final totalAmountValue = _tryParseAmount(totalAmount);
    final hasCompleteUserAmounts = _hasCompleteUserAmounts(
      assignedUserIds,
      amountByUserId,
    );
    final equalShareAmount =
        (!hasCompleteUserAmounts && totalAmountValue != null)
        ? _formatAmount(totalAmountValue / assignedUserIds.length)
        : null;

    final itemName = _readItemName(rows.first, fallbackItemId: itemId);
    for (final userId in assignedUserIds) {
      final userAmount = hasCompleteUserAmounts
          ? amountByUserId[userId]!
          : (equalShareAmount ?? amountByUserId[userId] ?? totalAmount);

      productsByUser
          .putIfAbsent(userId, () => <ExpenseMemberItem>[])
          .add(ExpenseMemberItem(name: itemName, amount: userAmount));
    }
  }

  Set<String> _extractAssignedUserIds(List<dynamic> users) {
    final ids = <String>{};
    for (final user in users.whereType<Map<String, dynamic>>()) {
      final id = _readUserId(user);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  /// Udział per osoba w jednym produkcie, z /expenses/items/{id}/users.
  ///
  /// Wiersze bez kwoty pomijamy zamiast zapisywać 0.00 — dzięki temu stare
  /// pozycje (sprzed kolumny `amount`) spadają na podział po równo, zamiast
  /// pokazywać zero.
  Map<String, String> _buildAmountByUserId(List<Map<String, dynamic>> rows) {
    final result = <String, String>{};
    for (final row in rows) {
      final userId = _readUserId(row);
      if (userId == null) continue;
      final amount = row['amount']?.toString();
      if (amount == null || amount.isEmpty) continue;
      result[userId] = normalizeMoney(amount);
    }
    return result;
  }

  bool _hasCompleteUserAmounts(
    Set<String> assignedUserIds,
    Map<String, String> amountByUserId,
  ) {
    return assignedUserIds.every(
      (id) => _tryParseAmount(amountByUserId[id]) != null,
    );
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map<String, dynamic>) return const [];

    const keys = ['data', 'content', 'items', 'results'];
    for (final key in keys) {
      final candidate = body[key];
      if (candidate is List) return candidate;
    }
    return const [];
  }

  String? _readItemId(Map<String, dynamic> item) {
    final id = item['id'] ?? item['itemId'] ?? item['expenseItemId'];
    final value = id?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String _readItemName(Map<String, dynamic> item, {String? fallbackItemId}) {
    final name = item['name'] ?? item['itemName'] ?? item['productName'];
    final value = name?.toString();
    if (value == null || value.isEmpty) {
      final shortId = (fallbackItemId != null && fallbackItemId.length >= 6)
          ? fallbackItemId.substring(0, 6)
          : fallbackItemId;
      return shortId == null ? 'Pozycja' : 'Pozycja $shortId';
    }
    return value;
  }

  String _readItemAmount(Map<String, dynamic> item) {
    final amount = item['amount'] ?? item['price'] ?? item['totalPrice'];
    final value = amount?.toString();
    if (value == null || value.isEmpty) return '0.00';
    // Dopełnij do 2 miejsc ("5.1" -> "5.10").
    return normalizeMoney(value);
  }

  String? _readUserId(Map<String, dynamic> user) {
    final id = user['userId'] ?? user['id'] ?? user['friendId'];
    final value = id?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  double? _tryParseAmount(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = widget.expense.style(isDark);

    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(texts.expenseDetailsTitle),
        // Oddaj informację, czy rozliczenie się zmieniło — lista to odświeży.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_settlementChanged),
        ),
        actions: [
          // "Powtórz" jest dla każdego, kto widzi wydatek (tworzy własny nowy);
          // edycja/usuwanie pozostają tylko dla właściciela.
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'repeat') _openRepeat();
              if (v == 'edit') _openEdit();
              if (v == 'delete') _confirmDelete(texts);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'repeat',
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(texts.repeatAction),
                  ],
                ),
              ),
              if (_isOwner)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(texts.editAction),
                    ],
                  ),
                ),
              if (_isOwner)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.amountNegative,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        texts.deleteAction,
                        style: TextStyle(color: AppColors.amountNegative),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(style, isDark),
            const SizedBox(height: 32),
            _infoRow(
              texts.expenseDetailsCategory,
              localizedCategoryLabel(widget.expense.category, texts),
              isDark,
            ),
            _infoRow(
              texts.expenseDetailsDate,
              widget.expense.date.toString().split(' ')[0],
              isDark,
            ),
            if (widget.expense.note.isNotEmpty)
              _infoRow(texts.expenseDetailsNote, widget.expense.note, isDark),
            if (_payerName != null)
              _infoRow(texts.expenseDetailsPaidByLabel, _payerName!, isDark),
            if (_projectName != null)
              _infoRow(texts.expenseDetailsProject, _projectName!, isDark),
            const Divider(height: 40),
            _buildSplitSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ExpenseStyle style, bool isDark) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: style.iconBg, shape: BoxShape.circle),
        child: Icon(style.icon, size: 40, color: style.iconColor),
      ),
      const SizedBox(height: 16),
      Text(
        formatMoneyWithBase(
          double.tryParse(widget.expense.totalAmount) ?? 0,
          widget.expense.currency,
          double.tryParse(widget.expense.baseAmount),
          widget.expense.baseCurrency,
        ),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.cardAmount(isDark),
        ),
      ),
      Text(
        widget.expense.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    ],
  );

  Widget _buildSplitSection(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final texts = AppTexts.of(context);

    final isByItem = _splitType == ExpenseSplitsType.BY_ITEM;
    final hasAnyProducts = _members.any((m) => m.items.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${texts.expenseDetailsSplitLabel}: $_splitLabel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.cardSubtitle(isDark),
          ),
        ),
        const SizedBox(height: 12),
        _buildOwedCallout(),
        ..._members.map((m) => _buildMemberTile(m, isDark, isByItem)),
        if (isByItem && !hasAnyProducts)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              texts.expenseDetailsNoData,
              style: TextStyle(color: AppColors.cardSubtitle(isDark)),
            ),
          ),
      ],
    );
  }

  /// Pasek „komu oddać" dla uczestnika, który jeszcze nie ma potwierdzonego
  /// udziału. Same plakietki tego nie mówią: udział właściciela i udział
  /// uczestnika, który już oddał, wyglądają identycznie, więc trzeci uczestnik
  /// nie wiedział, do kogo się zwrócić.
  Widget _buildOwedCallout() {
    final texts = AppTexts.of(context);
    final payer = _payerName;
    final myId = _currentUserId;
    if (payer == null || myId == null || _isOwner) {
      return const SizedBox.shrink();
    }

    ExpenseMember? mine;
    for (final m in _members) {
      if (m.userId == myId && m.userId != widget.expense.ownerId) {
        mine = m;
        break;
      }
    }
    // Rozliczony udział (albo brak udziału — np. członek projektu oglądający
    // cudzy wydatek) nie potrzebuje wskazówki, komu płacić.
    if (mine == null || mine.settled) return const SizedBox.shrink();

    final amount = '${mine.amount} ${widget.expense.currency}';
    final declared = mine.declaredPaid;
    final color = declared ? Colors.blue : AppColors.amountNegative;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            declared ? Icons.hourglass_top_rounded : Icons.arrow_forward_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              declared
                  ? texts.expenseDetailsAwaitingConfirm(payer)
                  : texts.expenseDetailsPayTo(amount, payer),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(ExpenseMember m, bool isDark, bool isByItem) {
    final displayAmount = isByItem && m.items.isNotEmpty
        ? m.items.fold<double>(
            0.0,
            (sum, item) =>
                sum +
                (double.tryParse(item.amount.replaceAll(',', '.')) ?? 0.0),
          )
        : double.tryParse(m.amount.replaceAll(',', '.')) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: UserAvatar(
            radius: 20,
            // ExpenseMember/ExpenseSplitResponse carry no avatarUrl yet — shows
            // initials. Add avatarUrl to the split response to show photos here.
            avatarUrl: null,
            name: m.displayName,
            backgroundColor: AppColors.avatarBg(isDark),
            foregroundColor: AppColors.avatarFg(isDark),
          ),
          title: Text(m.displayName),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${displayAmount.toStringAsFixed(2)} ${widget.expense.currency}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _settledChip(m),
            ],
          ),
        ),
        if (isByItem && m.items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: m.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: AppColors.cardSubtitle(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item.amount} ${widget.expense.currency}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  /// Chip stanu udziału. Rozliczenie ("Rozliczone") to wyłącznie słowo
  /// właściciela — potwierdzenie, że pieniądze dotarły. Uczestnik może jedynie
  /// ZGŁOSIĆ zapłatę ("Zgłoszono") — sugestię, którą właściciel widzi jako
  /// "Zgłasza zapłatę" i potwierdza tapnięciem.
  /// Własny udział właściciela nie podlega rozliczeniu (opłacony z definicji);
  /// potwierdzonego rozliczenia uczestnik nie może już cofnąć.
  Widget _settledChip(ExpenseMember m) {
    final texts = AppTexts.of(context);

    final isOwnersShare = m.userId == widget.expense.ownerId;
    final isOwnShare = !isOwnersShare && m.userId == _currentUserId;
    final declared = !m.settled && m.declaredPaid;

    // Wiersz właściciela dostaje własny kolor i etykietę. Wcześniej nosił to
    // samo zielone „Rozliczone" co uczestnik, który już oddał — więc z listy
    // nie dało się wyczytać, kto wyłożył pieniądze i komu się należy.
    final color = isOwnersShare
        ? AppColors.amountCurrency(
            Theme.of(context).brightness == Brightness.dark,
          )
        : m.settled
        ? Colors.green
        : declared
        ? Colors.blue
        : Colors.orange;

    final String label;
    if (isOwnersShare) {
      label = texts.expenseDetailsPayerChip;
    } else if (m.settled) {
      label = texts.expenseDetailsSettled;
    } else if (declared) {
      label = _isOwner
          ? texts.expenseDetailsDeclaresPaid
          : texts.expenseDetailsDeclared;
    } else {
      label = texts.expenseDetailsToPay;
    }

    // Właściciel rozlicza/cofa każdego uczestnika; uczestnik zgłasza zapłatę
    // własnego udziału lub wycofuje zgłoszenie — dopóki nie jest rozliczony.
    final VoidCallback? onTap;
    final IconData? icon;
    if (m.splitId == null || isOwnersShare) {
      onTap = null;
      icon = null;
    } else if (_isOwner) {
      if (m.settled) {
        onTap = () => _setMemberState(m, false);
        icon = Icons.undo_rounded;
      } else {
        onTap = () => _setMemberState(m, true);
        icon = Icons.check_rounded;
      }
    } else if (isOwnShare && !m.settled) {
      onTap = () => _setMemberState(m, !m.declaredPaid);
      icon = m.declaredPaid ? Icons.undo_rounded : Icons.check_rounded;
    } else {
      onTap = null;
      icon = null;
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: onTap != null
            ? Border.all(color: color.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 3),
            Icon(icon, size: 11, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }

  /// Jedno wywołanie API, dwa znaczenia (patrz backend): właściciel naprawdę
  /// (nie)rozlicza udział, uczestnik jedynie zgłasza/wycofuje zapłatę.
  Future<void> _setMemberState(ExpenseMember m, bool target) async {
    final expenseId = widget.expense.id;
    final splitId = m.splitId;
    if (expenseId == null || splitId == null) return;

    final texts = AppTexts.of(context);

    final result = await _expenseRepo.setSplitSettled(
      expenseId: expenseId,
      splitId: splitId,
      settled: target,
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
      final i = _members.indexOf(m);
      if (i != -1) {
        _members[i] = _isOwner
            // Rozliczenie zeruje zgłoszenie (tak samo robi backend).
            ? m.copyWith(settled: target, declaredPaid: false)
            : m.copyWith(declaredPaid: target);
      }
      _settlementChanged = true; // lista musi się odświeżyć po powrocie
    });
  }

  Widget _infoRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.cardSubtitle(isDark))),
        const SizedBox(width: 16),
        // Flexible + right-align so long notes wrap instead of overflowing.
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
