import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/debt_record.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/balances_service.dart';
import 'package:settly_mobile/services/auth_service.dart';

/// Read-only list of past settlements (where the user was debtor or creditor).
class SettlementHistoryPage extends StatefulWidget {
  const SettlementHistoryPage({super.key});

  @override
  State<SettlementHistoryPage> createState() => _SettlementHistoryPageState();
}

class _SettlementHistoryPageState extends State<SettlementHistoryPage> {
  final _service = BalancesService();

  bool _loading = true;
  String? _error;
  List<DebtRecord> _records = [];
  String? _currentUserId;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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
      final userInfo = await AuthService().getUserInfo();
      final data = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _currentUserId = userInfo?['sub'] as String?;
        _records = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppTexts.of(context).historyRetryError;
        _loading = false;
      });
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
          texts.historyTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(isDark),
          ),
        ),
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
      return _centered(
        Icons.cloud_off_rounded,
        _error!,
        action: OutlinedButton(
          onPressed: _load,
          child: Text(texts.historyRetryButton),
        ),
      );
    }
    if (_records.isEmpty) {
      return _centered(
        Icons.receipt_long_outlined,
        texts.historyNoItems,
        subtitle: texts.historySubtitle,
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RecordCard(
        record: _records[i],
        isDark: isDark,
        youReceived: _records[i].toUserId == _currentUserId,
      ),
    );
  }

  Widget _centered(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(
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
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final DebtRecord record;
  final bool isDark;

  /// True when the current user was the creditor (money came in).
  final bool youReceived;

  const _RecordCard({
    required this.record,
    required this.isDark,
    required this.youReceived,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final color = youReceived
        ? AppColors.amountPositive
        : AppColors.amountNegative;
    final sign = youReceived ? '+' : '-';
    final title = youReceived
        ? texts.historyReceivedPayment
        : texts.historySentPayment;
    final date = record.settledAt ?? record.createdAt;
    final dateLabel = date != null
        ? DateFormat('d MMM yyyy, HH:mm', 'pl').format(date)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              youReceived ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardTitle(isDark),
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cardSubtitle(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$sign${record.amount.toStringAsFixed(2)} zł',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
