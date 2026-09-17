import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pinned_items/pinned_item.dart';
import '../models/expenses/single_expense.dart';
import '../models/project.dart';
import '../services/api_service/api_service_request.dart';

class PinnedRepository {
  /// Klucze typowane: `expense:<uuid>` / `project:<uuid>`.
  ///
  /// v2 trzymało same id i `getAll` zawsze pytało o `expenses/<id>`, więc
  /// przypięcie czegokolwiek innego nie miało jak zadziałać. Nowy klucz, bo
  /// stare wpisy trzeba odczytać jako wydatki — migracja niżej robi to raz.
  static const _key = 'pinned_v3';
  static const _legacyKey = 'pinned_ids_v2';
  static const int maxPinned = 6;

  static String _keyFor(String id, PinnedItemType type) => '${type.name}:$id';

  static String _idOf(String key) {
    final i = key.indexOf(':');
    return i == -1 ? key : key.substring(i + 1);
  }

  static PinnedItemType _typeOf(String key) {
    final i = key.indexOf(':');
    // Wpis bez prefiksu pochodzi sprzed typowania — to zawsze był wydatek.
    if (i == -1) return PinnedItemType.expense;
    return key.startsWith('project:')
        ? PinnedItemType.project
        : PinnedItemType.expense;
  }

  /// Pełne klucze (z typem). Do środka repozytorium, nie do UI.
  Future<List<String>> _getPinnedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key);
    if (current != null) return current;

    // Jednorazowa migracja: co było przypięte w v2, było wydatkiem.
    final legacy = prefs.getStringList(_legacyKey) ?? [];
    final migrated = [
      for (final id in legacy) _keyFor(id, PinnedItemType.expense),
    ];
    await prefs.setStringList(_key, migrated);
    return migrated;
  }

  static final PinnedRepository _instance = PinnedRepository._internal();
  factory PinnedRepository() => _instance;
  PinnedRepository._internal();

  // ── Odczyt tylko ID ────────────────────────────────────────────────────────
  /// Same identyfikatory, bez prefiksu typu — UI sprawdza nimi „czy przypięte".
  /// Id są UUID-ami, więc wydatek i projekt nie mogą się tu zderzyć.
  Future<List<String>> getPinnedIds() async {
    return (await _getPinnedKeys()).map(_idOf).toList();
  }

  // ── Pobieranie pełnych danych z API ───────────────────────────────────────
  Future<List<PinnedItem>> getAll(bool isDark) async {
    final keys = await _getPinnedKeys();
    if (keys.isEmpty) return [];

    final List<PinnedItem> fullItems = [];
    final List<String> validKeys = [];

    final api = ApiServiceRequest();

    for (final key in keys) {
      final id = _idOf(key);
      final isProject = _typeOf(key) == PinnedItemType.project;

      final response = await api.request(
        endpoint: isProject ? 'projects/$id' : 'expenses/$id',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (isProject) {
          final project = Project.fromJson(data as Map<String, dynamic>);
          fullItems.add(
            PinnedItem.fromProject(
              projectId: project.id,
              name: project.name,
              description: project.description ?? '',
              totalAmount: project.totalAmount.toStringAsFixed(2),
              currency: project.totalCurrency,
              membersCount: project.memberCount,
            ),
          );
        } else {
          fullItems.add(PinnedItem.fromExpense(SingleExpense.fromJson(data), isDark));
        }
        validKeys.add(key);
      } else if (response != null && response.statusCode == 404) {
        // Usunięte po drugiej stronie — wypada z przypiętych zamiast wracać
        // jako błąd przy każdym wejściu na główną.
        print('Nie znaleziono elementu $key w bazie, pomijam.');
      } else {
        // Błąd sieci: zostawiamy przypięcie, bo to nie dowód, że zniknęło.
        validKeys.add(key);
      }
    }

    if (validKeys.length != keys.length) {
      await _saveIds(validKeys);
    }

    return fullItems;
  }

  Future<bool> pin(
    String id, {
    PinnedItemType type = PinnedItemType.expense,
  }) async {
    final keys = await _getPinnedKeys();
    final key = _keyFor(id, type);
    if (keys.contains(key)) return true;
    if (keys.length >= maxPinned) return false;

    keys.add(key);
    await _saveIds(keys);
    return true;
  }

  /// Odpina po samym id — wywołujący nie musi pamiętać typu, a UUID-y się nie
  /// powtarzają między wydatkami a projektami.
  Future<void> unpin(String id) async {
    final keys = await _getPinnedKeys();
    keys.removeWhere((key) => _idOf(key) == id);
    await _saveIds(keys);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final ids = await _getPinnedKeys();
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
    return (await getPinnedIds()).contains(id);
  }

  Future<void> _saveIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids);
  }
}
