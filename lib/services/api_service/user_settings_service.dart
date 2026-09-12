import 'dart:convert';

import 'package:settly_mobile/services/api_service/api_service_request.dart';
import 'package:settly_mobile/utils/money_format.dart';

/// Ustawienia użytkownika — na razie wyłącznie waluta bazowa.
class UserSettings {
  /// Waluta, w której raportowane są salda i sumy.
  final String baseCurrency;

  /// Waluty obsługiwane przez backend. Serwowane, a nie zaszyte w kliencie,
  /// żeby picker i walidacja nigdy się nie rozjechały.
  final List<String> supportedCurrencies;

  const UserSettings({
    required this.baseCurrency,
    this.supportedCurrencies = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final supported = json['supportedCurrencies'];
    return UserSettings(
      baseCurrency: json['baseCurrency']?.toString() ?? kDefaultCurrency,
      supportedCurrencies: supported is List
          ? supported.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

/// Opakowuje `GET/PUT /users/me/settings`.
class UserSettingsService {
  final ApiServiceRequest _api = ApiServiceRequest();

  /// Ostatnio znana waluta bazowa.
  ///
  /// Trzymana statycznie, bo ekrany zbiorcze (salda, sumy, historia) formatują
  /// kwoty synchronicznie w `build`, a przeciąganie tam asynchronicznego stanu
  /// oznaczałoby kilka dodatkowych zapytań na każde wejście. Odświeżamy przy
  /// starcie i po każdej zmianie ustawień; do czasu pierwszej odpowiedzi
  /// obowiązuje domyślne PLN — to zła etykieta w najgorszym razie, nigdy zła
  /// kwota, bo przeliczenia robi backend.
  static String baseCurrency = kDefaultCurrency;

  Future<UserSettings> fetch() async {
    final response = await _api.request(
      endpoint: 'users/me/settings',
      method: HttpMethod.get,
    );

    if (response != null && response.statusCode == 200) {
      final settings = UserSettings.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      baseCurrency = settings.baseCurrency;
      return settings;
    }
    throw Exception('Nie udało się pobrać ustawień');
  }

  Future<UserSettings> updateBaseCurrency(String code) async {
    final response = await _api.request(
      endpoint: 'users/me/settings',
      method: HttpMethod.put,
      body: {'baseCurrency': code},
    );

    if (response != null && response.statusCode == 200) {
      final settings = UserSettings.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      baseCurrency = settings.baseCurrency;
      return settings;
    }
    throw Exception('Nie udało się zapisać waluty bazowej');
  }
}
