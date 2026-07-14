import 'package:settly_mobile/const/app_texts.dart';

/// Mapuje surowy identyfikator kategorii z API (`food`, `shopping`, `others`…)
/// na czytelną, przetłumaczoną etykietę.
///
/// Identyfikatory są stałym zbiorem — patrz `_kCategories` w
/// `expense_form_page.dart`. Nigdy nie pokazuj surowego id użytkownikowi:
/// to właśnie powodowało angielskie kategorie na stronie głównej.
String localizedCategoryLabel(String rawCategory, AppTexts texts) {
  switch (rawCategory.toLowerCase()) {
    case 'food':
      return texts.expensesLabelFood;
    case 'transport':
      return texts.expensesLabelTransport;
    case 'shopping':
      return texts.expensesLabelShopping;
    case 'entertainment':
      return texts.categoryEntertainmentLabel;
    case 'health':
      return texts.categoryHealthLabel;
    case 'subscriptions':
      return texts.categorySubscriptionsLabel;
    case 'others':
    case 'other':
      return texts.expensesLabelOther;
    default:
      return rawCategory;
  }
}
