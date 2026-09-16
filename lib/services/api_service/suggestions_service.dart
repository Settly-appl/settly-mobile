import 'dart:convert';

import 'package:settly_mobile/models/suggestion.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Opakowuje `/suggestions`:
///  - POST — może każdy zalogowany,
///  - GET  — tylko admin (pilnuje tego backend, nie ukrycie przycisku).
class SuggestionsService {
  final ApiServiceRequest _api = ApiServiceRequest();

  Future<void> send(String content) async {
    final response = await _api.request(
      endpoint: 'suggestions',
      method: HttpMethod.post,
      body: {'content': content},
    );
    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 201)) {
      throw Exception('Nie udało się wysłać sugestii');
    }
  }

  Future<List<Suggestion>> getAll() async {
    final response = await _api.request(
      endpoint: 'suggestions',
      method: HttpMethod.get,
    );
    if (response != null && response.statusCode == 200) {
      return Suggestion.listFromJson(
        jsonDecode(response.body) as List<dynamic>,
      );
    }
    throw Exception('Nie udało się pobrać sugestii');
  }
}
