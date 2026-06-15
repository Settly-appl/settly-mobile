import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pinned_items/pinned_item.dart';
import '../models/expenses/single_expense.dart';
import '../services/api_service/api_service_request.dart';

class PinnedRepository {
  static const _key = 'pinned_ids_v2';
  static const int maxPinned = 6;

  static final PinnedRepository _instance = PinnedRepository._internal();
  factory PinnedRepository() => _instance;
  PinnedRepository._internal();

  // ── Odczyt tylko ID ────────────────────────────────────────────────────────
  Future<List<String>> getPinnedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // ── Pobieranie pełnych danych z API ───────────────────────────────────────
  Future<List<PinnedItem>> getAll(bool isDark) async {
    final ids = await getPinnedIds();
    if (ids.isEmpty) return [];

    final List<PinnedItem> fullItems = [];
    final List<String> validIds = [];

    final api = ApiServiceRequest();

    for (final id in ids) {
      final response = await api.request(
        endpoint: 'expenses/$id',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final expense = SingleExpense.fromJson(data);

        // ZMIANA: Używamy nowej fabryki fromExpense z SingleExpense
        fullItems.add(PinnedItem.fromExpense(expense, isDark));
        validIds.add(id);
      } else if (response != null && response.statusCode == 404) {
        // Komunikat tylko do logów - przetłumaczony na polski
        print('Nie znaleziono elementu $id w bazie, pomijam.');
      } else {
        validIds.add(id);
      }
    }

    if (validIds.length != ids.length) {
      await _saveIds(validIds);
    }

    return fullItems;
  }

  Future<bool> pin(String id) async {
    final ids = await getPinnedIds();
    if (ids.contains(id)) return true;
    if (ids.length >= maxPinned) return false;

    ids.add(id);
    await _saveIds(ids);
    return true;
  }

  Future<void> unpin(String id) async {
    final ids = await getPinnedIds();
    ids.remove(id);
    await _saveIds(ids);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final ids = await getPinnedIds();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex >= ids.length)
      return;

    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    await _saveIds(ids);
  }

  Future<bool> isPinned(String id) async {
    final ids = await getPinnedIds();
    return ids.contains(id);
  }

  Future<void> _saveIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids);
  }
}
