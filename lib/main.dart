import 'package:flutter/material.dart';
import 'package:settly_mobile/pages/homePage.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('pl', null).then((_) => runApp(MyApp()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false);
  }
}
