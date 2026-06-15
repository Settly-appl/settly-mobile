import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/const/api_url.dart';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/services/receipt_scan_service.dart';
import '../models/quick_add_dialog/sheet_option.dart';
import 'expense_form_page.dart';

class QuickScanMenu extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onSaved;

  const QuickScanMenu({super.key, required this.isDark, required this.onSaved});

  @override
  State<QuickScanMenu> createState() => _QuickScanMenuState();
}

class _QuickScanMenuState extends State<QuickScanMenu> {
  final _scanService = ReceiptScanService();
  final _api = ApiServiceRequest();
  final List<Friend> _availableFriends = [];
  bool _isScanning = false;
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold(widget.isDark),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFF243d5a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              texts.quickScanTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(texts.quickScanSubtitle, style: TextStyle(fontSize: 12)),
            SizedBox(height: 20),
            _SheetOption(
              option: SheetOption(
                icon: Icons.receipt_long,
                iconColor: AppColors.actionScanIcon(widget.isDark),
                iconBackground: AppColors.actionScanIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(widget.isDark),
                title: texts.singleExpenseLabel,
                subtitle: texts.quickExpenseExamples,
                titleColor: AppColors.amountCurrency(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning ? () {} : _handleSingleExpenseScan,
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.people,
                iconColor: AppColors.actionProjectIcon(widget.isDark),
                iconBackground: AppColors.actionProjectIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionProjectBorder(widget.isDark),
                title: texts.groupExpenseLabel,
                subtitle: texts.quickGroupExamples,
                titleColor: AppColors.iconProject(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning ? () {} : _handleGroupExpenseScan,
              ),
            ),
            SizedBox(height: 10),
            _SheetOption(
              option: SheetOption(
                icon: Icons.folder,
                iconColor: AppColors.actionAddIcon(widget.isDark),
                iconBackground: AppColors.actionAddIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(widget.isDark),
                title: texts.projectExpenseLabel,
                subtitle: texts.quickProjectExamples,
                titleColor: AppColors.amountCurrency(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning
                    ? () {}
                    : () {
                        Navigator.pop(context);
                        // TODO: navigate to project expense scanning
                      },
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _isScanning ? () {} : () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sheetCancel(widget.isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isScanning
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.cardSubtitle(widget.isDark),
                          ),
                        ),
                      )
                    : Text(
                        texts.cancelActionLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.cardSubtitle(widget.isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSingleExpenseScan() async {
    // Show dialog to choose between camera and gallery
    final imageSource = await _showImageSourceDialog();
    if (imageSource == null) return;

    setState(() => _isScanning = true);

    try {
      // Pick image from camera or gallery
      final imageFile = imageSource == ImageSource.camera
          ? await _scanService.pickImageFromCamera()
          : await _scanService.pickImageFromGallery();

      if (imageFile == null) {
        setState(() => _isScanning = false);
        return;
      }

      // Scan receipt using AI
      final result = await _scanService.scanReceipt(imageFile);
      if (result == null) {
        if (mounted) {
          final texts = AppTexts.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(texts.expenseScanFailedTitle)));
          setState(() => _isScanning = false);
        }
        return;
      }

      // Close the scan menu and open expense form with pre-filled data
      if (!mounted) return;
      final rootMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pop();

      await Future<void>.delayed(Duration.zero);
      final saved = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => ExpenseFormPage(
            isDark: widget.isDark,
            initialCategory: result.category,
            initialCurrency: result.currency,
            initialAmount: result.totalAmount,
          ),
        ),
      );

      if (saved == true) {
        final texts = AppTexts.of(context);
        rootMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(texts.expenseAdded)));
        await widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error in _handleSingleExpenseScan: $e');
      if (mounted) {
        final texts = AppTexts.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(texts.expenseScanFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _handleGroupExpenseScan() async {
    if (_loadingFriends) {
      _snack(AppTexts.of(context).expenseScanLoadingFriends);
      return;
    }
    if (_availableFriends.isEmpty) {
      _snack(AppTexts.of(context).expenseScanNoFriends);
      return;
    }

    final selectedFriendIds = await _openFriendsPicker();
    if (selectedFriendIds == null || selectedFriendIds.isEmpty) return;

    final imageSource = await _showImageSourceDialog();
    if (imageSource == null) return;

    setState(() => _isScanning = true);

    try {
      final imageFile = imageSource == ImageSource.camera
          ? await _scanService.pickImageFromCamera()
          : await _scanService.pickImageFromGallery();

      if (imageFile == null) return;

      // Single call to /ai: payload should include items and can include summary fields.
      final itemsResponse = await _sendReceiptForItems(imageFile);
      if (itemsResponse == null ||
          (itemsResponse.statusCode != 200 &&
              itemsResponse.statusCode != 201)) {
        if (mounted) {
          _snack(AppTexts.of(context).expenseScanNoReceipt);
        }
        return;
      }

      late final Map<String, dynamic> parsed;
      try {
        parsed = _parseGroupScanPayload(jsonDecode(itemsResponse.body));
      } catch (_) {
        if (mounted) {
          _snack(AppTexts.of(context).expenseScanReadError);
        }
        return;
      }

      final itemsData = parsed['items'] as List<Map<String, dynamic>>;
      if (itemsData.isEmpty) {
        if (mounted) {
          _snack(AppTexts.of(context).expenseScanNoItems);
        }
        return;
      }

      if (!mounted) return;
      final rootMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pop();

      await Future<void>.delayed(Duration.zero);
      final saved = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => ExpenseFormPage(
            isDark: widget.isDark,
            initialCategory: parsed['category'] as String,
            initialSelectedFriendIds: selectedFriendIds.toList(),
            initialSplitType: SplitType.byItems,
            initialReceiptItems: itemsData,
          ),
        ),
      );

      if (saved == true) {
        final texts = AppTexts.of(context);
        rootMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(texts.expenseAdded)));
        await widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error in _handleGroupExpenseScan: $e');
      if (mounted) {
        _snack(AppTexts.of(context).expenseScanFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<Set<String>?> _openFriendsPicker() async {
    final tempSelected = <String>{};

    return showModalBottomSheet<Set<String>>(
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
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.avatarBg(widget.isDark),
                          child: Text(
                            f.displayName.trim().isNotEmpty
                                ? f.displayName.trim()[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.avatarFg(widget.isDark),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      onPressed: tempSelected.isEmpty
                          ? null
                          : () => Navigator.pop(ctx, tempSelected),
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
  }

  Future<ImageSource?> _showImageSourceDialog() async {
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
                  color: Color(0xFF243d5a),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                texts.chooseImageSourceTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.username(widget.isDark),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.actionScanIcon(widget.isDark),
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
                  color: AppColors.actionAddIcon(widget.isDark),
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

  Future<http.Response?> _sendReceiptForItems(File photo) async {
    final token = await AuthService().getAccessToken();
    final uri = Uri.parse('${ProjectApiConst.baseUrl}/ai');

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

  Map<String, dynamic> _parseGroupScanPayload(dynamic decoded) {
    List<Map<String, dynamic>> items = const [];
    String category = 'others';

    if (decoded is Map<String, dynamic>) {
      // Extract category
      category = decoded['category']?.toString() ?? category;

      // Extract items
      final itemsSource = decoded['items'];
      if (itemsSource is List) {
        items = List<Map<String, dynamic>>.from(
          itemsSource.whereType<Map<String, dynamic>>(),
        );
      }
    }

    return {'items': items, 'category': category};
  }

  Future<void> _loadFriends() async {
    final response = await _api.request(
      endpoint: 'friendships',
      method: HttpMethod.get,
    );
    if (!mounted) return;

    if (response != null && response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      _availableFriends.addAll(
        decoded.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }

    setState(() => _loadingFriends = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SheetOption extends StatelessWidget {
  final SheetOption option;

  const _SheetOption({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: option.iconBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: option.borderColor),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: option.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        color: option.titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF4A6A85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
