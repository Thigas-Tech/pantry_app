import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the ID of the currently selected inventory (pantry).
///
/// The value is persisted to [SharedPreferences] under the key
/// `active_inventory_id` so that the selection survives app restarts.
/// On initialization the provider reads the persisted value and validates
/// that the corresponding inventory still exists in the database. If the
/// persisted inventory was deleted, the provider falls back to the first
/// available inventory or, when no inventories exist, reseeds the default
/// "Home" inventory.
///
/// Defaults to `1` (the built‑in "Home" inventory created during migration)
/// on the very first run or when no persisted value is found.
class ActiveInventoryNotifier extends Notifier<int> {
  @override
  int build() {
    unawaited(_validateAndLoad());
    return 1;
  }

  /// The current active inventory ID.
  int get value => state;

  /// Updates the active inventory ID and persists the change.
  set value(int id) {
    state = id;
    unawaited(_persist(id));
  }

  /// Loads the persisted inventory ID and validates it against the database.
  ///
  /// If the persisted ID does not exist (inventory was deleted), falls back
  /// to the first available inventory or reseeds the default.
  Future<void> _validateAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('active_inventory_id');
      final targetId = stored ?? 1;

      final inventories = await _fetchInventories();
      if (inventories == null) return;

      final exists = inventories.any((i) => i['id'] == targetId);
      if (exists) {
        if (targetId != state) {
          state = targetId;
        }
        return;
      }

      final resolvedId = _fallbackId(inventories);
      unawaited(prefs.setInt('active_inventory_id', resolvedId));
      state = resolvedId;
    } catch (e) {
      logWarning('Failed to load persisted active inventory: $e');
    }
  }

  /// Fetches all inventories, returning `null` when the DB is unavailable.
  Future<List<Map<String, dynamic>>?> _fetchInventories() async {
    try {
      final db = ref.read(databaseProvider);
      final result = await db.getInventories();
      return result;
    } catch (_) {
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
    } catch (e) {
      logWarning('Failed to reseed default inventory: $e');
    }
  }

  /// Persists the active inventory ID to SharedPreferences.
  Future<void> _persist(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_inventory_id', id);
    } catch (e) {
      logWarning('Failed to persist active inventory: $e');
    }
  }
}

/// The provider for [ActiveInventoryNotifier].
final activeInventoryProvider = NotifierProvider<ActiveInventoryNotifier, int>(
  ActiveInventoryNotifier.new,
);
