/// Formatowanie kwot wraz z walutą.
///
/// Powstało dlatego, że ekrany zbiorcze (salda, sumy projektów, historia
/// rozliczeń) miały `zł` wpisane na sztywno. Dopóki wszystko było w złotówkach,
/// nie było tego widać; przy wydatku w funtach ta sama liczba zaczyna kłamać.
/// Każde miejsce pokazujące pieniądze powinno przechodzić przez [formatMoney] i
/// podawać walutę jawnie — brak waluty to teraz błąd kompilacji, a nie cicha
/// pomyłka.
library;

/// Waluty obsługiwane przez aplikację. Jedno źródło prawdy dla pickera w
/// formularzu wydatku, ustawień profilu i walidacji po stronie backendu
/// (`CurrencyConversionService.SUPPORTED`) — listy nie mogą się rozjechać.
const List<Map<String, String>> kCurrencies = [
  {'code': 'PLN', 'symbol': 'zł', 'name': 'Złoty polski'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'USD', 'symbol': '\$', 'name': 'Dolar amerykański'},
  {'code': 'GBP', 'symbol': '£', 'name': 'Funt brytyjski'},
];

const String kDefaultCurrency = 'PLN';

/// Symbol waluty; dla nieznanego kodu zwracamy sam kod, żeby kwota nigdy nie
/// została pokazana bez oznaczenia.
String currencySymbol(String? code) {
  if (code == null || code.isEmpty) return kCurrencies.first['symbol']!;
  for (final c in kCurrencies) {
    if (c['code'] == code) return c['symbol']!;
  }
  return code;
}

/// Kwota z dwoma miejscami po przecinku i symbolem waluty: `60.63 zł`, `12.50 £`.
String formatMoney(num amount, String? currency, {int decimals = 2}) {
  return '${amount.toStringAsFixed(decimals)} ${currencySymbol(currency)}';
}

/// Kwota bez części dziesiętnej — do kafelków podsumowań, gdzie liczy się rząd
/// wielkości, a nie grosze.
String formatMoneyRounded(num amount, String? currency) {
  return '${amount.toStringAsFixed(0)} ${currencySymbol(currency)}';
}

/// Kwota w walucie wydatku z przelicznikiem w nawiasie, gdy wydatek był w innej
/// walucie niż bazowa: `12.50 £ (~60.63 zł)`. Gdy waluty są te same, drugi
/// człon tylko powtarzałby pierwszy, więc go pomijamy.
String formatMoneyWithBase(
  num amount,
  String? currency,
  num? baseAmount,
  String? baseCurrency,
) {
  final native = formatMoney(amount, currency);
  if (baseAmount == null ||
      baseCurrency == null ||
      baseCurrency == currency) {
    return native;
  }
  return '$native (~${formatMoney(baseAmount, baseCurrency)})';
}

/// Przelicza kwotę po kursie, którym użytkownik kupił walutę. Kierunek jest tu
/// jedyną rzeczą, którą łatwo pomylić: [rateToBase] to ile jednostek waluty
/// bazowej kosztuje **jedna** jednostka waluty wydatku (1 GBP = 4.85 PLN → 4.85).
double convertToBase(double amount, double rateToBase) {
  return double.parse((amount * rateToBase).toStringAsFixed(2));
}
