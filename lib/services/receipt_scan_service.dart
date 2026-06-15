import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:settly_mobile/services/auth_service.dart';
import 'package:settly_mobile/const/api_url.dart';

class ScanReceiptResult {
  final String currency;
  final String category;
  final double totalAmount;

  ScanReceiptResult({
    required this.currency,
    required this.category,
    required this.totalAmount,
  });

  factory ScanReceiptResult.fromJson(Map<String, dynamic> json) {
    return ScanReceiptResult(
      currency: json['currency'] as String? ?? 'PLN',
      category: json['category'] as String? ?? 'others',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReceiptScanService {
  static const String _endpoint = 'ai/singleExpense';
  final _imagePicker = ImagePicker();

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      // Log po polsku
      print('Błąd przy wybieraniu zdjęcia: $e');
      return null;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      // Log po polsku
      print('Błąd przy wybieraniu zdjęcia z galerii: $e');
      return null;
    }
  }

  Future<ScanReceiptResult?> scanReceipt(File imageFile) async {
    try {
      final token = await AuthService().getAccessToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ProjectApiConst.baseUrl}/$_endpoint'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      });

      request.files.add(
        await http.MultipartFile.fromPath('receipt', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) {
          return await scanReceipt(imageFile);
        }
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanReceiptResult.fromJson(jsonData);
      } else {
        print('Błąd podczas skanowania paragonu: ${response.statusCode}');
        print('Odpowiedź serwera: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Błąd w scanReceipt: $e');
      return null;
    }
  }
}
