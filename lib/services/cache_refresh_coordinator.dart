import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/utils/logger.dart';

/// Coordinates the background product-cache refresh at app startup.
///
/// Owns the refresh decision that used to live in main.dart:
///
/// 1. Skip entirely when the device has no connectivity.
/// 2. Skip when the cache is not overdue.
/// 3. Record the refresh timestamp *before* firing any refresh, so that
///    HomeScreen's overdue check sees a fresh cache and does not
///    duplicate the work.
/// 4. Refresh every inventory in parallel (rate-limit pacing lives inside
///    [ProductRepository.refreshInventoryProducts]).
///
/// A failing inventory refresh never aborts the others; partial results are
/// returned so callers can decide whether to invalidate the pantry UI.
class CacheRefreshCoordinator {
  /// Creates a coordinator with the repository, database, and a
  /// connectivity probe.
  ///
  /// The connectivity probe is a function so tests can control the
  /// connectivity decision without a real network check.
  CacheRefreshCoordinator({
    required this._repo,
    required this._db,
    required this._hasConnection,
  });

  final ProductRepository _repo;
  final DatabaseHelper _db;
  final Future<bool> Function() _hasConnection;

  /// Refreshes all inventories if online and overdue.
  ///
  /// Returns the total number of products refreshed across all inventories
  /// (0 when skipped offline, when the cache is fresh, or when there are no
  /// inventories). Individual inventory failures are logged and skipped.
  Future<int> refreshIfOverdue() async {
    if (!await _hasConnection()) {
      logInfo('Offline — skipping scheduled cache refresh');
      return 0;
    }
    if (!await _repo.isCacheOverdue()) {
      logInfo('Cache is fresh — skipping scheduled refresh');
      return 0;
    }

    // Set the timestamp before firing refreshes so concurrent overdue
    // checks (e.g. HomeScreen) see a fresh cache and do not duplicate.
    await _repo.setLastRefreshTime();

    final inventories = await _db.getInventories();
    final results = await Future.wait(
      inventories.map((inv) async {
        try {
          return await _repo.refreshInventoryProducts(inv['id'] as int);
        } on Exception catch (e) {
          logWarning('Inventory refresh failed: $e');
          return 0;
        }
      }),
    );
    final refreshed = results.fold<int>(0, (sum, count) => sum + count);
    logInfo('Refreshed products for ${inventories.length} inventories');
    return refreshed;
  }
}
