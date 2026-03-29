import 'package:flutter/material.dart';
import 'package:settly_mobile/dto/expense_request.dart';
import '../projectColors/app_colors.dart';

class ExpenseFormDialog extends StatefulWidget {
  final bool isDark;
  const ExpenseFormDialog({super.key, required this.isDark});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _selectedCategory = "Wybierz";
  bool _isCategoryExpanded = false;

  String _selectedProject = "Brak projektu";
  bool _isProjectExpanded = false;

  String _selectedSplitType = "Podział równy";
  bool _isSplitTypeExpanded = false;

  bool _isFriendsExpanded = false;
  bool _isScanned = false;
  final List<String> _selectedFriends = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.orange},
    {'name': 'food', 'icon': Icons.restaurant, 'color': Colors.red},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'entertainment', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': 'health', 'icon': Icons.medical_services, 'color': Colors.green},
    {'name': 'others', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _projects = [
    {
      'name': 'Wakacje Chorwacja',
      'icon': Icons.beach_access,
      'color': Colors.cyan,
      'members': 4,
    },
    {
      'name': 'Impreza urodzinowa',
      'icon': Icons.cake,
      'color': Colors.pink,
      'members': 6,
    },
    {
      'name': 'Wspólne zakupy',
      'icon': Icons.shopping_cart,
      'color': Colors.orange,
      'members': 3,
    },
    {
      'name': 'Wyjazd służbowy',
      'icon': Icons.business_center,
      'color': Colors.blue,
      'members': 2,
    },
  ];

  final List<Map<String, dynamic>> _friends = [
    {'name': 'Kasia Mazurek', 'initials': 'KN', 'color': Colors.pink},
    {'name': 'Piotr Wiśniewski', 'initials': 'PW', 'color': Colors.orange},
    {'name': 'Anna Kowalska', 'initials': 'AK', 'color': Colors.purple},
    {'name': 'Marek Zielony', 'initials': 'MZ', 'color': Colors.teal},
    {'name': 'Julia Dąbrowska', 'initials': 'JD', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final Color bgColor = AppColors.scaffold(widget.isDark);
    final Color cardColor = widget.isDark
        ? const Color(0xFF1A2D45)
        : Colors.white;
    final Color accentGreen = AppColors.amountCurrency(widget.isDark);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return MediaQuery.removeViewInsets(
      removeBottom: true,
      context: context,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDark
                  ? const Color(0xFF243D5A)
                  : const Color(0xFFE8EDF3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: keyboardHeight + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Center(
                  child: Text(
                    "Nowy wydatek",
                    style: TextStyle(
                      color: AppColors.username(widget.isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // KWOTA
                _buildAmountSection(accentGreen),

                const SizedBox(height: 24),
                _sectionHeader("SZCZEGÓŁY"),
                const SizedBox(height: 12),

                _buildInputField(
                  "Sklep / miejsce",
                  "np. Biedronka...",
                  _placeController,
                  cardColor,
                ),

                _buildClickableField(
                  "Data",
                  _formatDate(_selectedDate),
                  cardColor,
                  onTap: _presentDatePicker,
                ),

                // KATEGORIA
                _buildExpandableHeader(
                  label: "KATEGORIA",
                  value: _selectedCategory,
                  isExpanded: _isCategoryExpanded,
                  cardColor: cardColor,
                  onTap: () => setState(
                    () => _isCategoryExpanded = !_isCategoryExpanded,
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _isCategoryExpanded ? 180 : 0,
                  margin: EdgeInsets.only(bottom: _isCategoryExpanded ? 12 : 0),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.cardBorder(widget.isDark),
                        ),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final bool isSelected =
                              _selectedCategory == cat['name'];
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = cat['name'];
                              _isCategoryExpanded = false;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (cat['color'] as Color).withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(
                                        color: (cat['color'] as Color)
                                            .withOpacity(0.4),
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    color: cat['color'] as Color,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      color: AppColors.cardSubtitle(
                                        widget.isDark,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                _buildInputField(
                  "Notatka (opcjonalna)",
                  "Dodaj opis...",
                  _noteController,
                  cardColor,
                ),

                const SizedBox(height: 16),
                _sectionHeader("PROJEKT"),
                const SizedBox(height: 12),

                // PROJEKT
                _buildExpandableHeader(
                  label: "PRZYPISZ DO PROJEKTU",
                  value: _selectedProject,
                  isExpanded: _isProjectExpanded,
                  cardColor: cardColor,
                  onTap: () =>
                      setState(() => _isProjectExpanded = !_isProjectExpanded),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _isProjectExpanded
                      ? (_projects.length * 64.0) + 8
                      : 0,
                  margin: EdgeInsets.only(bottom: _isProjectExpanded ? 12 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardBorder(widget.isDark),
                      ),
                    ),
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _projects.length,
                      separatorBuilder: (_, __) => Divider(
                        color: AppColors.cardBorder(widget.isDark),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        final bool isSelected =
                            _selectedProject == project['name'];
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedProject = project['name'];
                            _isProjectExpanded = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (project['color'] as Color).withOpacity(
                                      0.08,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (project['color'] as Color)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    project['icon'] as IconData,
                                    color: project['color'] as Color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project['name'],
                                        style: TextStyle(
                                          color: AppColors.cardTitle(
                                            widget.isDark,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${project['members']} uczestników',
                                        style: TextStyle(
                                          color: AppColors.cardSubtitle(
                                            widget.isDark,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.amountCurrency(
                                      widget.isDark,
                                    ),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _sectionHeader("PODZIAŁ KOSZTÓW"),
                const SizedBox(height: 12),

                // ZNAJOMI
                _buildExpandableHeader(
                  label: "DODAJ ZNAJOMYCH",
                  value: _selectedFriends.isEmpty
                      ? "Wybierz osoby"
                      : _selectedFriends.join(', '),
                  isExpanded: _isFriendsExpanded,
                  cardColor: cardColor,
                  onTap: () =>
                      setState(() => _isFriendsExpanded = !_isFriendsExpanded),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _isFriendsExpanded ? (_friends.length * 56.0) + 8 : 0,
                  margin: EdgeInsets.only(bottom: _isFriendsExpanded ? 12 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardBorder(widget.isDark),
                      ),
                    ),
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _friends.length,
                      separatorBuilder: (_, __) => Divider(
                        color: AppColors.cardBorder(widget.isDark),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        final bool isSelected = _selectedFriends.contains(
                          friend['name'],
                        );
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedFriends.remove(friend['name']);
                            } else {
                              _selectedFriends.add(friend['name']);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (friend['color'] as Color).withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: (friend['color'] as Color)
                                      .withOpacity(0.15),
                                  child: Text(
                                    friend['initials'],
                                    style: TextStyle(
                                      color: friend['color'] as Color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    friend['name'],
                                    style: TextStyle(
                                      color: AppColors.cardTitle(widget.isDark),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.amountCurrency(
                                      widget.isDark,
                                    ),
                                    size: 18,
                                  )
                                else
                                  Icon(
                                    Icons.circle_outlined,
                                    color: AppColors.cardSubtitle(
                                      widget.isDark,
                                    ),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Podgląd wybranych znajomych + Wybór typu podziału
                if (_selectedFriends.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(
                      () => _isSplitTypeExpanded = !_isSplitTypeExpanded,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors
                          .transparent, // Zapewnia klikalność na całej szerokości
                      child: Row(
                        children: [
                          // Wyświetlamy awatary wybranych osób
                          ..._selectedFriends.take(3).map((name) {
                            final friend = _friends.firstWhere(
                              (f) => f['name'] == name,
                            );
                            return _userAvatar(
                              friend['initials'],
                              friend['color'] as Color,
                            );
                          }),
                          if (_selectedFriends.length > 3)
                            Text(
                              " +${_selectedFriends.length - 3}",
                              style: TextStyle(
                                color: AppColors.cardSubtitle(widget.isDark),
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 8),

                          // Wybrany typ podziału
                          Text(
                            _selectedSplitType,
                            style: TextStyle(
                              color: AppColors.amountCurrency(widget.isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isSplitTypeExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.cardSubtitle(widget.isDark),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ROZWIJANIE TYPU PODZIAŁU
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isSplitTypeExpanded ? 100 : 0,
                    curve: Curves.easeInOut,
                    child: _isSplitTypeExpanded
                        ? Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.cardBorder(widget.isDark),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSplitOption(
                                  "Podział równy",
                                  Icons.pie_chart_outline,
                                ),
                                Divider(
                                  height: 1,
                                  color: AppColors.cardBorder(widget.isDark),
                                ),
                                _buildSplitOption(
                                  "Własne kwoty (Custom)",
                                  Icons.edit_note,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Wspólny widget nagłówka z rozwijaniem (używany przez kategorię i projekt)
  Widget _buildExpandableHeader({
    required String label,
    required String value,
    required bool isExpanded,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Używamy Expanded, aby tekst wiedział, ile ma miejsca
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    // KLUCZOWE PARAMETRY:
                    maxLines: 1, // Tylko jedna linia
                    overflow: TextOverflow.ellipsis, // Dodaje "..." na końcu
                  ),
                ),
                const SizedBox(width: 8), // Odstęp od strzałki
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blueGrey,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(Color accentGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "KWOTA",
            style: TextStyle(color: Colors.blueGrey, fontSize: 10),
          ),
          const SizedBox(height: 4),
          IntrinsicWidth(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentGreen,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "0,00",
                hintStyle: TextStyle(color: accentGreen.withOpacity(0.2)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    "zł",
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitSection() {
    return Row(
      children: [
        _userAvatar("M", Colors.blue),
        _userAvatar("K", Colors.pink),
        _userAvatar("P", Colors.orange),
        const SizedBox(width: 8),
        const Text(
          "Podział równy",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right, color: Colors.blueGrey),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {
        // --- PUNKT 2: Mapowanie danych z UI do obiektu DTO ---
        final expense = ExpenseRequest(
          totalAmount:
              double.tryParse(_amountController.text.replaceAll(',', '.')) ??
              0.0,
          shop: _placeController.text.trim(),
          date: _selectedDate,
          //category: _selectedCategory,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          isScanned: _isScanned,
          //projectId: _selectedProject,
          //splitType: _selectedSplitType,
          //participants: _selectedFriends,
        );

        // --- WALIDACJA ---
        if (expense.totalAmount <= 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Wprowadź kwotę!")));
          return;
        }
        // --- WYJŚCIE ---
        // Zwracamy cały obiekt DTO do HomePage
        Navigator.pop(context, expense);
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF00E6B4), Color(0xFF0088FF)],
          ),
        ),
        child: const Center(
          child: Text(
            "Zapisz wydatek",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      color: Colors.blueGrey,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _userAvatar(String initial, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _presentDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale("pl", "PL"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FFA3),
              onPrimary: Colors.black,
              surface: Color(0xFF1B2735),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildSplitOption(String title, IconData icon) {
    final bool isSelected = _selectedSplitType == title;
    return InkWell(
      onTap: () => setState(() {
        _selectedSplitType = title;
        _isSplitTypeExpanded = false;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.amountCurrency(widget.isDark)
                  : Colors.blueGrey,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: AppColors.amountCurrency(widget.isDark),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return "$day.$month";
  }
}
