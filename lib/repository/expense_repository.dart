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

  /// Rozlicza / cofa rozliczenie całego wydatku. Właściciel rozlicza wszystkich
  /// uczestników, uczestnik tylko swoją część. Backend jest idempotentny.
  Future<SettleResult> setExpenseSettled({
    required String expenseId,
    required bool settled,
  }) {
    return _send('expenses/$expenseId/${settled ? 'settle' : 'unsettle'}');
  }

  /// Rozlicza / cofa rozliczenie pojedynczej osoby w wydatku.
  Future<SettleResult> setSplitSettled({
    required String expenseId,
    required String splitId,
    required bool settled,
  }) {
    return _send(
      'expenses/$expenseId/splits/$splitId/${settled ? 'settle' : 'unsettle'}',
    );
  }

  /// Cofa zbiorcze rozliczenie: przywraca wszystkie objęte nim udziały i usuwa
  /// wpis z historii, żeby saldo i historia płatności się zgadzały.
  Future<SettleResult> undoSettleUp(String debtId) {
    return _send('debts/$debtId', method: HttpMethod.delete);
  }

  Future<SettleResult> _send(
    String endpoint, {
    HttpMethod method = HttpMethod.patch,
  }) async {
    try {
      final response = await _api.request(endpoint: endpoint, method: method);
      if (response == null) return SettleResult.failed;

      final code = response.statusCode;
      if (code == 200 || code == 201 || code == 204) return SettleResult.ok;

      // 409: udział został rozliczony zbiorczo — nie wolno cofnąć go osobno.
      if (code == 409) return SettleResult.lockedBySettleUp;

      return SettleResult.failed;
    } catch (_) {
      return SettleResult.failed;
    }
  }
}

/// Wynik zmiany rozliczenia.
///
/// [lockedBySettleUp] to ważny przypadek: udział został rozliczony zbiorczo na
/// stronie „Rozliczenia”, więc pieniądze naprawdę zostały przekazane. Cofnięcie
/// tylko tego jednego udziału wskrzesiłoby saldo za zapłacone pieniądze —
/// backend (409) tego zabrania. Trzeba cofnąć całe rozliczenie.
enum SettleResult { ok, lockedBySettleUp, failed }
