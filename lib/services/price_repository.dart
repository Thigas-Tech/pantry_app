import 'package:intl/intl.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/open_prices_service.dart';
import 'package:pantry_app/utils/logger.dart';

export 'open_prices_service.dart' show SyncResult;

/// Coordinates price CRUD, formatting, currency conversion, and aggregation.
///
/// [PriceRepository] combines the local PriceDao (via [DatabaseHelper])
/// with the [CurrencyService] for display conversions.
///
/// ## Architecture
///
/// Local CRUD methods delegate directly to PriceDao. Formatting and
/// conversion methods use CurrencyService to convert prices to the
/// user's base currency for display.
class PriceRepository {
  /// Creates a [PriceRepository].
  PriceRepository(
    this._db,
    this._currencyService, [
    OpenPricesService? openPricesService,
  ]) : _openPricesService =
           openPricesService ?? OpenPricesService(databaseHelper: _db);

  final DatabaseHelper _db;
  final CurrencyService _currencyService;
  final OpenPricesService _openPricesService;

  // ---------------------------------------------------------------------------
  // Local CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a price observation. Returns the new row ID.
  Future<int> addPrice(Price price) => _db.insertPrice(price);

  /// Updates an existing price row.
  Future<void> updatePrice(Price price) async {
    await _db.updatePrice(price);
  }

  /// Deletes the price with the given [id].
  Future<void> deletePrice(int id) async {
    await _db.deletePrice(id);
  }

  /// Returns the price with the given [id], or `null` if not found.
  Future<Price?> getPriceById(int id) => _db.getPriceById(id);

  /// Returns all price entries for the given [barcode], ordered by
  /// datePurchased descending.
  Future<List<Price>> getPriceHistory(
    String barcode, {
    int? limit,
    int? offset,
  }) => _db.getPricesByBarcode(barcode, limit: limit, offset: offset);

  /// Returns the most recent price for the given [barcode], or `null`.
  Future<Price?> getLatestPrice(String barcode) => _db.getLatestPrice(barcode);

  /// Returns the total number of prices on record.
  Future<int> getPriceCount() => _db.getPriceCount();

  // ---------------------------------------------------------------------------
  // Formatting & conversion
  // ---------------------------------------------------------------------------

  /// Formats [amount] as a currency string in [currencyCode].
  ///
  /// Uses [NumberFormat.currency] from `package:intl`. Returns a string like
  /// `"R$ 15,90"` or `"$15.90"`.
  String formatPrice(double amount, String currencyCode) {
    try {
      return NumberFormat.currency(
        name: currencyCode,
        decimalDigits: 2,
      ).format(amount);
    } on Exception catch (e) {
      logWarning('Currency format error for $currencyCode: $e');
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }

  /// Converts [amount] from [fromCurrency] to [baseCurrency].
  ///
  /// Returns the original [amount] if conversion fails or currencies match.
  Future<double> convertToBase(
    double amount,
    String fromCurrency,
    String baseCurrency,
  ) => _currencyService.convert(amount, fromCurrency, baseCurrency);

  // ---------------------------------------------------------------------------
  // Aggregations (scoped to an inventory)
  // ---------------------------------------------------------------------------

  /// Returns the sum of the most recent price per distinct product in
  /// the given inventory, or `null` if no prices exist.
  Future<double?> totalInventoryValue(int inventoryId) =>
      _db.getTotalInventoryValue(inventoryId);

  /// Returns the average of the most recent price per distinct product in
  /// the given inventory, or `null` if no prices exist.
  Future<double?> averageItemPrice(int inventoryId) =>
      _db.getAverageItemPrice(inventoryId);

  /// Returns the count of distinct items in the inventory that have at
  /// least one price.
  Future<int> pricedItemCount(int inventoryId) =>
      _db.getPricedItemCount(inventoryId);

  // ---------------------------------------------------------------------------
  // Sync helpers
  // ---------------------------------------------------------------------------

  /// Returns prices pending sync to Open Prices.
  Future<List<Price>> getPendingSyncPrices() =>
      _db.getPricesBySyncStatus(priceSyncPending);

  /// Syncs all pending prices to the Open Prices database.
  ///
  /// Returns a [SyncResult] with counts of synced/failed prices.
  Future<SyncResult> syncToOpenPrices() =>
      _openPricesService.syncPendingPrices();
}
