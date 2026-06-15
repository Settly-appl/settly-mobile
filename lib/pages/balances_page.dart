import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/friend_balance.dart';
import 'package:settly_mobile/pages/settlement_history_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/balances_service.dart';

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
  final Set<String> _settling = {};

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  static String _money(double v) => '${v.toStringAsFixed(2)} zł';

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
      final data = await _service.getBalances();
      if (!mounted) return;
      setState(() {
        _balances = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = texts.balancesRetryMessage;
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

  const _BalanceCard({
    required this.balance,
    required this.isDark,
    required this.settling,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final amountColor = balance.owesYou
        ? AppColors.amountPositive
        : AppColors.amountNegative;
    final sign = balance.owesYou ? '+' : '-';
    final subtitle = balance.owesYou ? 'They owe you' : 'You owe them';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.avatarBg(isDark),
                backgroundImage:
                    (balance.avatarUrl != null && balance.avatarUrl!.isNotEmpty)
                    ? NetworkImage(balance.avatarUrl!)
                    : null,
                child: (balance.avatarUrl == null || balance.avatarUrl!.isEmpty)
                    ? Text(
                        balance.initials,
                        style: TextStyle(
                          color: AppColors.avatarFg(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                '$sign${balance.absAmount.toStringAsFixed(2)} zł',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
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
                'Wait until your friend confirms receiving the payment.',
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
}

class _SettleConfirmSheet extends StatelessWidget {
  final FriendBalance balance;
  final bool isDark;

  const _SettleConfirmSheet({required this.balance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mark as settled?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.username(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You confirm that ${balance.label} paid you '
            '${balance.absAmount.toStringAsFixed(2)} zł. All unsettled '
            'shares of this person toward you will be closed.',
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
            child: const Text('Yes, settle'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppTexts.of(context).cancelAction),
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
