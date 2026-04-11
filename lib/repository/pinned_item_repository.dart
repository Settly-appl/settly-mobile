import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pinned_item.dart';

class PinnedRepository {
  static const _key = 'pinned_items_v1';
  static const int maxPinned = 6;

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final PinnedRepository _instance = PinnedRepository._internal();
  factory PinnedRepository() => _instance;
  PinnedRepository._internal();

  // ── Odczyt ─────────────────────────────────────────────────────────────────
  Future<List<PinnedItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => PinnedItem.fromJson(jsonDecode(s))).toList();
  }

  // ── Zapis ──────────────────────────────────────────────────────────────────
  /// Dodaje element do pinned. Jeśli już istnieje (ten sam id) — aktualizuje.
  /// Zwraca false jeśli osiągnięto limit MAX_PINNED.
  Future<bool> pin(PinnedItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAll();

    // Sprawdź czy już przypięty — jeśli tak, aktualizuj
    final existingIdx = current.indexWhere((e) => e.id == item.id);
    if (existingIdx != -1) {
      current[existingIdx] = item;
      await _save(prefs, current);
      return true;
    }

    // Sprawdź limit
    if (current.length >= maxPinned) return false;

    current.add(item);
    await _save(prefs, current);
    return true;
  }

  /// Usuwa element z pinned po id.
  Future<void> unpin(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAll();
    current.removeWhere((e) => e.id == id);
    await _save(prefs, current);
  }

  /// Zmienia kolejność (drag & drop w edycji).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAll();
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length)
      return;

    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    await _save(prefs, current);
  }

  /// Sprawdza czy dany id jest przypięty.
  Future<bool> isPinned(String id) async {
    final current = await getAll();
    return current.any((e) => e.id == id);
  }

  // ── Prywatne ───────────────────────────────────────────────────────────────
  Future<void> _save(SharedPreferences prefs, List<PinnedItem> items) async {
    await prefs.setStringList(
      _key,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
