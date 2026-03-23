import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settly_mobile/pages/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Ta metoda pozwoli nam znaleźć stan MyApp w dowolnym miejscu aplikacji
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Domyślnie ustawiamy na systemowy
  ThemeMode _themeMode = ThemeMode.system;

  // Funkcja do zmiany motywu
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: const HomePage(),
    );
  }
}
