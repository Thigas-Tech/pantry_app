import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/scan_history_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/utils/logger.dart';

/// Notifier that exposes the recent-scan history and its mutations.
///
/// The history is a bounded list of the latest successful scans (capped by
/// [ScanHistoryDao.defaultKeepCount]). Recording is delegated here so that
/// the scanner and the UI share a single refresh path.
class ScanHistory extends AsyncNotifier<List<ScanHistoryEntry>> {
  @override
  Future<List<ScanHistoryEntry>> build() {
    final db = ref.watch(databaseProvider);
    return db.getRecentScanHistory();
  }

  /// Records a successful scan and refreshes the provider state.
  ///
  /// Returns the inserted row id. The table is pruned to its cap inside
  /// [DatabaseHelper.recordScan].
  Future<int> record(ScanHistoryEntry entry) async {
    final db = ref.read(databaseProvider);
    final id = await db.recordScan(entry);
    ref.invalidateSelf();
    return id;
  }

  /// Adds the scanned product directly to the active inventory.
  ///
  /// Ensures a products row exists (so the inventory foreign key holds) by
  /// resolving the product from cache, then the network, and finally falling
  /// back to a manual snapshot built from the history entry. The inventory
  /// row is inserted with quantity 1 via
  /// [DatabaseHelper.insertOrMergeInventoryItem], so repeated quick-adds of
  /// the same barcode merge quantities instead of duplicating rows.
  Future<void> quickAdd(ScanHistoryEntry entry) async {
    final db = ref.read(databaseProvider);
    final activeInventoryId = ref.read(activeInventoryProvider);

    var product = await ref
        .read(productRepositoryProvider)
        .getProductFromCache(entry.barcode);
    if (product == null) {
      try {
        product = await ref
            .read(productRepositoryProvider)
            .getProduct(entry.barcode);
      } on Exception catch (e) {
        logWarning(
          'Quick-add could not resolve product ${entry.barcode}: $e',
        );
      }
    }

    await db.insertProduct(
      product ??
          Product(
            barcode: entry.barcode,
            name: entry.name,
            imageUrl: entry.imageUrl,
            source: 'manual',
          ),
    );

    await db.insertOrMergeInventoryItem(
      InventoryItem(
        barcode: entry.barcode,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
        inventoryId: activeInventoryId,
      ),
    );

    ref.invalidate(pantryProvider);
  }

  /// Deletes every history entry and refreshes the provider state.
  ///
  /// Returns the number of rows removed.
  Future<int> clear() async {
    final db = ref.read(databaseProvider);
    final cleared = await db.clearScanHistory();
    ref.invalidateSelf();
    return cleared;
  }
}

/// Provides the recent-scan history for the home screen.
final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistory, List<ScanHistoryEntry>>(
      ScanHistory.new,
    );
