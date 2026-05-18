import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:settly_mobile/models/frends/friend.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
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
              'Skanuj paragon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Wybierz typ wydatku do zskanowania',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 20),
            _SheetOption(
              option: SheetOption(
                icon: Icons.receipt_long,
                iconColor: AppColors.actionScanIcon(widget.isDark),
                iconBackground: AppColors.actionScanIconBg(widget.isDark),
                borderColor: AppColors.sheetOptionExpenseBorder(widget.isDark),
                title: 'Pojedynczy wydatek',
                subtitle: 'Skanuj paragon by stworzyć pojedynczy wydatek',
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
                title: 'Wydatek grupowy',
                subtitle: 'Skanuj paragon by stworzyć wydatek z znajomymi',
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
                title: 'Wydatek w projekcie',
                subtitle: 'Do projektu',
                titleColor: AppColors.amountCurrency(widget.isDark),
                subtitleColor: AppColors.cardSubtitle(widget.isDark),
                onTap: _isScanning
                    ? () {}
                    : () {
                        Navigator.pop(context);
                        // TODO: nawigacja do skanowania wydatku w projekcie
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
                        'Anuluj',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nie udało się zskanować paragonu. Spróbuj ponownie.',
              ),
            ),
          );
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
        rootMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Dodano wydatek.')));
        await widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error in _handleSingleExpenseScan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Błąd podczas skanowania. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _handleGroupExpenseScan() async {
    if (_loadingFriends) {
      _snack('Trwa ładowanie znajomych…');
      return;
    }
    if (_availableFriends.isEmpty) {
      _snack('Nie masz jeszcze znajomych. Dodaj ich w zakładce Znajomi.');
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

      final result = await _scanService.scanReceipt(imageFile);
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nie udało się zskanować paragonu. Spróbuj ponownie.',
              ),
            ),
          );
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
            initialCategory: result.category,
            initialCurrency: result.currency,
            initialAmount: result.totalAmount,
            initialSelectedFriendIds: selectedFriendIds.toList(),
            initialSplitType: SplitType.byItems,
            initialReceiptImagePath: imageFile.path,
          ),
        ),
      );

      if (saved == true) {
        rootMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Dodano wydatek.')));
        await widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error in _handleGroupExpenseScan: $e');
      if (mounted) {
        _snack('Błąd podczas skanowania. Spróbuj ponownie.');
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
                'Wybierz źródło zdjęcia',
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
                  'Aparat',
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                subtitle: Text(
                  'Zrób zdjęcie paragonu',
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
                  'Galeria',
                  style: TextStyle(color: AppColors.cardTitle(widget.isDark)),
                ),
                subtitle: Text(
                  'Wybierz zdjęcie z galerii',
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
