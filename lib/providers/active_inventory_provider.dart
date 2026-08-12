import 'dart:async';

import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'active_inventory_provider.g.dart';

/// Holds the ID of the currently selected inventory (pantry).
///
/// The value is persisted to [SharedPreferences] under the key
/// active_inventory_id so that the selection survives app restarts.
/// On initialization the provider reads the persisted value and validates
/// that the corresponding inventory still exists in the database. If the
/// persisted inventory was deleted, the provider falls back to the first
/// available inventory or, when no inventories exist, reseeds the default
/// "Home" inventory.
///
/// Defaults to 1 (the built‑in "Home" inventory created during migration)
/// on the very first run or when no persisted value is found.
@Riverpod(keepAlive: true)
class ActiveInventoryNotifier extends _$ActiveInventoryNotifier {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('active_inventory_id');
    final targetId = stored ?? 1;

    final inventories = await _fetchInventories();
    if (inventories == null) return targetId;

    final exists = inventories.any((i) => i['id'] == targetId);
    if (exists) return targetId;

    final resolvedId = _fallbackId(inventories);
    if (resolvedId != targetId) {
      unawaited(prefs.setInt('active_inventory_id', resolvedId));
    }
    return resolvedId;
  }

  /// Updates the active inventory ID and persists the change.
  void setActiveInventory(int id) {
    state = AsyncValue.data(id);
    unawaited(_persist(id));
  }

  /// Fetches all inventories, returning null when the DB is unavailable.
  Future<List<Map<String, dynamic>>?> _fetchInventories() async {
    try {
      final db = ref.read(databaseProvider);
      return await db.getInventories();
    } on Exception catch (e) {
      logWarning('Failed to load inventories during validation: $e');
      return null;
    }
  }

  /// Returns the first available inventory ID or reseeds the default.
  int _fallbackId(List<Map<String, dynamic>> inventories) {
    if (inventories.isNotEmpty) {
      return inventories.first['id'] as int;
    }
    unawaited(_reseedDefault());
    return 1;
  }

  /// Reseeds the default "Home" inventory when no inventories exist.
  Future<void> _reseedDefault() async {
    try {
      final db = ref.read(databaseProvider);
      await db.inventoriesDao.seedDefault(await db.database);
    } on Exception catch (e) {
      logWarning('Failed to reseed default inventory: $e');
    }
  }

  /// Persists the active inventory ID to SharedPreferences.
  Future<void> _persist(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_inventory_id', id);
    } on Exception catch (e) {
      logWarning('Failed to persist active inventory: $e');
    }
  }
}
