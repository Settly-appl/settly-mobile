import 'dart:convert';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:http/http.dart' as http;
import 'package:settly_mobile/const/api_url.dart';
import 'package:settly_mobile/services/auth_service.dart';

class SingleExpenseApi {
  final _authService = AuthService();

  Future<bool> sendExpense(ExpenseRequest expense) async {
    final url = Uri.parse('${ProjectApiConst.baseUrl}/expenses');
    final token = await _authService.getAccessToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Wydatek wysłany pomyślnie!");
        return true;
      } else {
        print("Błąd backendu: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Błąd połączenia: $e");
      return false;
    }
  }
}
