import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';
import 'package:pantry_app/utils/logger.dart';

export 'open_prices_api_client.dart'
    show FetchPricesResult, RemotePrice, SubmitPriceResult;

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
/// ## Token-based auth
///
/// The service reads the Bearer token from [OpenPricesApiClient] which
/// defaults to the configured token (from .env or shared preferences).
/// If the token is empty, all API operations return empty/error results
/// and the app works in local-only mode.
///
/// ## Sync flow
///
/// 1. Upload the proof photo (TODO — blocked by receipt capture).
/// 2. Create the price with proof_id.
/// 3. Store the returned open_prices_id.
/// 4. Mark as synced.
class OpenPricesService {
  /// Creates an [OpenPricesService].
  OpenPricesService({
    required DatabaseHelper databaseHelper,
    OpenPricesApiClient? apiClient,
  }) : _db = databaseHelper,
       _api = apiClient ?? OpenPricesApiClient();

  final DatabaseHelper _db;
  final OpenPricesApiClient _api;

  /// Fetches prices for the given [barcode] from the Open Prices API.
  ///
  /// Returns the API result, or an empty result on error or when no
  /// token is configured.
  Future<FetchPricesResult> fetchPricesByBarcode(String barcode) async {
    if (!_api.hasToken) {
      return const FetchPricesResult(prices: [], total: 0);
    }
    return _api.fetchPricesByBarcode(barcode);
  }

  /// Syncs all pending prices to Open Prices.
  ///
  /// Proof photo upload is still a TODO — this method marks prices as
  /// synced locally without making HTTP requests.
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
        final updated = price.copyWith(syncStatus: priceSyncSynced);
        await _db.updatePrice(updated);
        synced++;
        logInfo('Price ${price.id} marked as synced (placeholder)');
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

  /// Validates the configured token against the Open Prices API.
  ///
  /// Returns true if the token is non-empty and the API responds with
  /// a success status. Returns false on network error.
  Future<bool> validateToken() => _api.validateToken();

  /// Disposes the underlying HTTP client.
  void dispose() {
    _api.dispose();
  }
}
