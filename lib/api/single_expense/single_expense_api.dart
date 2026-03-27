import 'dart:convert';
import 'package:settly_mobile/dto/expense_request.dart';
import 'package:http/http.dart' as http;
import 'package:settly_mobile/const/api_url.dart';

class SingleExpenseApi {
  Future<bool> sendExpense(ExpenseRequest expense) async {
    final url = Uri.parse('${ProjectApiConst.baseUrl}/expenses');
    //final url = Uri.parse('http://localhost:8080/api/expenses');
    //final String tokenPostman = "wL4TwfN-0QEHkPaR8vMfTTC9gQpQbQ";

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Tutaj możesz dodać np. Bearer Token jeśli masz logowanie
          //'Authorization': 'Bearer $tokenPostman',
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
