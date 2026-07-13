import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:settly_mobile/utils/web_platform.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:settly_mobile/const/api_url.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:settly_mobile/models/expenses/item_draft.dart';
import 'package:settly_mobile/models/expenses/single_expense.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/api_service/projects_service.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/utils/money_input.dart';
import 'package:settly_mobile/widgets/user_avatar.dart';

class ExpenseFormPage extends StatefulWidget {
  final bool isDark;
  final String? initialProjectId;
  final String? initialCategory;
  final String? initialCurrency;
  final double? initialAmount;
  final List<String> initialSelectedFriendIds;
  final SplitType? initialSplitType;
  final String? initialReceiptImagePath;
  final List<Map<String, dynamic>>? initialReceiptItems;

  /// When set, the form edits this existing expense (PUT) instead of creating a
  /// new one. Its splits/items are loaded and prefilled.
  final SingleExpense? editExpense;

  const ExpenseFormPage({
    super.key,
    required this.isDark,
    this.initialProjectId,
    this.initialCategory,
    this.initialCurrency,
    this.initialAmount,
    this.initialSelectedFriendIds = const [],
    this.initialSplitType,
    this.initialReceiptImagePath,
    this.initialReceiptItems,
    this.editExpense,
  });

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _CategoryOption {
  final String id;
  final IconData icon;
  final Color color;

  const _CategoryOption(this.id, this.icon, this.color);

  String label(AppTexts texts) {
    switch (id) {
      case 'shopping':
        return texts.expensesLabelShopping;
      case 'food':
        return texts.expensesLabelFood;
      case 'transport':
        return texts.expensesLabelTransport;
      case 'entertainment':
        return texts.categoryEntertainmentLabel;
      case 'health':
        return texts.categoryHealthLabel;
      default:
        return texts.expensesLabelOther;
    }
  }
}

const List<_CategoryOption> _kCategories = [
  _CategoryOption('shopping', Icons.shopping_bag, Colors.orange),
  _CategoryOption('food', Icons.restaurant, Colors.red),
  _CategoryOption('transport', Icons.directions_car, Colors.blue),
  _CategoryOption('entertainment', Icons.movie, Colors.purple),
  _CategoryOption('health', Icons.medical_services, Colors.green),
  _CategoryOption('others', Icons.more_horiz, Colors.grey),
];

const String _kNoProject = '__none__';

const List<Map<String, String>> _kCurrencies = [
  {'code': 'PLN', 'symbol': 'zł', 'name': 'Złoty polski'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'USD', 'symbol': '\$', 'name': 'Dolar amerykański'},
  {'code': 'GBP', 'symbol': '£', 'name': 'Funt brytyjski'},
];

class _ExpenseFormPageState extends State<ExpenseFormPage>
    with WidgetsBindingObserver {
  static const String _receiptScanEndpoint = 'ai';

  final _api = ApiServiceRequest();
  final _imagePicker = ImagePicker();
  double _lastBottomInset = 0;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  _CategoryOption? _selectedCategory;
  String _selectedCurrency = 'PLN';

  final _projectsService = ProjectsService();
  List<Project> _projects = [];
  String? _selectedProjectId;

  bool _loadingFriends = true;
  List<Friend> _availableFriends = [];
  final Set<String> _selectedFriendIds = {};

  String? _currentUserId;
  String _currentUserDisplayName = 'Ty';
  String? _currentUserAvatarUrl;

  String? _editExpenseId; // non-null while editing an existing expense
  bool get _isEditing => _editExpenseId != null;

  SplitType _splitType = SplitType.equal;
  String? _amountBeforeByItems;

  final Map<String, TextEditingController> _customAmountControllers = {};
  // Udział właściciela w podziale CUSTOM (właściciel jest po prostu jednym z
  // wierszy listy uczestników).
  final TextEditingController _ownerAmountController = TextEditingController(
    text: '0.00',
  );
  // Kolejność uczestników podziału CUSTOM (właściciel + znajomi). Edycja wiersza
  // „zamraża" ten i wszystkie powyżej, a resztę rozdziela równo między wiersze
  // poniżej. Kolejność można zmieniać przeciąganiem.
  final List<String> _customOrder = [];
  bool _recomputingCustom = false; // zabezpieczenie przed rekurencją

  final List<ItemDraft> _items = [];
  int _itemAutoId = 0;
  final Set<String> _selectedItemIds = {};
  bool _itemSelectionMode = false;

  bool _saving = false;
  bool _scanningReceipt = false;
  bool _initialReceiptScanStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _amountController.addListener(_onAmountChanged);
    _selectedProjectId = widget.initialProjectId;

    if (widget.initialSelectedFriendIds.isNotEmpty) {
      _selectedFriendIds.addAll(widget.initialSelectedFriendIds);
    }
    if (widget.initialSplitType != null) {
      _splitType = widget.initialSplitType!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialCurrency != null) {
      _selectedCurrency = widget.initialCurrency!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = _kCategories.firstWhere(
        (cat) => cat.id == widget.initialCategory,
        orElse: () => _kCategories.first,
      );
    }
    // Edit mode: prefill the header from the existing expense; splits/items are
    // loaded asynchronously once the current user + friends are known.
    final edit = widget.editExpense;
    if (edit != null) {
      _editExpenseId = edit.id;
      _placeController.text = edit.name;
      _noteController.text = edit.note;
      _amountController.text = _cleanAmount(edit.totalAmount);
      _selectedCurrency = edit.currency;
      _selectedDate = edit.date;
      _selectedProjectId = edit.projectId;
      _selectedCategory = _kCategories.firstWhere(
        (c) => c.id == edit.category,
        orElse: () => _kCategories.last,
      );
    }

    if (_splitType == SplitType.byItems) {
      _amountBeforeByItems = _amountController.text;
    }

    _bootstrap();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartInitialReceiptScan();
    });
  }

  // Loads the base data, then (in edit mode) prefills splits/items — which needs
  // the current user id and friends to be resolved first.
  Future<void> _bootstrap() async {
    await Future.wait([_loadCurrentUser(), _loadFriends()]);
    _loadProjects();
    if (widget.editExpense != null) await _prefillSplitsAndItems();
  }

  static String _cleanAmount(String raw) {
    final v = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    return v == null ? '' : v.toStringAsFixed(2);
  }

  SplitType _splitTypeFromApi(String? s) {
    switch (s) {
      case 'CUSTOM':
        return SplitType.custom;
      case 'BY_ITEM':
        return SplitType.byItems;
      default:
        return SplitType.equal;
    }
  }

  // Loads the existing split (type, participants, custom amounts) and, for
  // BY_ITEM, the items and their assignees, into the form for editing.
  Future<void> _prefillSplitsAndItems() async {
    final id = _editExpenseId;
    if (id == null) return;

    final splitsResp = await _api.request(
      endpoint: 'expenses/$id/splits',
      method: HttpMethod.get,
    );
    List<dynamic> splits = const [];
    if (splitsResp != null && splitsResp.statusCode == 200) {
      splits = jsonDecode(splitsResp.body) as List<dynamic>;
    }

    if (splits.isNotEmpty) {
      final type = _splitTypeFromApi(splits.first['splitType'] as String?);
      final friendIds = <String>[
        for (final s in splits)
          if ((s['userId'] as String?) != null && s['userId'] != _currentUserId)
            s['userId'] as String,
      ];
      if (!mounted) return;
      setState(() {
        _splitType = type;
        _selectedFriendIds
          ..clear()
          ..addAll(friendIds);
      });
      // Establish the participant order + controllers, then set real amounts.
      _syncCustomControllersToEqualFriends();
      if (type == SplitType.custom) {
        _recomputingCustom = true;
        for (final s in splits) {
          final uid = s['userId'] as String?;
          final amt = (s['amount'] as num?)?.toDouble();
          if (uid != null && amt != null) {
            _ctrlFor(uid).text = amt.toStringAsFixed(2);
          }
        }
        _recomputingCustom = false;
      }
    }

    if (_splitType == SplitType.byItems) {
      final itemsResp = await _api.request(
        endpoint: 'expenses/$id/items',
        method: HttpMethod.get,
      );
      if (itemsResp != null && itemsResp.statusCode == 200) {
        final drafts = <ItemDraft>[];
        for (final it in jsonDecode(itemsResp.body) as List<dynamic>) {
          final itemId = it['id']?.toString();
          final assignees = <String>{};
          if (itemId != null) {
            final usersResp = await _api.request(
              endpoint: 'expenses/items/$itemId/users',
              method: HttpMethod.get,
            );
            if (usersResp != null && usersResp.statusCode == 200) {
              for (final u in jsonDecode(usersResp.body) as List<dynamic>) {
                final uid = (u['userId'] ?? u['id'])?.toString();
                if (uid != null) assignees.add(uid);
              }
            }
          }
          drafts.add(
            ItemDraft(
              id: 'item_${_itemAutoId++}',
              name: (it['name'] as String?) ?? '',
              price: (it['price'] as num?)?.toDouble() ?? 0.0,
              assigneeIds: assignees,
            ),
          );
        }
        if (!mounted) return;
        setState(() {
          _items
            ..clear()
            ..addAll(drafts);
        });
        _syncAmountFromItems();
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectsService.getMyProjects();
      if (mounted) setState(() => _projects = projects);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _placeController.dispose();
    _noteController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    _ownerAmountController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset == 0 && _lastBottomInset > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _lastBottomInset = bottomInset;
    });
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadCurrentUser() async {
    final info = await AuthService().getUserInfo();
    if (!mounted || info == null) return;
    setState(() {
      _currentUserId = info['sub'] as String?;
      _currentUserDisplayName =
          (info['given_name'] as String?) ??
          (info['name'] as String?) ??
          (info['preferred_username'] as String?) ??
          'Ty';
      final picture = info['picture'] as String?;
      _currentUserAvatarUrl = (picture != null && picture.isNotEmpty)
          ? picture
          : null;
    });
    _maybeStartInitialReceiptScan();
  }

  Future<void> _loadFriends() async {
    final response = await _api.request(
      endpoint: 'friendships',
      method: HttpMethod.get,
    );
    if (!mounted) return;
    if (response != null && response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      _availableFriends = data
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setState(() => _loadingFriends = false);
  }

  // ── Math ──────────────────────────────────────────────────────────────────

  double get _totalAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

  List<String> get _participantIdsIncludingMe {
    final ids = <String>[];
    if (_currentUserId != null) ids.add(_currentUserId!);
    for (final id in _selectedFriendIds) {
      if (id != _currentUserId) ids.add(id);
    }
    return ids;
  }

  Map<String, double> _equalAmounts() {
    final ids = _participantIdsIncludingMe;
    if (ids.isEmpty || _totalAmount <= 0) {
      return {for (final id in ids) id: 0.0};
    }
    final cents = (_totalAmount * 100).round();
    final base = cents ~/ ids.length;
    final remainder = cents - base * ids.length;
    final result = <String, double>{};
    for (var i = 0; i < ids.length; i++) {
      final extra = i == 0 ? remainder : 0;
      result[ids[i]] = (base + extra) / 100.0;
    }
    return result;
  }

  double _parseCtrl(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;


  double get _itemsSum {
    double s = 0;
    for (final item in _items) {
      s += item.price;
    }
    return s;
  }

  void _onAmountChanged() {
    if (_splitType == SplitType.equal) {
      _syncCustomControllersToEqualFriends();
    } else if (_splitType == SplitType.custom) {
      // Zmiana kwoty całkowitej → różnicę wchłania dolny wiersz.
      _cascadeBottomAbsorb();
    }
    setState(() {});
  }

  // Kontroler danego uczestnika (właściciel korzysta z osobnego pola).
  TextEditingController _ctrlFor(String id) {
    if (id == _currentUserId) return _ownerAmountController;
    return _customAmountControllers.putIfAbsent(
      id,
      () => TextEditingController(text: '0.00'),
    );
  }

  // Utrzymuje _customOrder w zgodzie z właścicielem + zaznaczonymi znajomymi,
  // zachowując kolejność ustawioną przez użytkownika (przeciąganiem).
  void _ensureCustomOrder() {
    final ownerId = _currentUserId;
    _customOrder.removeWhere(
      (id) => id != ownerId && !_selectedFriendIds.contains(id),
    );
    if (ownerId != null && !_customOrder.contains(ownerId)) {
      _customOrder.insert(0, ownerId);
    }
    for (final id in _selectedFriendIds) {
      if (!_customOrder.contains(id)) _customOrder.add(id);
    }
  }

  // Suma wszystkich udziałów (właściciel + znajomi).
  double get _customParticipantsTotal {
    double s = 0;
    for (final id in _customOrder) {
      s += _parseCtrl(_ctrlFor(id));
    }
    return s;
  }

  void _syncCustomControllersToEqualFriends() {
    _ensureCustomOrder();
    final equal = _equalAmounts();
    _recomputingCustom = true;
    for (final id in _customOrder) {
      final amt = (equal[id] ?? 0.0).toStringAsFixed(2);
      final c = _ctrlFor(id);
      if (c.text != amt) c.text = amt;
    }
    _recomputingCustom = false;
    _customAmountControllers.removeWhere((id, c) {
      if (!_selectedFriendIds.contains(id)) {
        c.dispose();
        return true;
      }
      return false;
    });
  }

  // Uczestnik zmienił swój udział → zamroź wiersze 0..index, a resztę rozdziel
  // równo między wiersze poniżej.
  void _onParticipantEdited(String id) {
    if (_recomputingCustom) return;
    final index = _customOrder.indexOf(id);
    if (index >= 0) _cascadeFromIndex(index);
    setState(() {});
  }

  // Zmiana kwoty całkowitej → różnicę wchłania dolny wiersz.
  void _cascadeBottomAbsorb() {
    if (_customOrder.length >= 2) _cascadeFromIndex(_customOrder.length - 2);
  }

  // Rozdziela resztę (total − suma wierszy 0..index) równo między wiersze
  // poniżej index. Ujemna reszta jest zerowana — walidacja zablokuje zapis.
  void _cascadeFromIndex(int index) {
    final belowCount = _customOrder.length - (index + 1);
    if (belowCount <= 0) return; // nic poniżej, nie ma czego rozdzielać

    double fixedSum = 0;
    for (var k = 0; k <= index; k++) {
      fixedSum += _parseCtrl(_ctrlFor(_customOrder[k]));
    }
    final remainderCents = ((_totalAmount - fixedSum) * 100).round();
    final safeCents = remainderCents < 0 ? 0 : remainderCents;
    final base = safeCents ~/ belowCount;
    final extra = safeCents - base * belowCount; // grosze reszty → pierwszy poniżej

    _recomputingCustom = true;
    for (var k = index + 1; k < _customOrder.length; k++) {
      final cents = base + (k == index + 1 ? extra : 0);
      final text = (cents / 100.0).toStringAsFixed(2);
      final c = _ctrlFor(_customOrder[k]);
      if (c.text != text) c.text = text;
    }
    _recomputingCustom = false;
  }

  void _onReorderParticipants(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final id = _customOrder.removeAt(oldIndex);
      _customOrder.insert(newIndex, id);
    });
  }

  void _toggleFriend(String userId) {
    setState(() {
      if (_selectedFriendIds.contains(userId)) {
        _selectedFriendIds.remove(userId);
        for (final item in _items) {
          item.assigneeIds.remove(userId);
        }
      } else {
        _selectedFriendIds.add(userId);
      }
      _syncCustomControllersToEqualFriends();
    });

    if (_selectedFriendIds.isEmpty && _splitType == SplitType.byItems) {
      setState(() {
        _splitType = SplitType.equal;
        if (_amountBeforeByItems != null) {
          _amountController.text = _amountBeforeByItems!;
        }
        _selectedItemIds.clear();
        _itemSelectionMode = false;
      });
    }
  }

  void _setSplitType(SplitType t) {
    setState(() {
      final wasByItems = _splitType == SplitType.byItems;
      final enteringByItems = t == SplitType.byItems && !wasByItems;
      final leavingByItems = wasByItems && t != SplitType.byItems;

      if (enteringByItems) _amountBeforeByItems = _amountController.text;

      _splitType = t;
      if (t == SplitType.custom) _syncCustomControllersToEqualFriends();
      if (t == SplitType.byItems) _syncAmountFromItems();
      if (leavingByItems && _amountBeforeByItems != null) {
        _amountController.text = _amountBeforeByItems!;
      }
      if (leavingByItems) _selectedItemIds.clear();
    });
  }

  void _syncAmountFromItems() {
    final text = _itemsSum.toStringAsFixed(2);
    if (_amountController.text != text) _amountController.text = text;
  }

  void _addItem() {
    setState(() {
      _items.add(
        ItemDraft(
          id: 'item_${_itemAutoId++}',
          assigneeIds: {
            if (_currentUserId != null) _currentUserId!,
            ..._selectedFriendIds,
          },
        ),
      );
      if (_splitType == SplitType.byItems) _syncAmountFromItems();
    });
  }

  void _enterItemSelectionMode(String itemId) {
    setState(() {
      _itemSelectionMode = true;
      _selectedItemIds.add(itemId);
    });
  }

  void _exitItemSelectionMode({bool clearSelection = true}) {
    setState(() {
      _itemSelectionMode = false;
      if (clearSelection) _selectedItemIds.clear();
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _toggleSelectAllItems() {
    setState(() {
      if (_selectedItemIds.length == _items.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds
          ..clear()
          ..addAll(_items.map((e) => e.id));
      }
    });
  }

  Future<void> _removeSelectedItems() async {
    if (_selectedItemIds.isEmpty) return;
    final ids = Set<String>.from(_selectedItemIds);
    setState(() {
      _items.removeWhere((i) => ids.contains(i.id));
      _selectedItemIds.clear();
      if (_items.isEmpty) _itemSelectionMode = false;
      if (_splitType == SplitType.byItems) _syncAmountFromItems();
    });
  }

  Future<void> _removeAllItems() async {
    if (_items.isEmpty) return;
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(texts.clearAllItemsDialogTitle),
        content: Text(texts.clearAllItemsDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(texts.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(texts.deleteAllItems),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _items.clear();
        _selectedItemIds.clear();
        _itemSelectionMode = false;
        if (_splitType == SplitType.byItems) _syncAmountFromItems();
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  String? _blockingError() {
    final texts = AppTexts.of(context);
    if (_currentUserId == null) return texts.errorNoAccount;
    if (_totalAmount <= 0) return texts.errorAmountZero;
    if (_selectedCategory == null) return texts.errorNoCategory;

    if (_selectedFriendIds.isEmpty) return null;

    if (_splitType == SplitType.custom) {
      // All shares (owner + friends) must add up to the total, and be >= 0.
      // 0.005 = float slack. A share of exactly 0 is allowed.
      if ((_customParticipantsTotal - _totalAmount).abs() > 0.005) {
        return texts.errorFriendsExceedTotal;
      }
      if (_customOrder.any((id) => _parseCtrl(_ctrlFor(id)) < 0)) {
        return texts.errorNegativeAmounts;
      }
    }

    if (_splitType == SplitType.byItems) {
      if (_items.isEmpty) return texts.errorNoItems;
      for (final item in _items) {
        if (item.name.trim().isEmpty) return texts.errorItemNoName;
        if (item.price <= 0) return texts.errorItemNoPrice;
        if (item.assigneeIds.isEmpty) {
          return texts.errorItemNoAssignee.replaceAll('{name}', item.name);
        }
      }
      final assigned = <String>{for (final i in _items) ...i.assigneeIds};
      for (final friendId in _selectedFriendIds) {
        if (!assigned.contains(friendId)) {
          final name = _availableFriends
              .firstWhere(
                (f) => f.userId == friendId,
                orElse: () => Friend(
                  friendshipId: '',
                  userId: friendId,
                  displayName: '?',
                ),
              )
              .displayName;
          return texts.errorFriendNotAssigned.replaceAll('{name}', name);
        }
      }
    }
    return null;
  }

  bool get _canSave => _blockingError() == null && !_saving;

  Future<void> _save() async {
    final texts = AppTexts.of(context);
    final err = _blockingError();
    if (err != null) {
      _snack(err);
      return;
    }

    setState(() => _saving = true);
    try {
      final req = CreateExpenseRequest(
        shop: _placeController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        currency: _selectedCurrency,
        category: _selectedCategory!.id,
        totalAmount: _totalAmount,
        date: _selectedDate,
        projectId: _selectedProjectId,
      );
      final String expenseId;
      if (_isEditing) {
        final resp = await _api.request(
          endpoint: 'expenses/$_editExpenseId',
          method: HttpMethod.put,
          body: req.toJson(),
        );
        if (resp == null ||
            (resp.statusCode != 200 && resp.statusCode != 201)) {
          _snack(_apiErrorMessage(resp, texts.errorCreateExpense));
          return;
        }
        expenseId = _editExpenseId!;
        // Wipe the old split + items so they're recreated from the current form
        // state below. Aborts (with a message) if a participant already settled.
        if (!await _clearSplitsAndItems(expenseId, texts)) return;
      } else {
        final expResp = await _api.request(
          endpoint: 'expenses',
          method: HttpMethod.post,
          body: req.toJson(),
        );
        if (expResp == null ||
            (expResp.statusCode != 200 && expResp.statusCode != 201)) {
          _snack(_apiErrorMessage(expResp, texts.errorCreateExpense));
          return;
        }
        expenseId =
            (jsonDecode(expResp.body) as Map<String, dynamic>)['id'] as String;
      }

      if (_selectedFriendIds.isEmpty && _splitType != SplitType.byItems) {
        _finishSuccessfully();
        return;
      }

      final itemIds = <String, String>{};
      if (_splitType == SplitType.byItems) {
        for (final draft in _items) {
          final itemResp = await _api.request(
            endpoint: 'expenses/$expenseId/items',
            method: HttpMethod.post,
            body: CreateExpenseItemRequest(
              name: draft.name.trim(),
              price: draft.price,
              quantity: 1,
            ).toJson(),
          );
          if (itemResp == null ||
              (itemResp.statusCode != 200 && itemResp.statusCode != 201)) {
            if (!_isEditing) await _rollbackExpense(expenseId);
            _snack(
              _apiErrorMessage(
                itemResp,
                texts.errorSaveItem.replaceAll('{name}', draft.name),
              ),
            );
            return;
          }
          final body = jsonDecode(itemResp.body) as Map<String, dynamic>;
          itemIds[draft.id] = body['id'] as String;
        }
      }

      final participants = _buildParticipantsPayload();
      final assignments = _splitType == SplitType.byItems
          ? [
              for (final draft in _items)
                ItemSplitAssignment(
                  expenseItemId: itemIds[draft.id]!,
                  userIds: draft.assigneeIds.toList(),
                ),
            ]
          : null;

      final splitReq = CreateExpenseSplitRequest(
        splitType: _splitType,
        participants: participants,
        itemAssignments: assignments,
      );
      final splitResp = await _api.request(
        endpoint: 'expenses/$expenseId/splits',
        method: HttpMethod.post,
        body: splitReq.toJson(),
      );
      if (splitResp == null ||
          (splitResp.statusCode != 200 && splitResp.statusCode != 201)) {
        if (!_isEditing) await _rollbackExpense(expenseId);
        _snack(_apiErrorMessage(splitResp, texts.errorSaveSplit));
        return;
      }

      _finishSuccessfully();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<SplitParticipantRequest> _buildParticipantsPayload() {
    switch (_splitType) {
      case SplitType.equal:
        final eq = _equalAmounts();
        return [
          for (final id in _selectedFriendIds)
            SplitParticipantRequest(friendId: id, amount: eq[id] ?? 0.01),
        ];
      case SplitType.custom:
        return [
          for (final id in _selectedFriendIds)
            SplitParticipantRequest(
              friendId: id,
              amount: _parseCtrl(_ctrlFor(id)),
            ),
        ];
      case SplitType.byItems:
        return [
          for (final id in _selectedFriendIds)
            SplitParticipantRequest(friendId: id, amount: 0.01),
        ];
    }
  }

  Future<void> _rollbackExpense(String expenseId) async {
    await _api.request(
      endpoint: 'expenses/$expenseId',
      method: HttpMethod.delete,
    );
  }

  /// Removes the existing split + items of an expense (edit flow), so the form
  /// can recreate them. Returns false (with a message) if the split can't be
  /// deleted because a participant already settled.
  Future<bool> _clearSplitsAndItems(String expenseId, AppTexts texts) async {
    final delSplits = await _api.request(
      endpoint: 'expenses/$expenseId/splits',
      method: HttpMethod.delete,
    );
    // 204 = deleted, 404 = none to delete; 400 = a participant already settled.
    if (delSplits != null && delSplits.statusCode == 400) {
      _snack(_apiErrorMessage(delSplits, texts.errorSaveSplit));
      return false;
    }

    final itemsResp = await _api.request(
      endpoint: 'expenses/$expenseId/items',
      method: HttpMethod.get,
    );
    if (itemsResp != null && itemsResp.statusCode == 200) {
      for (final it in jsonDecode(itemsResp.body) as List<dynamic>) {
        final itemId = it['id']?.toString();
        if (itemId != null) {
          await _api.request(
            endpoint: 'expenses/$expenseId/items/$itemId',
            method: HttpMethod.delete,
          );
        }
      }
    }
    return true;
  }

  // ── Receipt scan ──────────────────────────────────────────────────────────

  Future<void> _scanReceiptWithCamera() async {
    if (_scanningReceipt) return;
    final imageSource = await _showImageSourceDialog();
    if (imageSource == null) return;
    try {
      final photo = await _imagePicker.pickImage(
        source: imageSource,
        imageQuality: 85,
      );
      if (photo == null) return;
      await _uploadReceiptAndPrefillItems(photo);
    } catch (_) {
      if (mounted) _snack(AppTexts.of(context).snackPhotoSourceError);
    }
  }

  Future<void> _scanSingleExpenseWithCamera() async {
    if (_scanningReceipt) return;
    final imageSource = await _showImageSourceDialog();
    if (imageSource == null) return;
    try {
      final photo = await _imagePicker.pickImage(
        source: imageSource,
        imageQuality: 85,
      );
      if (photo == null) return;
      await _uploadSingleExpenseAndPrefill(photo);
    } catch (_) {
      if (mounted) _snack(AppTexts.of(context).snackPhotoSourceError);
    }
  }

  void _maybeStartInitialReceiptScan() {
    if (_initialReceiptScanStarted) return;
    if (_currentUserId == null) return;

    if (widget.initialReceiptItems != null &&
        widget.initialReceiptItems!.isNotEmpty) {
      if (_selectedFriendIds.isEmpty) return;
      if (_splitType != SplitType.byItems) return;
      _initialReceiptScanStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prefillItemsFromExtracted(widget.initialReceiptItems!);
      });
      return;
    }

    if (widget.initialReceiptImagePath == null) return;

    if (_selectedFriendIds.isEmpty) {
      _initialReceiptScanStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _uploadSingleExpenseAndPrefill(XFile(widget.initialReceiptImagePath!));
      });
      return;
    }

    if (_splitType != SplitType.byItems) return;

    _initialReceiptScanStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _uploadReceiptAndPrefillItems(XFile(widget.initialReceiptImagePath!));
    });
  }

  Future<void> _uploadReceiptAndPrefillItems(XFile photo) async {
    setState(() => _scanningReceipt = true);
    try {
      var response = await _sendReceiptScan(photo);
      if (response?.statusCode == 401) {
        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) response = await _sendReceiptScan(photo);
      }
      if (!mounted) return;
      final texts = AppTexts.of(context);
      if (response == null ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        _snack(_apiErrorMessage(response, texts.snackReceiptScanFailed));
        return;
      }
      final decoded = jsonDecode(response.body);
      final extracted = _extractReceiptItems(decoded);
      if (extracted.isEmpty) {
        _snack(texts.snackReceiptNoItems);
        return;
      }
      final participants = <String>{
        if (_currentUserId != null) _currentUserId!,
        ..._selectedFriendIds,
      };
      setState(() {
        _items
          ..clear()
          ..addAll(
            extracted.map(
              (e) => ItemDraft(
                id: 'item_${_itemAutoId++}',
                name: e.name,
                price: e.price,
                assigneeIds: Set<String>.from(participants),
              ),
            ),
          );
        _syncAmountFromItems();
      });
      _snack(
        texts.snackReceiptItems.replaceAll('{count}', '${extracted.length}'),
      );
    } catch (_) {
      if (mounted) _snack(AppTexts.of(context).snackReceiptError);
    } finally {
      if (mounted) setState(() => _scanningReceipt = false);
    }
  }

  void _prefillItemsFromExtracted(List<Map<String, dynamic>> rawItems) {
    final texts = AppTexts.of(context);
    try {
      final extracted = _extractReceiptItems(rawItems);
      if (extracted.isEmpty) {
        _snack(texts.snackReceiptNoItems);
        return;
      }
      final participants = <String>{
        if (_currentUserId != null) _currentUserId!,
        ..._selectedFriendIds,
      };
      setState(() {
        _items
          ..clear()
          ..addAll(
            extracted.map(
              (e) => ItemDraft(
                id: 'item_${_itemAutoId++}',
                name: e.name,
                price: e.price,
                assigneeIds: Set<String>.from(participants),
              ),
            ),
          );
        _syncAmountFromItems();
      });
      _snack(
        texts.snackReceiptItems.replaceAll('{count}', '${extracted.length}'),
      );
    } catch (_) {
      _snack(texts.snackProcessingError);
    }
  }

  Future<void> _uploadSingleExpenseAndPrefill(XFile photo) async {
    setState(() => _scanningReceipt = true);
    try {
      var response = await _sendSingleExpenseScan(photo);
      if (response?.statusCode == 401) {
        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) response = await _sendSingleExpenseScan(photo);
      }
      if (!mounted) return;
      final texts = AppTexts.of(context);
      if (response == null ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        _snack(_apiErrorMessage(response, texts.snackReceiptScanFailed));
        return;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final currency = decoded['currency']?.toString();
      final category = decoded['category']?.toString();
      final totalAmount = (decoded['totalAmount'] as num?)?.toDouble() ?? 0.0;
      setState(() {
        if (currency != null && currency.isNotEmpty) {
          _selectedCurrency = currency;
        }
        if (category != null && category.isNotEmpty) {
          _selectedCategory = _kCategories.firstWhere(
            (cat) => cat.id == category,
            orElse: () => _kCategories.firstWhere(
              (cat) => cat.id == 'others',
              orElse: () => _kCategories.first,
            ),
          );
        }
        _amountController.text = totalAmount.toStringAsFixed(2);
      });
      _snack(texts.snackSingleExpenseFilled);
    } catch (_) {
      if (mounted) _snack(AppTexts.of(context).snackReceiptError);
    } finally {
      if (mounted) setState(() => _scanningReceipt = false);
    }
  }

  Future<http.Response?> _sendReceiptScan(XFile photo) async {
    final token = await AuthService().getAccessToken();
    final uri = Uri.parse('${ProjectApiConst.baseUrl}/$_receiptScanEndpoint');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['ngrok-skip-browser-warning'] = 'true'
      ..files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    try {
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    } catch (_) {
      return null;
    }
  }

  Future<http.Response?> _sendSingleExpenseScan(XFile photo) async {
    final token = await AuthService().getAccessToken();
    final uri = Uri.parse('${ProjectApiConst.baseUrl}/ai/singleExpense');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['ngrok-skip-browser-warning'] = 'true'
      ..files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    try {
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    } catch (_) {
      return null;
    }
  }

  List<_ReceiptItemParsed> _extractReceiptItems(dynamic body) {
    dynamic source = body;
    if (body is Map<String, dynamic>) {
      source =
          body['items'] ??
          body['products'] ??
          body['positions'] ??
          body['data'];
    }
    if (source is! List) return const [];
    final result = <_ReceiptItemParsed>[];
    for (final raw in source.whereType<Map<String, dynamic>>()) {
      final name = (raw['name'] ?? raw['itemName'] ?? raw['productName'])
          ?.toString()
          .trim();
      final rawPrice = (raw['price'] ?? raw['amount'] ?? raw['totalPrice'])
          ?.toString();
      final price = double.tryParse((rawPrice ?? '').replaceAll(',', '.'));
      if (name == null || name.isEmpty || price == null || price <= 0) continue;
      result.add(_ReceiptItemParsed(name: name, price: price));
    }
    return result;
  }

  String _apiErrorMessage(dynamic resp, String fallback) {
    final texts = AppTexts.of(context);
    if (resp == null) return texts.errorNoConnection;
    try {
      final body = jsonDecode(resp.body);
      if (body is Map && body['message'] is String) {
        return '$fallback: ${body['message']}';
      }
    } catch (_) {}
    return '$fallback (${resp.statusCode}).';
  }

  void _finishSuccessfully() {
    Navigator.of(context).pop(true);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffold(widget.isDark),
        appBar: AppBar(
          backgroundColor: AppColors.scaffold(widget.isDark),
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.username(widget.isDark)),
          title: Text(
            _isEditing ? texts.formEditExpense : texts.formNewExpense,
            style: TextStyle(
              color: AppColors.username(widget.isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              // Add the keyboard height to the bottom padding so a focused
              // split/price field can scroll up above the on-screen keyboard.
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                120 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountCard(texts),
                  const SizedBox(height: 20),
                  _sectionHeader(texts.formDetailsSection),
                  const SizedBox(height: 8),
                  _detailsCard(texts),
                  const SizedBox(height: 20),
                  _sectionHeader(texts.formProjectSection),
                  const SizedBox(height: 8),
                  _projectPickerCard(texts),
                  const SizedBox(height: 20),
                  _sectionHeader(texts.formSplitSection),
                  const SizedBox(height: 8),
                  _friendsPickerCard(texts),
                  if (_selectedFriendIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _splitModeSelector(texts),
                    const SizedBox(height: 12),
                    if (_splitType == SplitType.equal) _equalEditor(texts),
                    if (_splitType == SplitType.custom) _customEditor(texts),
                    if (_splitType == SplitType.byItems) ...[
                      const SizedBox(height: 12),
                      _itemsEditor(texts),
                    ],
                  ],
                ],
              ),
            ),
            _buildSaveBar(texts),
          ],
        ),
      ),
    );
  }

  // ── Amount card ───────────────────────────────────────────────────────────

  Widget _buildAmountCard(AppTexts texts) {
    final accent = AppColors.amountCurrency(widget.isDark);
    final locked = _splitType == SplitType.byItems;
    final amountColor = locked ? accent.withValues(alpha: 0.45) : accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        border: Border.all(color: AppColors.amountFieldBorder(widget.isDark)),
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            locked ? texts.formAmountLocked : texts.formAmountLabel,
            style: TextStyle(
              color: AppColors.cardSubtitle(widget.isDark),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickCurrency,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currencySymbol(_selectedCurrency),
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: amountColor, size: 22),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IntrinsicWidth(
                child: _MoneyField(
                  controller: _amountController,
                  readOnly: locked,
                  enableInteractiveSelection: !locked,
                  showCursor: !locked,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: amountColor.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: 6),
            Text(
              texts.formAmountLockedHint,
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 11,
              ),
            ),
          ],
          // Subtelne czerwone ostrzeżenie, gdy wpisano kwotę równą 0.
          if (!locked &&
              _amountController.text.trim().isNotEmpty &&
              _totalAmount == 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  texts.formAmountZeroWarning,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg(widget.isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sheetHandle(widget.isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            for (final c in _kCurrencies)
              ListTile(
                leading: Text(
                  c['symbol']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amountCurrency(widget.isDark),
                  ),
                ),
                title: Text(
                  c['name']!,
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                subtitle: Text(
                  c['code']!,
                  style: TextStyle(
                    color: AppColors.cardSubtitle(widget.isDark),
                  ),
                ),
                trailing: _selectedCurrency == c['code']
                    ? Icon(
                        Icons.check_circle,
                        color: AppColors.amountCurrency(widget.isDark),
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, c['code']),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedCurrency = picked);
  }

  String _currencySymbol(String code) {
    return _kCurrencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'symbol': code},
    )['symbol']!;
  }

  // ── Details card ──────────────────────────────────────────────────────────

  Widget _detailsCard(AppTexts texts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(widget.isDark)),
      ),
      child: Column(
        children: [
          _rowInput(
            label: texts.formShopLabel,
            hint: texts.formShopHint,
            controller: _placeController,
          ),
          _rowDivider(),
          _rowTap(
            label: texts.formDateLabel,
            value: _formatDate(_selectedDate),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          _rowDivider(),
          _rowTap(
            label: texts.formCategoryLabel,
            value: _selectedCategory?.label(texts) ?? texts.formCategoryHint,
            valueIcon: _selectedCategory?.icon,
            valueColor: _selectedCategory?.color,
            placeholder: _selectedCategory == null,
            icon: Icons.local_offer_outlined,
            onTap: () => _pickCategory(texts),
          ),
          _rowDivider(),
          _rowInput(
            label: texts.formNoteLabel,
            hint: texts.formNoteHint,
            controller: _noteController,
          ),
        ],
      ),
    );
  }

  Widget _rowInput({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.cardSubtitle(
                    widget.isDark,
                  ).withValues(alpha: 0.6),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowTap({
    required String label,
    required String value,
    required IconData icon,
    IconData? valueIcon,
    Color? valueColor,
    bool placeholder = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.cardSubtitle(widget.isDark),
                  fontSize: 13,
                ),
              ),
            ),
            if (valueIcon != null) ...[
              Icon(valueIcon, size: 16, color: valueColor),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: placeholder
                      ? AppColors.cardSubtitle(widget.isDark)
                      : AppColors.cardTitle(widget.isDark),
                  fontSize: 15,
                  fontStyle: placeholder ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.cardSubtitle(widget.isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() => Divider(
    color: AppColors.cardBorder(widget.isDark),
    height: 1,
    indent: 16,
    endIndent: 16,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('pl', 'PL'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickCategory(AppTexts texts) async {
    final picked = await showModalBottomSheet<_CategoryOption>(
      context: context,
      backgroundColor: AppColors.cardBg(widget.isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sheetHandle(widget.isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.4,
                children: [
                  for (final c in _kCategories)
                    InkWell(
                      onTap: () => Navigator.pop(ctx, c),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategory?.id == c.id
                                ? c.color
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c.icon, color: c.color, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              c.label(texts),
                              style: TextStyle(
                                color: AppColors.cardTitle(widget.isDark),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedCategory = picked);
  }

  // ── Project picker ────────────────────────────────────────────────────────

  Widget _projectPickerCard(AppTexts texts) {
    final selected = _projects.where((p) => p.id == _selectedProjectId);
    final hasSelection = selected.isNotEmpty;
    final label = hasSelection ? selected.first.name : texts.noProjectExpense;

    return GestureDetector(
      onTap: () => _pickProject(texts),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(widget.isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(widget.isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.actionProjectIconBg(widget.isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.groups_2_outlined,
                size: 20,
                color: AppColors.actionProjectIcon(widget.isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts.projectLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cardSubtitle(widget.isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasSelection
                          ? AppColors.cardTitle(widget.isDark)
                          : AppColors.cardSubtitle(widget.isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.cardSubtitle(widget.isDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProject(AppTexts texts) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.cardBg(widget.isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sheetHandle(widget.isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: AppColors.cardSubtitle(widget.isDark),
                ),
                title: Text(
                  texts.noProjectExpense,
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                trailing: _selectedProjectId == null
                    ? Icon(
                        Icons.check,
                        color: AppColors.amountCurrency(widget.isDark),
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(_kNoProject),
              ),
              if (_projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    texts.noProjectsYet,
                    style: TextStyle(
                      color: AppColors.cardSubtitle(widget.isDark),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _projects
                        .map(
                          (p) => ListTile(
                            leading: Icon(
                              Icons.groups_2_outlined,
                              color: AppColors.actionProjectIcon(widget.isDark),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                color: AppColors.cardTitle(widget.isDark),
                              ),
                            ),
                            trailing: _selectedProjectId == p.id
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.amountCurrency(
                                      widget.isDark,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.of(sheetContext).pop(p.id),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedProjectId = picked == _kNoProject ? null : picked);
  }

  // ── Friends picker ────────────────────────────────────────────────────────

  Widget _friendsPickerCard(AppTexts texts) {
    final selected = _availableFriends
        .where((f) => _selectedFriendIds.contains(f.userId))
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(widget.isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 18,
                color: AppColors.cardSubtitle(widget.isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedFriendIds.isEmpty
                      ? texts.personalExpenseLabel
                      : texts.splitWithPeople
                            .replaceAll(
                              '{count}',
                              '${_selectedFriendIds.length}',
                            )
                            .replaceAll(
                              '{people}',
                              _selectedFriendIds.length == 1
                                  ? 'osobą'
                                  : 'osobami',
                            ),
                  style: TextStyle(
                    color: AppColors.cardTitle(widget.isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openFriendsPicker(texts),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.amountCurrency(widget.isDark),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  texts.addAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_selectedFriendIds.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              texts.addFriendsToSplit,
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _scanningReceipt ? () {} : _scanSingleExpenseWithCamera,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.amountCurrency(widget.isDark),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _scanningReceipt
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.amountCurrency(widget.isDark),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: AppColors.amountCurrency(widget.isDark),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            texts.fillFromReceipt,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.amountCurrency(widget.isDark),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          if (_selectedFriendIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in selected)
                  InputChip(
                    avatar: _initialsAvatar(
                      f.displayName,
                      avatarUrl: f.avatarUrl,
                      size: 12,
                    ),
                    label: Text(f.displayName),
                    labelStyle: TextStyle(
                      color: AppColors.cardTitle(widget.isDark),
                      fontSize: 12,
                    ),
                    onDeleted: () => _toggleFriend(f.userId),
                    deleteIconColor: AppColors.cardSubtitle(widget.isDark),
                    backgroundColor: AppColors.tagInactiveBg(widget.isDark),
                    side: BorderSide(
                      color: AppColors.cardBorder(widget.isDark),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFriendsPicker(AppTexts texts) async {
    if (_loadingFriends) {
      _snack(texts.loadingFriends);
      return;
    }
    if (_availableFriends.isEmpty) {
      _snack(texts.noFriendsYetAddInTab);
      return;
    }

    final tempSelected = Set<String>.from(_selectedFriendIds);
    final confirmed = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: AppColors.cardBg(widget.isDark),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sheetHandle(widget.isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        texts.choosePeople,
                        style: TextStyle(
                          color: AppColors.cardTitle(widget.isDark),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        texts.selectedCountLabel.replaceAll(
                          '{count}',
                          '${tempSelected.length}',
                        ),
                        style: TextStyle(
                          color: AppColors.cardSubtitle(widget.isDark),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableFriends.length,
                    itemBuilder: (_, i) {
                      final f = _availableFriends[i];
                      final sel = tempSelected.contains(f.userId);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) => setModal(() {
                          if (v == true) {
                            tempSelected.add(f.userId);
                          } else {
                            tempSelected.remove(f.userId);
                          }
                        }),
                        title: Text(
                          f.displayName,
                          style: TextStyle(
                            color: AppColors.cardTitle(widget.isDark),
                          ),
                        ),
                        secondary: _initialsAvatar(
                          f.displayName,
                          avatarUrl: f.avatarUrl,
                        ),
                        activeColor: AppColors.amountCurrency(widget.isDark),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, tempSelected),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.amountCurrency(
                          widget.isDark,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        texts.doneAction,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != null) {
      setState(() {
        _selectedFriendIds
          ..clear()
          ..addAll(confirmed);
        for (final item in _items) {
          item.assigneeIds.removeWhere(
            (id) => id != _currentUserId && !_selectedFriendIds.contains(id),
          );
        }
        _syncCustomControllersToEqualFriends();
      });

      if (_selectedFriendIds.isEmpty && _splitType == SplitType.byItems) {
        setState(() {
          _splitType = SplitType.equal;
          if (_amountBeforeByItems != null) {
            _amountController.text = _amountBeforeByItems!;
          }
          _selectedItemIds.clear();
          _itemSelectionMode = false;
        });
      }
    }
  }

  // ── Split selector ────────────────────────────────────────────────────────

  Widget _splitModeSelector(AppTexts texts) {
    return Row(
      children: [
        _modeChip(
          texts.splitModeEqual,
          Icons.pie_chart_outline,
          SplitType.equal,
        ),
        const SizedBox(width: 8),
        _modeChip(texts.splitModeCustom, Icons.edit_note, SplitType.custom),
        const SizedBox(width: 8),
        _modeChip(
          texts.splitModeByItem,
          Icons.shopping_basket_outlined,
          SplitType.byItems,
        ),
      ],
    );
  }

  Widget _modeChip(String label, IconData icon, SplitType type) {
    final active = _splitType == type;
    final accent = AppColors.amountCurrency(widget.isDark);
    return Expanded(
      child: InkWell(
        onTap: () => _setSplitType(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.12)
                : AppColors.cardBg(widget.isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? accent : AppColors.cardBorder(widget.isDark),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? accent : AppColors.cardSubtitle(widget.isDark),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? accent
                      : AppColors.cardSubtitle(widget.isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Equal editor ──────────────────────────────────────────────────────────

  Widget _equalEditor(AppTexts texts) {
    final eq = _equalAmounts();
    final per = _participantIdsIncludingMe.isNotEmpty && _totalAmount > 0
        ? (_totalAmount / _participantIdsIncludingMe.length)
        : 0.0;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _totalAmount > 0
                ? texts.splitEqualPerPerson
                      .replaceAll('{amount}', per.toStringAsFixed(2))
                      .replaceAll(
                        '{currency}',
                        _currencySymbol(_selectedCurrency),
                      )
                : texts.splitEqualHint,
            style: TextStyle(
              color: AppColors.cardSubtitle(widget.isDark),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          for (final id in _participantIdsIncludingMe)
            _readOnlySplitRow(id, eq[id] ?? 0.0),
        ],
      ),
    );
  }

  Widget _readOnlySplitRow(String userId, double amount) {
    final isMe = userId == _currentUserId;
    final name = isMe ? _currentUserDisplayName : _nameFor(userId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _initialsAvatar(
            name,
            avatarUrl: _avatarUrlFor(userId),
            highlight: isMe,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? 'Ty' : name,
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${_currencySymbol(_selectedCurrency)}',
            style: TextStyle(
              color: AppColors.cardTitle(widget.isDark),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom editor ─────────────────────────────────────────────────────────

  Widget _customEditor(AppTexts texts) {
    final accent = AppColors.amountCurrency(widget.isDark);
    _ensureCustomOrder();
    // Shares must add up to the total; otherwise flag it (0.005 = float slack).
    final mismatch =
        _totalAmount > 0 &&
        (_customParticipantsTotal - _totalAmount).abs() > 0.005;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _customOrder.length,
            onReorder: _onReorderParticipants,
            itemBuilder: (context, index) =>
                _participantRow(_customOrder[index], index),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  mismatch ? texts.splitCustomOverflow : texts.splitCustomHint,
                  style: TextStyle(
                    color: mismatch
                        ? AppColors.amountNegative
                        : AppColors.cardSubtitle(widget.isDark),
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(_syncCustomControllersToEqualFriends),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  texts.splitCustomDistribute,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Jeden wiersz podziału CUSTOM (właściciel lub znajomy) z uchwytem do
  // przeciągania. Musi mieć klucz — wymóg ReorderableListView.
  Widget _participantRow(String id, int index) {
    final isOwner = id == _currentUserId;
    final name = isOwner ? _currentUserDisplayName : _nameFor(id);
    final controller = _ctrlFor(id);
    return Padding(
      key: ValueKey('custom_$id'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_indicator,
                size: 18,
                color: AppColors.cardSubtitle(widget.isDark),
              ),
            ),
          ),
          _initialsAvatar(
            name,
            avatarUrl: _avatarUrlFor(id),
            highlight: isOwner,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 14,
                fontWeight: isOwner ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: _MoneyField(
              controller: controller,
              textAlign: TextAlign.right,
              onChanged: (_) => _onParticipantEdited(id),
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 14,
                fontWeight: isOwner ? FontWeight.w700 : FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                suffixText: ' ${_currencySymbol(_selectedCurrency)}',
                suffixStyle: TextStyle(
                  color: AppColors.cardSubtitle(widget.isDark),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.cardBorder(widget.isDark),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.cardBorder(widget.isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Items editor ──────────────────────────────────────────────────────────

  Widget _itemsEditor(AppTexts texts) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${_items.length} ${_items.length == 1 ? texts.itemNounSingular : texts.itemNounPlural}',
                    style: TextStyle(
                      color: AppColors.cardSubtitle(widget.isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_itemSelectionMode) ...[
                    TextButton.icon(
                      onPressed: _toggleSelectAllItems,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amountCurrency(
                          widget.isDark,
                        ),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: Icon(
                        _selectedItemIds.length == _items.length
                            ? Icons.deselect
                            : Icons.select_all,
                        size: 18,
                      ),
                      label: Text(
                        _selectedItemIds.length == _items.length
                            ? texts.deselectAll
                            : texts.selectAll,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : _removeSelectedItems,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amountNegative,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        texts.deleteSelected,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _removeAllItems,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cardSubtitle(widget.isDark),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.delete_forever_outlined, size: 18),
                      label: Text(
                        texts.clearAction,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _exitItemSelectionMode(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.iconExpenseBlue(
                          widget.isDark,
                        ),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      label: Text(
                        texts.doneAction,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: _scanningReceipt ? null : _scanReceiptWithCamera,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amountCurrency(widget.isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: _scanningReceipt
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(
              texts.scanReceiptButton,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _addItem,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.amountCurrency(widget.isDark),
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              texts.addItemButton,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < _items.length; i++) ...[
              _buildItemCard(_items[i], texts),
              if (i != _items.length - 1) const SizedBox(height: 10),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              texts.addItemsHint,
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemDraft item, AppTexts texts) {
    final selected = _selectedItemIds.contains(item.id);

    return GestureDetector(
      onTap: () => _itemSelectionMode
          ? _toggleItemSelection(item.id)
          : _enterItemSelectionMode(item.id),
      onLongPress: () => _itemSelectionMode
          ? _toggleItemSelection(item.id)
          : _enterItemSelectionMode(item.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.amountCurrency(widget.isDark).withValues(alpha: 0.08)
              : AppColors.tagInactiveBg(widget.isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.amountCurrency(widget.isDark)
                : AppColors.cardBorder(widget.isDark),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('name_${item.id}'),
                    initialValue: item.name,
                    onChanged: (v) => item.name = v,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: AppColors.cardTitle(widget.isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: texts.formItemNameHint,
                      hintStyle: TextStyle(
                        color: AppColors.cardSubtitle(widget.isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: _MoneyField(
                    key: ValueKey('price_${item.id}'),
                    initialValue: item.price > 0
                        ? item.price.toStringAsFixed(2)
                        : '',
                    textAlign: TextAlign.right,
                    onChanged: (v) => setState(() {
                      item.price =
                          double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                      if (_splitType == SplitType.byItems) {
                        _syncAmountFromItems();
                      }
                    }),
                    style: TextStyle(
                      color: AppColors.cardTitle(widget.isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0.00',
                      suffixText: ' ${_currencySymbol(_selectedCurrency)}',
                      suffixStyle: TextStyle(
                        color: AppColors.cardSubtitle(widget.isDark),
                        fontSize: 12,
                      ),
                      hintStyle: TextStyle(
                        color: AppColors.cardSubtitle(widget.isDark),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                    ),
                  ),
                ),
                if (_itemSelectionMode)
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleItemSelection(item.id),
                    activeColor: AppColors.amountCurrency(widget.isDark),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final uid in _participantIdsIncludingMe)
                  _itemAssigneeChip(item, uid),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemAssigneeChip(ItemDraft item, String userId) {
    final isMe = userId == _currentUserId;
    final name = isMe ? _currentUserDisplayName : _nameFor(userId);
    final active = item.assigneeIds.contains(userId);
    final accent = AppColors.amountCurrency(widget.isDark);

    return InkWell(
      onTap: () => setState(() {
        if (active) {
          item.assigneeIds.remove(userId);
        } else {
          item.assigneeIds.add(userId);
        }
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent : AppColors.cardBorder(widget.isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              radius: 10,
              avatarUrl: _avatarUrlFor(userId),
              name: name,
              backgroundColor: active
                  ? accent.withValues(alpha: 0.3)
                  : AppColors.avatarBg(widget.isDark),
              foregroundColor: active
                  ? accent
                  : AppColors.avatarFg(widget.isDark),
              fontSize: 9,
            ),
            const SizedBox(width: 6),
            Text(
              isMe ? 'Ty' : name.split(' ').first,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? accent : AppColors.cardSubtitle(widget.isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────────

  Widget _buildSaveBar(AppTexts texts) {
    final err = _blockingError();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.scaffold(widget.isDark),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder(widget.isDark)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.cardSubtitle(widget.isDark),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        err,
                        style: TextStyle(
                          color: AppColors.cardSubtitle(widget.isDark),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amountCurrency(widget.isDark),
                  disabledBackgroundColor: AppColors.amountCurrency(
                    widget.isDark,
                  ).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        texts.saveExpenseButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      title,
      style: TextStyle(
        color: AppColors.sectionTitle(widget.isDark),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _sectionCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg(widget.isDark),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder(widget.isDark)),
    ),
    child: child,
  );

  Widget _initialsAvatar(
    String name, {
    String? avatarUrl,
    bool highlight = false,
    double size = 14,
  }) {
    final bg = highlight
        ? AppColors.amountCurrency(widget.isDark).withValues(alpha: 0.18)
        : AppColors.avatarBg(widget.isDark);
    final fg = highlight
        ? AppColors.amountCurrency(widget.isDark)
        : AppColors.avatarFg(widget.isDark);
    return UserAvatar(
      radius: size + 2,
      avatarUrl: avatarUrl,
      name: name,
      backgroundColor: bg,
      foregroundColor: fg,
      fontSize: size - 2,
    );
  }

  String _nameFor(String userId) {
    if (userId == _currentUserId) return _currentUserDisplayName;
    return _availableFriends
        .firstWhere(
          (f) => f.userId == userId,
          orElse: () =>
              Friend(friendshipId: '', userId: userId, displayName: '?'),
        )
        .displayName;
  }

  // Avatar URL uczestnika: własne zdjęcie z tokenu albo avatarUrl znajomego.
  String? _avatarUrlFor(String userId) {
    if (userId == _currentUserId) return _currentUserAvatarUrl;
    for (final f in _availableFriends) {
      if (f.userId == userId) return f.avatarUrl;
    }
    return null;
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    if (isDesktopWeb) return ImageSource.gallery;
    final texts = AppTexts.of(context);
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBg(widget.isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF243d5a),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                texts.chooseImageSourceTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cardTitle(widget.isDark),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.amountCurrency(widget.isDark),
                ),
                title: Text(
                  texts.cameraLabel,
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                subtitle: Text(
                  texts.cameraSubtitle,
                  style: TextStyle(
                    color: AppColors.cardSubtitle(widget.isDark),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.image,
                  color: AppColors.amountCurrency(widget.isDark),
                ),
                title: Text(
                  texts.galleryLabel,
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                subtitle: Text(
                  texts.gallerySubtitle,
                  style: TextStyle(
                    color: AppColors.cardSubtitle(widget.isDark),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

class _ReceiptItemParsed {
  final String name;
  final double price;

  const _ReceiptItemParsed({required this.name, required this.price});
}

/// Pole kwoty/ceny: wymusza maks. 2 cyfry po separatorze (przez
/// [MoneyInputFormatter]) i po utracie fokusu uzupełnia końcowe zera
/// (`5` → `5.00`, `5,1` → `5.10`).
///
/// Może korzystać z zewnętrznego [controller] (np. wspólnego dla logiki form
/// rodzica) albo — gdy go nie podano — z własnego, zainicjowanego [initialValue].
class _MoneyField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool showCursor;
  final bool enableInteractiveSelection;
  final TextAlign textAlign;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  const _MoneyField({
    super.key,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.showCursor = true,
    this.enableInteractiveSelection = true,
    this.textAlign = TextAlign.start,
    this.style,
    this.decoration,
    this.onChanged,
  });

  @override
  State<_MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<_MoneyField> {
  // Wewnętrzny kontroler tworzymy tylko, gdy rodzic nie podał własnego.
  TextEditingController? _internalController;
  final FocusNode _focusNode = FocusNode();

  // Zawsze aktualny kontroler — jeśli rodzic podmieni `controller` przy
  // przebudowie listy (np. inna osoba w podziale), czytamy nowy, nie stary.
  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(
        text: widget.initialValue ?? '',
      );
    }
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (widget.readOnly) return;

    if (_focusNode.hasFocus) {
      // Po wejściu w pole: obetnij zbędne końcowe zera, aby łatwo było
      // zmienić wartość (`5.00` → `5`, `5.10` → `5.1`). Kursor na końcu.
      final stripped = stripTrailingZeros(_controller.text);
      if (stripped != _controller.text) {
        _controller.value = TextEditingValue(
          text: stripped,
          selection: TextSelection.collapsed(offset: stripped.length),
        );
      }
      return;
    }

    // Po utracie fokusu: uzupełnij do dwóch miejsc po przecinku.
    final normalized = normalizeMoney(_controller.text);
    if (normalized != _controller.text) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [MoneyInputFormatter()],
      textAlign: widget.textAlign,
      style: widget.style,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}
