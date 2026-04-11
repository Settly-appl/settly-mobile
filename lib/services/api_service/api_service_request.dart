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

    final token = await AuthService().getAccessToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
    // if (body != null) {
    //   print("Body: ${jsonEncode(body)}");
    // }

    try {
      http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await http.get(url, headers: headers);
          break;
        case HttpMethod.post:
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.put:
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.patch:
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.delete:
          response = await http.delete(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
      }

      return response;
    } catch (e) {
      print("Błąd połączenia: $e");
      return null;
    }
  }
}
