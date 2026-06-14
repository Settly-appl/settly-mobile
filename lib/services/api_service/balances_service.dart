import 'dart:convert';

import 'package:settly_mobile/models/debt_record.dart';
import 'package:settly_mobile/models/friend_balance.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Wraps the balances/debts endpoints:
///  - GET  /balances            net balance per counterparty (optionally per project)
///  - POST /debts/settle        settle up everything a debtor owes the current user
///  - GET  /debts               settlement history
class BalancesService {
  final ApiServiceRequest _api = ApiServiceRequest();

  /// Net balances between the current user and friends. Positive = they owe you.
  Future<List<FriendBalance>> getBalances({String? projectId}) async {
    final response = await _api.request(
      endpoint: 'balances',
      method: HttpMethod.get,
      queryParams: projectId != null ? {'projectId': projectId} : null,
    );

    if (response != null && response.statusCode == 200) {
      return FriendBalance.listFromJson(
        jsonDecode(response.body) as List<dynamic>,
      );
    }
    throw Exception('Nie udało się pobrać sald');
  }

  /// Settle up everything [debtorUserId] owes the current user. Only the
  /// creditor (current user) may do this.
  Future<DebtRecord> settleUp({
    required String debtorUserId,
    String? projectId,
  }) async {
    final response = await _api.request(
      endpoint: 'debts/settle',
      method: HttpMethod.post,
      body: {'debtorUserId': debtorUserId, 'projectId': ?projectId},
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      return DebtRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Nie udało się rozliczyć');
  }

  /// The current user's settlement history (as debtor or creditor).
  Future<List<DebtRecord>> getHistory() async {
    final response = await _api.request(
      endpoint: 'debts',
      method: HttpMethod.get,
    );

    if (response != null && response.statusCode == 200) {
      return DebtRecord.listFromJson(jsonDecode(response.body) as List<dynamic>);
    }
    throw Exception('Nie udało się pobrać historii');
  }
}
