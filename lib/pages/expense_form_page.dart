import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:settly_mobile/const/api_url.dart';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:settly_mobile/models/expenses/item_draft.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/auth_service.dart';

class ExpenseFormPage extends StatefulWidget {
  final bool isDark;
  final String? initialCategory;
  final String? initialCurrency;
  final double? initialAmount;

  const ExpenseFormPage({
    super.key,
    required this.isDark,
    this.initialCategory,
    this.initialCurrency,
    this.initialAmount,
  });

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _CategoryOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryOption(this.id, this.label, this.icon, this.color);
}

const List<_CategoryOption> _kCategories = [
  _CategoryOption('shopping', 'Zakupy', Icons.shopping_bag, Colors.orange),
  _CategoryOption('food', 'Jedzenie', Icons.restaurant, Colors.red),
  _CategoryOption('transport', 'Transport', Icons.directions_car, Colors.blue),
  _CategoryOption('entertainment', 'Rozrywka', Icons.movie, Colors.purple),
  _CategoryOption('health', 'Zdrowie', Icons.medical_services, Colors.green),
  _CategoryOption('others', 'Inne', Icons.more_horiz, Colors.grey),
];

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

  bool _loadingFriends = true;
  List<Friend> _availableFriends = [];
  final Set<String> _selectedFriendIds = {};

  String? _currentUserId;
  String _currentUserDisplayName = 'Ty';

  SplitType _splitType = SplitType.equal;

  // Keyed by friendId (payer is NOT here — payer's share is computed).
  final Map<String, TextEditingController> _customAmountControllers = {};

  final List<ItemDraft> _items = [];
  int _itemAutoId = 0;

  bool _saving = false;
  bool _scanningReceipt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _amountController.addListener(_onAmountChanged);

    // Initialize with provided values if any
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

    _loadCurrentUser();
    _loadFriends();
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
    });
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

  /// Everyone in the split: current user first, then selected friends in list order.
  List<String> get _participantIdsIncludingMe {
    final ids = <String>[];
    if (_currentUserId != null) ids.add(_currentUserId!);
    for (final f in _availableFriends) {
      if (_selectedFriendIds.contains(f.userId)) ids.add(f.userId);
    }
    return ids;
  }

  /// Equal split: everyone gets total/N; remainder (groszy) ends up on payer.
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

  double get _customFriendsTotal {
    double s = 0;
    for (final id in _selectedFriendIds) {
      final c = _customAmountControllers[id];
      if (c != null) s += _parseCtrl(c);
    }
    return s;
  }

  double get _myCustomShare => _totalAmount - _customFriendsTotal;

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
    }
    setState(() {});
  }

  void _syncCustomControllersToEqualFriends() {
    final equal = _equalAmounts();
    for (final friendId in _selectedFriendIds) {
      final controller = _customAmountControllers.putIfAbsent(
        friendId,
        () => TextEditingController(),
      );
      final amt = (equal[friendId] ?? 0.0).toStringAsFixed(2);
      if (controller.text != amt) controller.text = amt;
    }
    _customAmountControllers.removeWhere((id, c) {
      if (!_selectedFriendIds.contains(id)) {
        c.dispose();
        return true;
      }
      return false;
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
  }

  void _setSplitType(SplitType t) {
    setState(() {
      _splitType = t;
      if (t == SplitType.custom) {
        _syncCustomControllersToEqualFriends();
      }
      if (t == SplitType.byItems) {
        _syncAmountFromItems();
      }
    });
  }

  void _syncAmountFromItems() {
    final text = _itemsSum.toStringAsFixed(2);
    if (_amountController.text != text) {
      _amountController.text = text;
    }
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

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((i) => i.id == id);
      if (_splitType == SplitType.byItems) _syncAmountFromItems();
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  String? _blockingError() {
    if (_currentUserId == null) {
      return 'Nie można pobrać Twojego konta. Zaloguj się ponownie.';
    }
    if (_totalAmount <= 0) return 'Wprowadź kwotę większą niż 0.';
    if (_selectedCategory == null) return 'Wybierz kategorię wydatku.';

    if (_selectedFriendIds.isEmpty) {
      return null; // personal expense — OK
    }

    if (_splitType == SplitType.custom) {
      if (_customFriendsTotal >= _totalAmount) {
        return 'Kwoty znajomych nie mogą pokryć całości — Ty też musisz coś zapłacić.';
      }
      if (_customFriendsTotal < 0 ||
          _customAmountControllers.values.any((c) => _parseCtrl(c) < 0)) {
        return 'Kwoty nie mogą być ujemne.';
      }
    }

    if (_splitType == SplitType.byItems) {
      if (_items.isEmpty) return 'Dodaj przynajmniej jedną pozycję.';
      for (final item in _items) {
        if (item.name.trim().isEmpty) {
          return 'Każda pozycja musi mieć nazwę.';
        }
        if (item.price <= 0) {
          return 'Każda pozycja musi mieć cenę większą niż 0.';
        }
        if (item.assigneeIds.isEmpty) {
          return 'Pozycja "${item.name}" musi mieć przynajmniej jedną osobę.';
        }
      }
      // Ensure every selected friend is actually assigned somewhere — otherwise
      // backend would reject them as unused participants.
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
          return 'Przypisz pozycje dla: $name (lub usuń osobę z podziału).';
        }
      }
    }
    return null;
  }

  bool get _canSave => _blockingError() == null && !_saving;

  Future<void> _save() async {
    final err = _blockingError();
    if (err != null) {
      _snack(err);
      return;
    }

    setState(() => _saving = true);
    try {
      // ── Step 1: create the expense ───────────────────────────────────────
      final req = CreateExpenseRequest(
        shop: _placeController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        currency: _selectedCurrency,
        category: _selectedCategory!.id,
        totalAmount: _totalAmount,
        date: _selectedDate,
      );
      final expResp = await _api.request(
        endpoint: 'expenses',
        method: HttpMethod.post,
        body: req.toJson(),
      );
      if (expResp == null ||
          (expResp.statusCode != 200 && expResp.statusCode != 201)) {
        _snack(_apiErrorMessage(expResp, 'Nie udało się utworzyć wydatku'));
        return;
      }
      final expenseId =
          (jsonDecode(expResp.body) as Map<String, dynamic>)['id'] as String;

      // Personal expense — done after step 1.
      if (_selectedFriendIds.isEmpty) {
        _finishSuccessfully();
        return;
      }

      // ── Step 2 (BY_ITEM only): create items ──────────────────────────────
      final itemIds = <String, String>{}; // draft.id -> server itemId
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
            await _rollbackExpense(expenseId);
            _snack(
              _apiErrorMessage(
                itemResp,
                'Nie udało się zapisać pozycji "${draft.name}"',
              ),
            );
            return;
          }
          final body = jsonDecode(itemResp.body) as Map<String, dynamic>;
          itemIds[draft.id] = body['id'] as String;
        }
      }

      // ── Step 3: create splits ────────────────────────────────────────────
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
        await _rollbackExpense(expenseId);
        _snack(_apiErrorMessage(splitResp, 'Nie udało się zapisać podziału'));
        return;
      }

      _finishSuccessfully();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<SplitParticipantRequest> _buildParticipantsPayload() {
    // Backend forbids the payer being in `participants` and adds them automatically.
    switch (_splitType) {
      case SplitType.equal:
        final eq = _equalAmounts();
        return [
          for (final id in _selectedFriendIds)
            SplitParticipantRequest(
              friendId: id,
              amount: eq[id] ?? 0.01, // backend recomputes; just needs > 0
            ),
        ];
      case SplitType.custom:
        return [
          for (final id in _selectedFriendIds)
            SplitParticipantRequest(
              friendId: id,
              amount: _parseCtrl(_customAmountControllers[id]!),
            ),
        ];
      case SplitType.byItems:
        // Any positive amount works — backend recomputes from item assignments.
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

  Future<void> _scanReceiptWithCamera() async {
    if (_scanningReceipt) return;
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;
      await _uploadReceiptAndPrefillItems(photo);
    } catch (_) {
      _snack('Nie udało się otworzyć aparatu.');
    }
  }

  Future<void> _uploadReceiptAndPrefillItems(XFile photo) async {
    setState(() => _scanningReceipt = true);
    try {
      var response = await _sendReceiptScan(photo);

      if (response?.statusCode == 401) {
        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) {
          response = await _sendReceiptScan(photo);
        }
      }

      if (!mounted) return;
      if (response == null ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        _snack(_apiErrorMessage(response, 'Nie udało się zeskanować paragonu'));
        return;
      }

      final decoded = jsonDecode(response.body);
      final extracted = _extractReceiptItems(decoded);
      if (extracted.isEmpty) {
        _snack('Nie rozpoznano pozycji na paragonie.');
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

      _snack('Dodano ${extracted.length} pozycji z paragonu.');
    } catch (_) {
      _snack('Wystąpił błąd podczas analizy paragonu.');
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
      ..files.add(await http.MultipartFile.fromPath('receipt', photo.path));

    try {
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    } on SocketException {
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
    if (resp == null) return 'Brak połączenia. Spróbuj ponownie.';
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
            'Nowy wydatek',
            style: TextStyle(
              color: AppColors.username(widget.isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 20),

                  _sectionHeader('SZCZEGÓŁY'),
                  const SizedBox(height: 8),
                  _detailsCard(),

                  const SizedBox(height: 20),
                  _sectionHeader('PODZIAŁ'),
                  const SizedBox(height: 8),
                  _friendsPickerCard(),

                  if (_selectedFriendIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _splitModeSelector(),
                    const SizedBox(height: 12),
                    if (_splitType == SplitType.equal) _equalEditor(),
                    if (_splitType == SplitType.custom) _customEditor(),
                    if (_splitType == SplitType.byItems) _itemsEditor(),
                  ],
                ],
              ),
            ),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  // ── Amount ────────────────────────────────────────────────────────────────
  Widget _buildAmountCard() {
    final accent = AppColors.amountCurrency(widget.isDark);
    final locked = _splitType == SplitType.byItems;
    final amountColor = locked ? accent.withOpacity(0.45) : accent;
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
          colors: [accent.withOpacity(0.08), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            locked ? 'KWOTA (z pozycji)' : 'KWOTA',
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
                child: TextField(
                  controller: _amountController,
                  readOnly: locked,
                  enableInteractiveSelection: !locked,
                  showCursor: !locked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: amountColor.withOpacity(0.4)),
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
              'Suma aktualizuje się automatycznie z dodanych pozycji.',
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 11,
              ),
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
  Widget _detailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(widget.isDark)),
      ),
      child: Column(
        children: [
          _rowInput(
            label: 'Sklep / miejsce',
            hint: 'np. Biedronka',
            controller: _placeController,
          ),
          _rowDivider(),
          _rowTap(
            label: 'Data',
            value: _formatDate(_selectedDate),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          _rowDivider(),
          _rowTap(
            label: 'Kategoria',
            value: _selectedCategory?.label ?? 'Wybierz',
            valueIcon: _selectedCategory?.icon,
            valueColor: _selectedCategory?.color,
            placeholder: _selectedCategory == null,
            icon: Icons.local_offer_outlined,
            onTap: _pickCategory,
          ),
          _rowDivider(),
          _rowInput(
            label: 'Notatka',
            hint: 'Opcjonalnie',
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
                  color: AppColors.cardSubtitle(widget.isDark).withOpacity(0.6),
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

  Future<void> _pickCategory() async {
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
                          color: c.color.withOpacity(0.12),
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
                              c.label,
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

  // ── Friends picker ────────────────────────────────────────────────────────
  Widget _friendsPickerCard() {
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
                      ? 'Wydatek osobisty'
                      : 'Dzielisz z ${_selectedFriendIds.length} ${_selectedFriendIds.length == 1 ? 'osobą' : 'osobami'}',
                  style: TextStyle(
                    color: AppColors.cardTitle(widget.isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openFriendsPicker,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.amountCurrency(widget.isDark),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Dodaj',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (selected.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Dodaj znajomych, aby podzielić koszty.',
              style: TextStyle(
                color: AppColors.cardSubtitle(widget.isDark),
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in selected)
                  InputChip(
                    avatar: _initialsAvatar(f.displayName, size: 12),
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

  Future<void> _openFriendsPicker() async {
    if (_loadingFriends) {
      _snack('Trwa ładowanie znajomych…');
      return;
    }
    if (_availableFriends.isEmpty) {
      _snack('Nie masz jeszcze znajomych. Dodaj ich w zakładce Znajomi.');
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
                        'Wybierz osoby',
                        style: TextStyle(
                          color: AppColors.cardTitle(widget.isDark),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${tempSelected.length} zaznaczonych',
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
                      final selected = tempSelected.contains(f.userId);
                      return CheckboxListTile(
                        value: selected,
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
                        secondary: _initialsAvatar(f.displayName),
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
                      child: const Text(
                        'Gotowe',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
    }
  }

  // ── Split selector ────────────────────────────────────────────────────────
  Widget _splitModeSelector() {
    return Row(
      children: [
        _modeChip('Równo', Icons.pie_chart_outline, SplitType.equal),
        const SizedBox(width: 8),
        _modeChip('Kwoty', Icons.edit_note, SplitType.custom),
        const SizedBox(width: 8),
        _modeChip(
          'Per produkt',
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
                ? accent.withOpacity(0.12)
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
  Widget _equalEditor() {
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
                ? 'Po ok. ${per.toStringAsFixed(2)} ${_currencySymbol(_selectedCurrency)} na osobę'
                : 'Wprowadź kwotę powyżej',
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
          _initialsAvatar(name, highlight: isMe),
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
  Widget _customEditor() {
    final accent = AppColors.amountCurrency(widget.isDark);
    final myShare = _myCustomShare;
    final overflow = myShare <= 0 && _totalAmount > 0;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                _initialsAvatar(_currentUserDisplayName, highlight: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ty (reszta)',
                    style: TextStyle(
                      color: AppColors.cardTitle(widget.isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${myShare.toStringAsFixed(2)} ${_currencySymbol(_selectedCurrency)}',
                  style: TextStyle(
                    color: overflow
                        ? AppColors.amountNegative
                        : AppColors.cardTitle(widget.isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final friendId in _selectedFriendIds) _customFriendRow(friendId),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  overflow
                      ? 'Suma znajomych ≥ total. Ty musisz mieć > 0 zł.'
                      : 'Twój udział = total − suma znajomych.',
                  style: TextStyle(
                    color: overflow
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
                child: const Text(
                  'Rozdziel równo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customFriendRow(String friendId) {
    final controller = _customAmountControllers.putIfAbsent(
      friendId,
      () => TextEditingController(text: '0.00'),
    );
    final name = _nameFor(friendId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _initialsAvatar(name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: AppColors.cardTitle(widget.isDark),
                fontSize: 14,
                fontWeight: FontWeight.w600,
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

  // ── Items editor (BY_ITEM) ────────────────────────────────────────────────
  Widget _itemsEditor() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              _scanningReceipt ? 'Skanuję paragon...' : 'Skanuj paragon',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Dodaj pozycje z paragonu i zaznacz, kto co brał.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cardSubtitle(widget.isDark),
                  fontSize: 13,
                ),
              ),
            )
          else
            for (final item in _items) _itemCard(item),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.amountCurrency(widget.isDark),
              side: BorderSide(color: AppColors.cardBorder(widget.isDark)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Dodaj pozycję',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(ItemDraft item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.tagInactiveBg(widget.isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder(widget.isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  onChanged: (v) => setState(() => item.name = v),
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: AppColors.cardTitle(widget.isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Nazwa (np. Mleko)',
                    hintStyle: TextStyle(
                      color: AppColors.cardSubtitle(widget.isDark),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 4),
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: item.price > 0
                      ? item.price.toStringAsFixed(2)
                      : '',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.right,
                  onChanged: (v) => setState(() {
                    item.price = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
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
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.cardSubtitle(widget.isDark),
                ),
                onPressed: () => _removeItem(item.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
    );
  }

  Widget _itemAssigneeChip(ItemDraft item, String userId) {
    final isMe = userId == _currentUserId;
    final name = isMe ? _currentUserDisplayName : _nameFor(userId);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
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
          color: active ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent : AppColors.cardBorder(widget.isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: active
                  ? accent.withOpacity(0.3)
                  : AppColors.avatarBg(widget.isDark),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: active ? accent : AppColors.avatarFg(widget.isDark),
                ),
              ),
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
  Widget _buildSaveBar() {
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
                  ).withOpacity(0.4),
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
                    : const Text(
                        'Zapisz wydatek',
                        style: TextStyle(
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
    bool highlight = false,
    double size = 14,
  }) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final bg = highlight
        ? AppColors.amountCurrency(widget.isDark).withOpacity(0.18)
        : AppColors.avatarBg(widget.isDark);
    final fg = highlight
        ? AppColors.amountCurrency(widget.isDark)
        : AppColors.avatarFg(widget.isDark);
    return CircleAvatar(
      radius: size + 2,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontSize: size - 2,
          fontWeight: FontWeight.bold,
        ),
      ),
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
