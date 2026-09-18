import 'dart:async';

import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/balance_item.dart';
import 'package:settly_mobile/models/friend_balance.dart';
import 'package:settly_mobile/pages/expense_details_page.dart';
import 'package:settly_mobile/utils/category_label.dart';
import 'package:settly_mobile/pages/settlement_history_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/widgets/user_avatar.dart';
import 'package:settly_mobile/services/api_service/balances_service.dart';
import 'package:settly_mobile/utils/money_format.dart';
import 'package:settly_mobile/services/api_service/user_settings_service.dart';
import 'package:settly_mobile/repository/expense_repository.dart';
import 'package:settly_mobile/pages/unconverted_expenses_page.dart';

/// Lists net balances between the current user and each friend, and lets the
/// user mark money they're owed as received ("Rozlicz").
class BalancesPage extends StatefulWidget {
  const BalancesPage({super.key});

  @override
  State<BalancesPage> createState() => _BalancesPageState();
}

class _BalancesPageState extends State<BalancesPage> {
  final _service = BalancesService();

  bool _loading = true;
  String? _error;
  List<FriendBalance> _balances = [];

  /// Ile wydatków czeka na kurs. Dopóki go nie mają, backend pomija je w
  /// saldach — saldo jest wtedy niepełne i trzeba to powiedzieć wprost,
  /// zamiast pokazywać liczbę, która wygląda na kompletną.
  final _expenseRepository = ExpenseRepository();
  int _needsRateCount = 0;
  final Set<String> _settling = {};

  /// Rozwinięte salda — z czego składa się kwota przy danej osobie.
  ///
  /// Stan rozwinięcia trzyma strona, nie karta: dzięki temu przeżywa
  /// odświeżenie listy i powrót z ekranu wydatku, więc po rozliczeniu czy
  /// edycji użytkownik wraca dokładnie tam, gdzie patrzył.
  final Set<String> _expanded = {};
  final Map<String, List<BalanceItem>> _items = {};
  final Set<String> _itemsLoading = {};
  final Set<String> _itemsFailed = {};

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  /// Salda przychodzą już przeliczone na walutę bazową użytkownika, więc to
  /// ona jest domyślną etykietą; konkretne saldo niesie swoją walutę ze sobą.
  static String _money(double v, [String? currency]) =>
      formatMoney(v, currency ?? UserSettingsService.baseCurrency);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getBalances();
      final unconverted = await _expenseRepository.fetchUnconvertedExpenses();
      if (!mounted) return;
      setState(() {
        _balances = data;
        _needsRateCount = unconverted.length;
        _loading = false;
        // Salda przeliczone od nowa — rozwinięcia muszą pójść za nimi, bo
        // lista wydatków sprzed rozliczenia opisywałaby stan, którego już nie
        // ma. Zamknięte zostają zamknięte; rozliczone do zera znikają z listy,
        // więc ich rozwinięcie nie ma już czego pokazywać.
        _items.clear();
        _itemsFailed.clear();
        _expanded.removeWhere(
          (id) => !_balances.any((b) => b.userId == id),
        );
      });
      for (final id in _expanded) {
        unawaited(_loadItems(id));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppTexts.of(context).balancesRetryMessage;
        _loading = false;
      });
    }
  }

  double get _totalOwedToYou => _balances
      .where((b) => b.owesYou)
      .fold(0.0, (sum, b) => sum + b.absAmount);

  double get _totalYouOwe =>
      _balances.where((b) => b.youOwe).fold(0.0, (sum, b) => sum + b.absAmount);

  Future<void> _confirmSettle(FriendBalance balance) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.scaffold(isDark),
      builder: (_) => _SettleConfirmSheet(balance: balance, isDark: isDark),
    );

    if (confirmed != true) return;
    await _settle(balance);
  }

  Future<void> _settle(FriendBalance balance) async {
    final texts = AppTexts.of(context);
    setState(() => _settling.add(balance.userId));
    try {
      await _service.settleUp(debtorUserId: balance.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            texts.balancePaidOut
                .replaceAll('{amount}', _money(balance.absAmount))
                .replaceAll('{name}', balance.label),
          ),
          backgroundColor: AppColors.amountPositive,
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.settleFailedError)));
    } finally {
      if (mounted) setState(() => _settling.remove(balance.userId));
    }
  }

  /// Rozwija/zwija saldo. Pozycje pobieramy dopiero przy rozwinięciu i tylko
  /// raz — otwarcie każdego salda z góry to jedno zapytanie na znajomego za
  /// każdym wejściem na ekran, a większość z nich nikt nie otworzy.
  Future<void> _toggleExpanded(String userId) async {
    if (_expanded.contains(userId)) {
      setState(() => _expanded.remove(userId));
      return;
    }
    setState(() => _expanded.add(userId));
    if (_items.containsKey(userId)) return;
    await _loadItems(userId);
  }

  Future<void> _loadItems(String userId) async {
    setState(() {
      _itemsLoading.add(userId);
      _itemsFailed.remove(userId);
    });
    try {
      final items = await _service.getBalanceItems(userId);
      if (!mounted) return;
      setState(() => _items[userId] = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemsFailed.add(userId));
    } finally {
      if (mounted) setState(() => _itemsLoading.remove(userId));
    }
  }

  /// Otwiera wydatek stojący za pozycją salda.
  ///
  /// Zwykły `push`, więc cofnięcie wraca na Rozliczenia (a stamtąd na główną),
  /// zamiast wyrzucać użytkownika gdzieś indziej. Ekran szczegółów potrzebuje
  /// całego wydatku, a pozycja salda niesie samo id — stąd dociągnięcie.
  Future<void> _openExpense(BalanceItem item) async {
    final texts = AppTexts.of(context);
    // Dociągnięcie wydatku to sieć, a dotknięty wiersz bez żadnej odpowiedzi
    // wygląda jak zepsuty — stąd kółko na czas pobierania.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final expense = await _expenseRepository.fetchExpense(item.expenseId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (expense == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.balanceItemsFailed)));
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExpenseDetailsPage(expense: expense)),
    );
    if (changed == true) await _load();
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
          texts.balancesTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: texts.balancesHistoryTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettlementHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final texts = AppTexts.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: _error!,
        actionLabel: texts.retryAction,
        onAction: _load,
        isDark: isDark,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_needsRateCount > 0) ...[
          _NeedsRateBanner(
            count: _needsRateCount,
            isDark: isDark,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UnconvertedExpensesPage(isDark: isDark),
                ),
              );
              await _load();
            },
          ),
          const SizedBox(height: 16),
        ],
        _SummaryHeader(
          owedToYou: _money(_totalOwedToYou),
          youOwe: _money(_totalYouOwe),
        ),
        const SizedBox(height: 20),
        if (_balances.isEmpty)
          _MessageState(
            icon: Icons.celebration_outlined,
            title: texts.allSettledTitle,
            subtitle: texts.allSettledSubtitle,
            isDark: isDark,
          )
        else
          ..._balances.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BalanceCard(
                balance: b,
                isDark: isDark,
                settling: _settling.contains(b.userId),
                onSettle: () => _confirmSettle(b),
                expanded: _expanded.contains(b.userId),
                items: _items[b.userId],
                itemsLoading: _itemsLoading.contains(b.userId),
                itemsFailed: _itemsFailed.contains(b.userId),
                onToggle: () => _toggleExpanded(b.userId),
                onRetryItems: () => _loadItems(b.userId),
                onOpenExpense: _openExpense,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String owedToYou;
  final String youOwe;

  const _SummaryHeader({required this.owedToYou, required this.youOwe});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.summaryGradientLeft,
            AppColors.summaryGradientRight,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: texts.balancesOwedToYou,
              amount: owedToYou,
              subtitle: texts.balancesOtherOwes,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              label: texts.balancesYouOwe,
              amount: youOwe,
              subtitle: texts.balancesYouOweOthers,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.summaryTileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.summaryTileLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.summaryTileValue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.summaryTileSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final FriendBalance balance;
  final bool isDark;
  final bool settling;
  final VoidCallback onSettle;

  /// Czy saldo jest rozwinięte na wydatki, i co w nim jest.
  final bool expanded;
  final List<BalanceItem>? items;
  final bool itemsLoading;
  final bool itemsFailed;
  final VoidCallback onToggle;
  final VoidCallback onRetryItems;
  final void Function(BalanceItem item) onOpenExpense;

  const _BalanceCard({
    required this.balance,
    required this.isDark,
    required this.settling,
    required this.onSettle,
    required this.expanded,
    required this.items,
    required this.itemsLoading,
    required this.itemsFailed,
    required this.onToggle,
    required this.onRetryItems,
    required this.onOpenExpense,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final amountColor = balance.owesYou
        ? AppColors.amountPositive
        : AppColors.amountNegative;
    final sign = balance.owesYou ? '+' : '-';
    // Kierunek salda po polsku bezosobowo — patrz AppTexts.balanceOwedToYouLabel.
    final subtitle = balance.owesYou
        ? texts.balanceOwedToYouLabel
        : texts.balanceYouOweLabel;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Rozwija cała górna belka, nie sama strzałka: strzałka mówi tylko,
          // że jest co otworzyć, a celem dotyku jest wiersz.
          //
          // Material(transparency) nad tłem karty: bez niego fala dotyku
          // rysuje się na Materiale Scaffolda, czyli POD kartą, i gest nie
          // daje żadnej odpowiedzi.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  UserAvatar(
                    radius: 22,
                    avatarUrl: balance.avatarUrl,
                    initials: balance.initials,
                    backgroundColor: AppColors.avatarBg(isDark),
                    foregroundColor: AppColors.avatarFg(isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cardTitle(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cardSubtitle(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign${formatMoney(balance.absAmount, balance.currency)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 22,
                    color: AppColors.cardSubtitle(isDark),
                    semanticLabel: expanded
                        ? texts.balanceHideExpenses
                        : texts.balanceShowExpenses,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _buildItems(texts),
          if (balance.owesYou) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: settling ? null : onSettle,
                icon: settling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(settling ? texts.loading : texts.settlesAsReceived),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amountPositive,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                texts.settleWaitConfirmation,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.cardSubtitle(isDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Z czego składa się saldo. Obie strony idą osobno, bo „jesteś winien 40"
  /// i „jesteś winien 90, a masz do odebrania 50" to ta sama liczba — i tylko
  /// tę drugą da się sprawdzić z wydatkami w ręku.
  Widget _buildItems(AppTexts texts) {
    if (itemsLoading && items == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (itemsFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texts.balanceItemsFailed,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.cardSubtitle(isDark),
                ),
              ),
            ),
            TextButton(
              onPressed: onRetryItems,
              child: Text(texts.retryAction),
            ),
          ],
        ),
      );
    }

    final all = items ?? const <BalanceItem>[];
    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            texts.balanceItemsEmpty,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cardSubtitle(isDark),
            ),
          ),
        ),
      );
    }

    final owedToMe = all.where((i) => i.owedToMe).toList();
    final youOwe = all.where((i) => !i.owedToMe).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.cardBorder(isDark)),
        if (owedToMe.isNotEmpty)
          _section(texts, texts.balanceOwedToYouLabel, owedToMe, true),
        if (youOwe.isNotEmpty)
          _section(texts, texts.balanceYouOweLabel, youOwe, false),
      ],
    );
  }

  Widget _section(
    AppTexts texts,
    String title,
    List<BalanceItem> sectionItems,
    bool owedToMe,
  ) {
    final color = owedToMe
        ? AppColors.amountPositive
        : AppColors.amountNegative;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Row(
            children: [
              Icon(
                owedToMe
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                texts.expensesCount(sectionItems.length),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.cardSubtitle(isDark),
                ),
              ),
            ],
          ),
        ),
        ...sectionItems.map(
          (item) => _BalanceItemRow(
            item: item,
            isDark: isDark,
            color: color,
            onTap: () => onOpenExpense(item),
          ),
        ),
      ],
    );
  }
}

/// Jeden wydatek pod saldem. Klikalny — prowadzi na ekran wydatku zwykłym
/// `push`, więc cofnięcie wraca tutaj, na Rozliczenia.
class _BalanceItemRow extends StatelessWidget {
  final BalanceItem item;
  final bool isDark;

  /// Kolor kierunku — ten sam, co nagłówek sekcji, żeby po samej kwocie było
  /// widać, czy to należność, czy zobowiązanie.
  final Color color;
  final VoidCallback onTap;

  const _BalanceItemRow({
    required this.item,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final meta = <String>[
      '${item.date.day} ${texts.monthGenitive(item.date.month)}',
      if (item.projectName != null && item.projectName!.isNotEmpty)
        item.projectName!,
      if (item.category.isNotEmpty)
        localizedCategoryLabel(item.category, texts),
    ].join(' · ');

    // Udział to kwota DO ZAPŁATY, więc prowadzi waluta bazowa (formatSettlement).
    // Bez kursu nie ma czego przeliczać — zostaje kwota z paragonu, wyraźnie
    // opisana jako nieliczona do salda, żeby suma pozycji zgadzała się z liczbą
    // na górze karty.
    final amount = item.needsRate
        ? formatMoney(item.shareAmount, item.currency)
        : formatSettlement(
            item.shareBaseAmount,
            item.baseCurrency,
            item.shareAmount,
            item.currency,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texts.expenseName(item.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cardTitle(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.cardSubtitle(isDark),
                      ),
                    ),
                    if (item.needsRate)
                      Text(
                        texts.balanceItemNotCounted,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amountNegative,
                        ),
                      ),
                    if (item.declaredPaid)
                      Text(
                        texts.expenseDeclaredBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.needsRate
                      ? AppColors.cardSubtitle(isDark)
                      : color,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.cardSubtitle(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettleConfirmSheet extends StatelessWidget {
  final FriendBalance balance;
  final bool isDark;

  const _SettleConfirmSheet({required this.balance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            texts.settleConfirmTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.username(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texts.settleConfirmBody(
              balance.label,
              balance.absAmount.toStringAsFixed(2),
            ),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cardSubtitle(isDark),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amountPositive,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(texts.settleConfirmAction),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(texts.cancelAction),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const _MessageState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.cardSubtitle(isDark)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.cardTitle(isDark),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cardSubtitle(isDark),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Saldo jest niepełne, bo część wydatków nie ma kursu.
///
/// Celowo widoczne nad samymi kwotami: bez tego liczby wyglądają na kompletne,
/// a to właśnie brakujące przeliczenia potrafią odwrócić wynik „kto komu".
class _NeedsRateBanner extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _NeedsRateBanner({
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.amountNegative.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.amountNegative.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.currency_exchange_rounded,
              color: AppColors.amountNegative,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts.needsRateTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.amountNegative,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    texts.needsRateSubtitle(count),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cardSubtitle(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texts.needsRateAction,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amountNegative,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.amountNegative,
            ),
          ],
        ),
      ),
    );
  }
}
