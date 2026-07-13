import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/notification_service.dart';

/// „Włącz powiadomienia" — jedyna droga wyjścia, gdy push nie działa.
///
/// `NotificationService.init()` pyta o zgodę tylko, gdy nie została jeszcze
/// podjęta, więc kto raz odmówił, nie zobaczy pytania nigdy więcej. Bez tego
/// przycisku taki użytkownik zostawał z cicho zepsutymi powiadomieniami i bez
/// żadnego sygnału, że coś jest nie tak.
class EnableNotificationsButton extends StatefulWidget {
  /// Wywoływane po udanym włączeniu — np. żeby schować baner.
  final VoidCallback? onEnabled;

  const EnableNotificationsButton({super.key, this.onEnabled});

  @override
  State<EnableNotificationsButton> createState() =>
      _EnableNotificationsButtonState();
}

class _EnableNotificationsButtonState extends State<EnableNotificationsButton> {
  bool _working = false;

  Future<void> _enable() async {
    final texts = AppTexts.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _working = true);
    final result = await NotificationService().enableNotifications();
    if (!mounted) return;
    setState(() => _working = false);

    switch (result) {
      case NotificationEnableResult.enabled:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(texts.notifEnabledOk)));
        widget.onEnabled?.call();

      // Zgoda zablokowana — strona nie może o nią poprosić ponownie, trzeba
      // zmienić ustawienia przeglądarki.
      case NotificationEnableResult.blocked:
        _explain(texts.notifBlockedTitle, texts.notifBlockedBody);

      // Zgoda jest, a tokenu nie ma. Najczęściej Brave z wyłączonym Google push
      // messaging albo iOS bez zainstalowanej PWA — kierowanie takiej osoby do
      // ustawień zgód niczego by nie dało.
      case NotificationEnableResult.noPushService:
        _explain(texts.notifNoPushServiceTitle, texts.notifNoPushServiceBody);

      case NotificationEnableResult.unsupported:
        _explain(texts.notifNoPushServiceTitle, texts.notifUnsupportedBody);

      case NotificationEnableResult.failed:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(texts.notifEnableFailed)));
    }
  }

  void _explain(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTexts.of(ctx).doneAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return OutlinedButton.icon(
      onPressed: _working ? null : _enable,
      icon: _working
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.notifications_active_outlined),
      label: Text(texts.notifEnableButton),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.amountCurrency(
          Theme.of(context).brightness == Brightness.dark,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
