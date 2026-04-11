import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userInitials;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userInitials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil',
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
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.avatarBg(isDark),
                  child: Text(
                    userInitials,
                    style: TextStyle(
                      color: AppColors.avatarFg(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
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
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Wyloguj się'),
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
