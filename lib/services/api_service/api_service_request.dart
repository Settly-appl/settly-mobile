import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:settly_mobile/const/api_url.dart';
import 'package:settly_mobile/services/auth_service.dart';

enum HttpMethod { get, post, put, patch, delete }

class ApiServiceRequest {
  Future<http.Response?> request({
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? body, // Dane do JSONa (POST/PUT)
    Map<String, String>? queryParams, // Dane do URL (GET/DELETE)
  }) async {
    var url = Uri.parse('${ProjectApiConst.baseUrl}/$endpoint');
    if (queryParams != null) {
      url = url.replace(queryParameters: queryParams);
    }

    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      var response = await _send(url, method, encodedBody);

      // Access token expired — refresh once and retry.
      if (response.statusCode == 401) {
        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) {
          response = await _send(url, method, encodedBody);
        }
      }

      return response;
    } catch (e) {
      print("Błąd połączenia: $e");
      return null;
    }
  }

  Future<http.Response> _send(
    Uri url,
    HttpMethod method,
    String? encodedBody,
  ) async {
    final token = await AuthService().getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };

    switch (method) {
      case HttpMethod.get:
        return http.get(url, headers: headers);
      case HttpMethod.post:
        return http.post(url, headers: headers, body: encodedBody);
      case HttpMethod.put:
        return http.put(url, headers: headers, body: encodedBody);
      case HttpMethod.patch:
        return http.patch(url, headers: headers, body: encodedBody);
      case HttpMethod.delete:
        return http.delete(url, headers: headers, body: encodedBody);
    }
  }
}
