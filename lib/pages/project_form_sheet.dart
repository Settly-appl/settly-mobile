import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/projects_service.dart';
import 'package:settly_mobile/services/api_service/user_settings_service.dart';
import 'package:settly_mobile/utils/date_format.dart';
import 'package:settly_mobile/utils/money_format.dart';
import 'package:settly_mobile/utils/money_input.dart';

/// Formularz wyjazdu — ten sam przy tworzeniu i przy edycji.
///
/// Jedna klasa na oba przypadki celowo: waluta wyjazdu, kurs i daty dały się
/// ustawić tylko przy zakładaniu projektu, bo edycja była osobnym, uboższym
/// okienkiem („zmień nazwę"). Cokolwiek dojdzie do formularza, dochodzi od
/// razu w obu miejscach.
///
/// [project] `null` znaczy „nowy projekt". Zamyka się zwracając `true`, gdy coś
/// zapisano — wołający odświeża wtedy listę.
class ProjectFormSheet extends StatefulWidget {
  final bool isDark;
  final ProjectsService service;
  final Project? project;

  const ProjectFormSheet({
    super.key,
    required this.isDark,
    required this.service,
    this.project,
  });

  @override
  State<ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<ProjectFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _rateController;

  /// Waluta wyjazdu. `null` znaczy „ta sama co bazowa" — wtedy nie ma czego
  /// przeliczać i pole kursu się nie pokazuje.
  String? _tripCurrency;

  /// Oba końce albo żaden — otwarty przedział zagarniałby każdy przyszły
  /// wydatek, więc do automatycznego wyboru liczy się tylko pełny zakres.
  DateTimeRange? _tripDates;

  bool _saving = false;

  /// Nazwa jest wymagana; komunikat pokazujemy dopiero po naciśnięciu zapisu,
  /// żeby pusty formularz nie witał użytkownika czerwienią.
  bool _showNameError = false;

  bool get _isEdit => widget.project != null;

  String get _baseCurrency => UserSettingsService.baseCurrency;

  double? get _tripRate {
    final raw = _rateController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    return (value == null || value <= 0) ? null : value;
  }

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _nameController = TextEditingController(text: project?.name ?? '');
    _descController = TextEditingController(text: project?.description ?? '');
    final rate = project?.defaultRateToBase;
    _rateController = TextEditingController(
      text: rate == null ? '' : _trimZeros(rate),
    );
    // Waluta wyjazdu równa bazowej nie ma co robić w pickerze (nie ma czego
    // przeliczać), a i lista jej nie zawiera — traktujemy ją jak brak.
    final currency = project?.defaultCurrency;
    _tripCurrency = (currency == null || currency == _baseCurrency)
        ? null
        : currency;
    final start = project?.startDate;
    final end = project?.endDate;
    if (start != null && end != null) {
      _tripDates = DateTimeRange(start: start, end: end);
    }
  }

  /// `4.85` zamiast `4.8500` — kurs wpisuje człowiek i tak też powinien go
  /// zobaczyć, wracając do formularza.
  static String _trimZeros(double value) {
    var text = value.toStringAsFixed(4);
    if (text.contains('.')) {
      text = text.replaceAll(RegExp(r'0+$'), '');
      text = text.replaceAll(RegExp(r'\.$'), '');
    }
    return text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickTripDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: _tripDates,
    );
    if (picked != null && mounted) setState(() => _tripDates = picked);
  }

  Future<void> _save() async {
    final texts = AppTexts.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final description = _descController.text.trim();
    setState(() {
      _showNameError = false;
      _saving = true;
    });
    try {
      if (_isEdit) {
        await widget.service.updateProject(
          widget.project!.id,
          name: name,
          // Pusty opis i pusta waluta CZYSZCZĄ pole (backend czyta brak klucza
          // jako „nie ruszaj"), a wyczyszczenie waluty zabiera też kurs.
          description: description,
          defaultCurrency: _tripCurrency ?? '',
          defaultRateToBase: _tripCurrency == null ? null : _tripRate,
          startDate: _tripDates?.start,
          endDate: _tripDates?.end,
          clearDateSpan: _tripDates == null,
        );
      } else {
        await widget.service.createProject(
          name: name,
          description: description.isEmpty ? null : description,
          defaultCurrency: _tripCurrency,
          defaultRateToBase: _tripCurrency == null ? null : _tripRate,
          startDate: _tripDates?.start,
          endDate: _tripDates?.end,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? texts.projectUpdateFailedError
                : texts.projectCreateFailedError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? texts.projectEditTitle : texts.projectNewProject,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.username(widget.isDark),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_showNameError) setState(() => _showNameError = false);
              },
              decoration: InputDecoration(
                labelText: texts.projectNameLabel,
                hintText: texts.projectNameExample,
                errorText: _showNameError ? texts.projectNameRequired : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: texts.projectDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tripCurrency,
              decoration: InputDecoration(
                labelText: texts.projectCurrencyLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(texts.projectCurrencyNone),
                ),
                for (final c in kCurrencies)
                  if (c['code'] != _baseCurrency)
                    DropdownMenuItem<String>(
                      value: c['code'],
                      child: Text('${c['code']} — ${c['name']}'),
                    ),
              ],
              onChanged: (value) => setState(() => _tripCurrency = value),
            ),
            if (_tripCurrency != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [MoneyInputFormatter(decimalRange: 4)],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: texts.formRateLabel(_tripCurrency!, _baseCurrency),
                  hintText: '0.0000',
                  helperText: texts.projectCurrencyHint,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickTripDates,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: texts.projectDatesLabel,
                  helperText: texts.projectDatesHint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                  suffixIcon: _tripDates == null
                      ? const Icon(Icons.date_range_outlined)
                      : IconButton(
                          tooltip: texts.projectDatesClear,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _tripDates = null),
                        ),
                ),
                child: Text(
                  formatDateSpan(_tripDates?.start, _tripDates?.end) ??
                      texts.projectDatesNotSet,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.avatarFg(widget.isDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? texts.saveAction : texts.createAction,
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
