import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/utils/logger.dart';

/// Result of a single sync attempt.
class SyncResult {
  /// Creates a [SyncResult].
  const SyncResult({
    required this.synced,
    required this.failed,
    this.errorMessage,
  });

  /// Number of prices successfully synced.
  final int synced;

  /// Number of prices that failed to sync.
  final int failed;

  /// An optional error message if the entire sync failed.
  final String? errorMessage;

  /// Whether any prices were synced.
  bool get hasChanges => synced > 0 || failed > 0;
}

/// Service for synchronising local prices with the Open Prices community
/// database.
///
/// ## Current limitations
///
/// The Open Prices API requires a proof photo (receipt or shelf label) for
/// every price write. Until the app supports receipt capture (via NFC-e or
/// manual camera), the service marks prices as `synced` locally without
/// making HTTP requests. This is a placeholder for the future full
/// implementation.
///
/// ## Future implementation
///
/// When proof upload is available, the sync flow will be:
/// 1. Upload the proof photo → get `proof_id`.
/// 2. Create the price with `proof_id`.
/// 3. Store the returned `open_prices_id`.
/// 4. Mark as `synced`.
class OpenPricesService {
  /// Creates an [OpenPricesService].
  OpenPricesService({
    required DatabaseHelper databaseHelper,
  }) : _db = databaseHelper;

  final DatabaseHelper _db;

  /// Syncs all pending prices to Open Prices.
  ///
  /// In the current MVP, this marks pending prices as synced locally and
  /// logs the result. No HTTP requests are made.
  ///
  /// When proof capture is implemented, this will:
  /// 1. Skip prices with [priceSyncLocalOnly] status.
  /// 2. Upload proof image for [priceSyncPending] prices.
  /// 3. Create price on the Open Prices API.
  /// 4. Update syncStatus and openPricesId on success.
  Future<SyncResult> syncPendingPrices() async {
    final pending = await _db.getPricesBySyncStatus(priceSyncPending);

    if (pending.isEmpty) {
      logInfo('No pending prices to sync');
      return const SyncResult(synced: 0, failed: 0);
    }

    logInfo(
      'Open Prices sync: ${pending.length} pending prices '
      '(proof upload not yet implemented — marking as synced locally)',
    );

    var synced = 0;
    var failed = 0;

    for (final price in pending) {
      try {
        // TODO(capture-proof): implement proof upload and price creation
        // via OpenPricesAPIClient when receipt capture is available.
        // For now, mark as synced locally as a placeholder.
        final updated = price.copyWith(
          syncStatus: priceSyncSynced,
        );
        await _db.updatePrice(updated);
        synced++;
        logInfo(
          'Price ${price.id} marked as synced (placeholder)',
        );
      } on Exception catch (e) {
        logError('Failed to sync price ${price.id}: $e');
        try {
          await _db.updatePrice(
            price.copyWith(syncStatus: priceSyncFailed),
          );
        } on Exception catch (_) {}
        failed++;
      }
    }

    logInfo(
      'Open Prices sync finished: $synced synced, $failed failed',
    );
    return SyncResult(synced: synced, failed: failed);
  }

  /// Validates that [token] is a non-empty string.
  ///
  /// Full validation against the Open Prices API requires a network call
  /// (e.g. calling `GET /v1/session` with the token). That will be added
  /// when the actual API integration is implemented.
  bool validateToken(String token) {
    return token.trim().isNotEmpty;
  }
}
