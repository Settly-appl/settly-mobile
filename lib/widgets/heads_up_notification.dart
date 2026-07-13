import 'dart:async';

import 'package:flutter/material.dart';
import 'package:settly_mobile/models/app_notification.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

/// Pasek powiadomienia u góry ekranu (jak na Androidzie), pokazywany, gdy push
/// przyjdzie przy otwartej aplikacji — system nie rysuje wtedy własnego dymka,
/// więc bez tego powiadomienie byłoby niewidoczne.
///
/// Można go kliknąć (przechodzi tam, gdzie prowadzi powiadomienie) albo zsunąć
/// w górę / w bok, żeby zniknął. Sam chowa się po [_visibleFor].
class HeadsUpNotification extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const HeadsUpNotification({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  static const _visibleFor = Duration(seconds: 6);

  @override
  State<HeadsUpNotification> createState() => _HeadsUpNotificationState();
}

class _HeadsUpNotificationState extends State<HeadsUpNotification> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(HeadsUpNotification._visibleFor, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.notification.type) {
      case 'FRIEND_REQUEST':
      case 'FRIEND_REQUEST_ACCEPTED':
        return Icons.people_outline;
      case 'EXPENSE_SPLIT':
        return Icons.attach_money_rounded;
      case 'EXPENSE_SETTLEMENT':
        return Icons.check_circle_outline;
      case 'SETTLEMENT_REMINDER':
        return Icons.alarm_on_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final n = widget.notification;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Dismissible(
                key: ValueKey('headsup_${n.id ?? n.receivedAt}'),
                // W górę albo w bok — jak systemowy dymek.
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder(isDark)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.actionScanIcon(
                                isDark,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _icon,
                              size: 17,
                              color: AppColors.actionScanIcon(isDark),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  n.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cardTitle(isDark),
                                  ),
                                ),
                                if (n.body.isNotEmpty)
                                  Text(
                                    n.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.cardSubtitle(isDark),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
