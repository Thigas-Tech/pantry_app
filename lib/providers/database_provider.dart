import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/store.dart';

/// Provides the singleton [DatabaseHelper] instance to the widget tree.
///
/// Because [DatabaseHelper] is already a singleton (factory constructor),
/// this provider simply returns that same instance. It is registered as a
/// [Provider] (not a [FutureProvider]) because the database is lazily
/// initialised on first access and does not require asynchronous setup
/// before the UI can render.
///
/// ## Usage
///
/// - `ref.watch(databaseProvider)` in widgets that need access to the
///   database (usually via repository providers).
/// - `ref.read(databaseProvider)` in async callbacks.
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Lists all saved stores alphabetically for autocomplete suggestions.
final FutureProvider<List<Store>> storesProvider =
    FutureProvider.autoDispose<List<Store>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.getAllStores();
    });
