import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:settly_mobile/app_navigator.dart';
import 'package:settly_mobile/firebase_web_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settly_mobile/pages/main_pages/home_page.dart';
import 'package:settly_mobile/pages/main_pages/login_page.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/services/notification_service.dart';
import 'package:settly_mobile/services/notifications_store.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Background/terminated-state handler. The OS renders the notification from
/// the FCM payload automatically; this just needs to exist and be an entry point.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().init();
  }
  await Future.wait([
    initializeDateFormatting('pl_PL', null),
    initializeDateFormatting('en_US', null),
  ]);
  runApp(const MyApp());

  // Web push (opt-in): set up AFTER the first frame so nothing — Firebase init,
  // the permission prompt, or token fetch — can block the UI from painting.
  // Fire-and-forget; the JS service worker (web/firebase-messaging-sw.js)
  // handles background messages, not Dart.
  if (kIsWeb && kFirebaseWebConfigured) {
    Firebase.initializeApp(options: kFirebaseWebOptions)
        .then((_) => NotificationService().init())
        .catchError((Object e) {
          debugPrint('Web push init skipped: $e');
        });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('pl', 'PL');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language');
    if (!mounted) return;

    setState(() {
      _locale = languageCode == 'en'
          ? const Locale('en')
          : const Locale('pl', 'PL');
    });
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  Future<void> changeLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    if (!mounted) return;
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pl', 'PL'), Locale('en')],
      locale: _locale,
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
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      await _loadUserData();
      // Fire-and-forget: token registration must never block showing the app.
      unawaited(NotificationService().registerCurrentToken());
      // Skrzynka z backendu: pokazuje też powiadomienia, których push nie dowiózł.
      unawaited(NotificationsStore().refresh());
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
      final picture = info['picture'] as String?;
      _userAvatarUrl = (picture != null && picture.isNotEmpty) ? picture : null;
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
    unawaited(NotificationService().registerCurrentToken());
    unawaited(NotificationsStore().refresh());
    if (mounted) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _onLogout() async {
    // Remove this device's token while the access token is still valid.
    await NotificationService().unregisterCurrentToken();
    // Drop the previous user's in-app notifications so the next account starts clean.
    NotificationsStore().clear();
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = '';
        _userInitials = '';
        _userAvatarUrl = null;
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
      userAvatarUrl: _userAvatarUrl,
      onLogout: _onLogout,
    );
  }
}
