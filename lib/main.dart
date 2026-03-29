import 'package:flutter/material.dart';
import 'package:settly_mobile/pages/main_pages/home_page.dart';
import 'package:settly_mobile/pages/main_pages/login_page.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pl', 'PL')],
      locale: const Locale('pl', 'PL'),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.scaffold(false),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffold(true),
      ),
      themeMode: _themeMode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isChecking = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      await _loadUserData();
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isChecking = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final info = await _authService.getUserInfo();
    if (info != null) {
      final firstName = info['given_name'] as String? ?? '';
      final lastName = info['family_name'] as String? ?? '';
      final name =
          info['name'] as String? ??
          info['preferred_username'] as String? ??
          '';

      _userName = firstName.isNotEmpty ? firstName : name;
      _userInitials = _buildInitials(firstName, lastName, name);
    }
  }

  String _buildInitials(String firstName, String lastName, String fallback) {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (fallback.isNotEmpty) return fallback[0].toUpperCase();
    return '?';
  }

  Future<void> _onLoginSuccess() async {
    await _loadUserData();
    if (mounted) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _onLogout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = '';
        _userInitials = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _onLoginSuccess);
    }

    return HomePage(
      userName: _userName,
      userInitials: _userInitials,
      onLogout: _onLogout,
    );
  }
}
