import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/pages/admin_broadcast_page.dart';
import 'package:settly_mobile/main.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/auth_service.dart';
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
                  return Padding(
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
                  );
                },
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
