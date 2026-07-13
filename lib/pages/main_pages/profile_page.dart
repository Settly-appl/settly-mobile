import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/pages/admin_broadcast_page.dart';
import 'package:settly_mobile/main.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/services/notification_service.dart';
import 'package:settly_mobile/services/pwa_install.dart';
import 'package:settly_mobile/widgets/enable_notifications_button.dart';
import 'package:settly_mobile/widgets/user_avatar.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userInitials;
  final String? userAvatarUrl;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userInitials,
    this.userAvatarUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final texts = AppTexts.of(context);
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          texts.profileTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: UserAvatar(
                  radius: 48,
                  avatarUrl: userAvatarUrl,
                  initials: userInitials,
                  backgroundColor: AppColors.avatarBg(isDark),
                  foregroundColor: AppColors.avatarFg(isDark),
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.username(isDark),
                  ),
                ),
              ),
              const Spacer(),
              FutureBuilder<bool>(
                future: AuthService().isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminBroadcastPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.campaign_outlined),
                          label: Text(texts.adminBroadcastButton),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _AdminReminderButton(),
                      ),
                    ],
                  );
                },
              ),
              // Widoczne tylko, gdy push naprawdę nie działa (brak zgody albo
              // brak tokenu) — inaczej byłby to martwy przycisk.
              FutureBuilder<bool>(
                future: NotificationService().isEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.data != false) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EnableNotificationsButton(),
                  );
                },
              ),
              if (kIsWeb && !PwaInstall.isInstalled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (PwaInstall.canInstall) {
                        await PwaInstall.promptInstall();
                      } else if (context.mounted) {
                        // iOS / prompt not available → show the manual steps.
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            content: Text(texts.pwaInstallIosHint),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(texts.doneAction),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.install_mobile_outlined),
                    label: Text(texts.pwaInstallProfileOption),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () {
                    MyApp.of(context).changeLocale(
                      isEnglish ? const Locale('pl', 'PL') : const Locale('en'),
                    );
                  },
                  icon: const Icon(Icons.translate_rounded),
                  label: Text(texts.switchLanguageLabel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(texts.logoutButton),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amountNegative,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin: wyślij codzienne przypomnienie o rozliczeniach od razu, zamiast czekać
/// na 18:00. Backend zwraca liczbę powiadomionych osób, więc „nikt nic nie jest
/// winien" da się odróżnić od cichej awarii.
class _AdminReminderButton extends StatefulWidget {
  const _AdminReminderButton();

  @override
  State<_AdminReminderButton> createState() => _AdminReminderButtonState();
}

class _AdminReminderButtonState extends State<_AdminReminderButton> {
  bool _sending = false;

  Future<void> _trigger() async {
    final texts = AppTexts.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _sending = true);
    try {
      final response = await ApiServiceRequest().request(
        endpoint: 'notifications/settlement-reminder',
        method: HttpMethod.post,
      );

      if (!mounted) return;

      final ok = response != null &&
          (response.statusCode == 200 || response.statusCode == 202);
      if (!ok) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(texts.adminSettlementReminderFailed)),
          );
        return;
      }

      var reminded = 0;
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['reminded'] is int) {
          reminded = body['reminded'] as int;
        }
      } catch (_) {
        // brak czytelnego ciała — pokaż 0
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(texts.adminSettlementReminderSent(reminded))),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return OutlinedButton.icon(
      onPressed: _sending ? null : _trigger,
      icon: _sending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.alarm_on_outlined),
      label: Text(texts.adminSettlementReminderButton),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
