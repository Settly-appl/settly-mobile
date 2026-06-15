import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:settly_mobile/const/app_texts.dart';

void main() {
  testWidgets('App texts are localized for Polish', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl', 'PL'),
        supportedLocales: const [Locale('pl', 'PL'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) =>
              Scaffold(body: Text(AppTexts.of(context).loginButton)),
        ),
      ),
    );

    expect(find.text('Zaloguj się'), findsOneWidget);
  });

  testWidgets('App texts are localized for English', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('pl', 'PL'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) =>
              Scaffold(body: Text(AppTexts.of(context).loginButton)),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });
}
