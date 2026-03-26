import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';

class SingleExpenseAddPage extends StatefulWidget {
  @override
  _SingleExpenseAddPageState createState() => _SingleExpenseAddPageState();
}

class _SingleExpenseAddPageState extends State<SingleExpenseAddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nowy wydatek',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.greetingLight,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(child: Text('Tutaj formularz wydatku')),
    );
  }
}
