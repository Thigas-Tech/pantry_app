import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/scan_history_dao.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/providers/database_provider.dart';

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

/// Provides the recent-scan history recorded by successful scans.
final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistory, List<ScanHistoryEntry>>(
      ScanHistory.new,
    );
