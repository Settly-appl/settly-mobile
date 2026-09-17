import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/suggestion.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/suggestions_service.dart';

/// Lista sugestii — widok wyłącznie dla admina.
///
/// Ukrycie przycisku w profilu to uprzejmość, nie zabezpieczenie: dostępu
/// pilnuje backend (`@PreAuthorize("hasRole('admin')")`), więc ktoś bez roli
/// zobaczy tu komunikat o błędzie, a nie cudze zgłoszenia.
class SuggestionsPage extends StatefulWidget {
  final bool isDark;

  const SuggestionsPage({super.key, required this.isDark});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final _service = SuggestionsService();
  List<Suggestion> _suggestions = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _suggestions = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// Kasowanie jest nieodwracalne i nie ma kopii nigdzie indziej, więc pytamy
  /// najpierw. Listę odświeżamy lokalnie zamiast przeładowywać z sieci —
  /// backend już potwierdził usunięcie.
  Future<void> _confirmDelete(Suggestion suggestion) async {
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(texts.suggestionsDeleteTitle),
        content: Text(texts.suggestionsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(texts.suggestionsDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.amountNegative,
            ),
            child: Text(texts.suggestionsDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.delete(suggestion.id);
      if (!mounted) return;
      setState(() => _suggestions.removeWhere((s) => s.id == suggestion.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.suggestionsDeleted)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.suggestionsDeleteFailed)));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(widget.isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          texts.suggestionsAdminTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(widget.isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _buildBody(texts)),
      ),
    );
  }

  Widget _buildBody(AppTexts texts) {
    if (_failed || _suggestions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
        children: [
          Icon(
            _failed ? Icons.cloud_off_rounded : Icons.inbox_outlined,
            size: 48,
            color: AppColors.cardSubtitle(widget.isDark),
          ),
          const SizedBox(height: 12),
          Text(
            _failed ? texts.suggestionsAdminFailed : texts.suggestionsAdminEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cardSubtitle(widget.isDark)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg(widget.isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder(widget.isDark)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.cardTitle(widget.isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${suggestion.authorName ?? texts.suggestionsDeletedAuthor}'
                      ' · ${_formatDate(suggestion.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.cardSubtitle(widget.isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Wypełniony przycisk z PODPISEM, nie sama ikona.
              //
              // Poprzednie podejście — przemalowanie konturowej ikony na
              // czerwono — wciąż było niewidoczne. Nie zgadujemy więc dalej,
              // czemu 22-pikselowy kontur ginie na czyjejś karcie: kasowanie
              // dostaje pełne czerwone tło, biały znak i słowo „Usuń". Napis
              // jest tu najważniejszy — rysuje go zwykły font tekstu, więc
              // przycisk zostaje widoczny nawet wtedy, gdy font ikon się nie
              // wczyta i z glifu kosza zostanie pusty prostokąt.
              Tooltip(
                message: texts.suggestionsDeleteTooltip,
                child: FilledButton.icon(
                  onPressed: () => _confirmDelete(suggestion),
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: Text(texts.suggestionsDeleteTooltip),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amountNegative,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
