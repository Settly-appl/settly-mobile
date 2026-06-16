import '../../const/app_texts.dart';

enum ExpenseSplitsType {
  EQUAL,
  BY_ITEM,
  CUSTOM;

  static ExpenseSplitsType fromString(String value) {
    return ExpenseSplitsType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ExpenseSplitsType.EQUAL,
    );
  }

  String localizedLabel(AppTexts texts) {
    switch (this) {
      case ExpenseSplitsType.EQUAL:
        return texts.splitModeEqual;
      case ExpenseSplitsType.BY_ITEM:
        return texts.splitModeByItem;
      case ExpenseSplitsType.CUSTOM:
        return texts.splitModeCustom;
    }
  }
}
