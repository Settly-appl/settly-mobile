import 'dart:convert';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

class ExpenseRepository {
  final _api = ApiServiceRequest();

  Future<String?> fetchUserShareForExpense({
    required String expenseId,
    required String currency,
  }) async {
    try {
      final response = await _api.request(
        endpoint: 'expenses/$expenseId/userShare',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final amount = data['amount']?.toString() ?? '';
        final currency = data['currency']?.toString() ?? 'PLN';

        if (amount.isNotEmpty) {
          return '$amount $currency';
        }
      }
    } catch (_) {
      // Jeśli pobieranie się nie powiedzie, zwróć null
    }

    return null;
  }
}
