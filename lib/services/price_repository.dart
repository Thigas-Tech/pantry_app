import 'package:intl/intl.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/open_prices_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/price_calculator.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

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

  /// Returns the price with the given [id], or null if not found.
  Future<Price?> getPriceById(int id) => _db.getPriceById(id);

  /// Returns all price entries for the given [barcode] and [inventoryId],
  /// ordered by datePurchased descending.
  Future<List<Price>> getPriceHistory(
    String barcode, {
    required int inventoryId,
    int? limit,
    int? offset,
  }) => _db.getPricesByBarcode(
    barcode,
    inventoryId: inventoryId,
    limit: limit,
    offset: offset,
  );

  /// Returns the most recent price for the given [barcode] and
  /// [inventoryId], or null.
  Future<Price?> getLatestPrice(
    String barcode, {
    required int inventoryId,
  }) => _db.getLatestPrice(barcode, inventoryId: inventoryId);

  /// Returns the total number of prices on record.
  Future<int> getPriceCount() => _db.getPriceCount();

  // ---------------------------------------------------------------------------
  // Formatting & conversion
  // ---------------------------------------------------------------------------

  /// Formats [amount] as a currency string in [currencyCode].
  ///
  /// Uses [NumberFormat.currency] from package:intl. Returns a string like
  /// "R$ 15,90" or "$15.90".
  String formatPrice(double amount, String currencyCode) {
    try {
      return NumberFormat.currency(
        name: currencyCode,
        symbol: currencySymbolFor(currencyCode),
        decimalDigits: decimalDigitsFor(currencyCode),
      ).format(amount);
    } on Exception catch (e) {
      logWarning('Currency format error for $currencyCode: $e');
      return '${currencySymbolFor(currencyCode)} ${amount.toStringAsFixed(2)}';
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

  /// Builds a per-unit price label for [price] (e.g. "R$ 0,83/unit",
  /// "R$ 0,80/100 g", "R$ 8,00/kg", "R$ 5,00/L"), or null when the price
  /// carries no usable package size.
  ///
  /// The display unit is derived from the package size: per piece, per 100 g,
  /// per kg (when the package is at least one kilogram), per L (when the
  /// package is at least one liter), or per 100 ml otherwise. The localized
  /// suffix strings are supplied by the caller so this method stays free of
  /// l10n dependencies.
  String? unitPriceLabel(
    Price price, {
    required String perPiece,
    required String perHundredGrams,
    required String perKilogram,
    required String perLiter,
    required String perHundredMilliliters,
  }) {
    final unitPrice = PriceCalculator.unitPrice(
      price: price.price,
      packageQuantity: price.packageQuantity,
      packageUnit: price.packageUnit,
    );
    final packageQty = price.packageQuantity;
    final packageUnit = price.packageUnit;
    if (unitPrice == null || packageQty == null || packageUnit == null) {
      return null;
    }

    final scaled = switch (unitPrice.unit) {
      'g' =>
        UnitConverter.normalizeToGrams(packageQty, packageUnit) >= 1000
            ? (amount: unitPrice.amount * 1000, suffix: perKilogram)
            : (amount: unitPrice.amount * 100, suffix: perHundredGrams),
      'ml' =>
        UnitConverter.normalizeToMilliliters(packageQty, packageUnit) >= 1000
            ? (amount: unitPrice.amount * 1000, suffix: perLiter)
            : (amount: unitPrice.amount * 100, suffix: perHundredMilliliters),
      _ => (amount: unitPrice.amount, suffix: perPiece),
    };

    return '${formatPrice(scaled.amount, price.currency)}${scaled.suffix}';
  }

  // ---------------------------------------------------------------------------
  // Aggregations (scoped to an inventory)
  // ---------------------------------------------------------------------------

  /// Returns the sum of the most recent price per distinct product in
  /// the given inventory, converted to [baseCurrency], or null if no
  /// prices exist.
  ///
  /// When multiple currencies are present, each price is converted to
  /// [baseCurrency] before summing. The [baseCurrency] defaults to the
  /// user's configured base currency from Settings. If conversion fails
  /// for a price (e.g. rates unavailable), the unconverted value is used
  /// and a warning is logged.
  Future<double?> totalInventoryValue(
    int inventoryId, {
    String baseCurrency = 'USD',
  }) async {
    final db = await _db.database;
    final rows = await _db.priceDao.totalInventoryValueByCurrency(
      db,
      inventoryId,
    );
    if (rows.isEmpty) return null;

    var total = 0.0;
    for (final row in rows) {
      final currency = row['currency'] as String;
      final subtotal = (row['subtotal'] as num).toDouble();
      total += await convertToBase(subtotal, currency, baseCurrency);
    }
    return double.tryParse(total.toStringAsFixed(2));
  }

  /// Returns the quantity-weighted average of the most recent price per
  /// distinct product in the given inventory, converted to [baseCurrency],
  /// or null if no prices exist.
  ///
  /// Each price is converted individually before averaging so that
  /// mixed-currency inventories produce a meaningful average. Prices that
  /// carry a positive package size are reduced to their per-item value first
  /// (price / package size), matching recipe cost scaling. Products held in
  /// larger quantities contribute proportionally more to the average.
  Future<double?> averageItemPrice(
    int inventoryId, {
    String baseCurrency = 'USD',
  }) async {
    final db = await _db.database;
    final rows = await _db.priceDao.latestPricesWithCurrency(
      db,
      inventoryId,
    );
    if (rows.isEmpty) return null;

    var sum = 0.0;
    var totalQty = 0.0;
    for (final row in rows) {
      final price = _scaledLatestPrice(row);
      final currency = row['currency'] as String;
      final qty = (row['total_quantity'] as num?)?.toDouble() ?? 1;
      sum += await convertToBase(price, currency, baseCurrency) * qty;
      totalQty += qty;
    }
    if (totalQty == 0) return null;
    final avg = sum / totalQty;
    return double.tryParse(avg.toStringAsFixed(2));
  }

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

  /// Counts prices pending sync to Open Prices without loading the rows.
  Future<int> getPendingSyncCount() =>
      _db.countPricesBySyncStatus(priceSyncPending);

  /// Syncs all pending prices to the Open Prices database.
  ///
  /// Returns a [SyncResult] with counts of synced/failed prices.
  Future<SyncResult> syncToOpenPrices() =>
      _openPricesService.syncPendingPrices();

  /// Computes the value, quantity-weighted average price, and count of
  /// priced items in [inventoryId] from a single latest-price pass.
  ///
  /// Runs one query (the latest-prices-with-currency pass) and one
  /// currency-conversion pass instead of re-executing the correlated
  /// latest-price subquery per aggregate, which the stats screen
  /// previously did on every visit.
  ///
  /// The value sums per-currency subtotals converted to [baseCurrency];
  /// the average is the quantity-weighted mean of the latest price per
  /// product, reduced to per-item values for prices that carry a package
  /// size. Returns nulls for total and average when no prices exist.
  Future<({double? total, double? average, int count})> inventoryPriceSummary(
    int inventoryId, {
    String baseCurrency = 'USD',
  }) async {
    final db = await _db.database;
    final rows = await _db.priceDao.latestPricesWithCurrency(
      db,
      inventoryId,
    );
    if (rows.isEmpty) return (total: null, average: null, count: 0);

    var weightedSum = 0.0;
    var totalQty = 0.0;
    final subtotals = <String, double>{};
    for (final row in rows) {
      final price = _scaledLatestPrice(row);
      final currency = row['currency'] as String;
      final qty = (row['total_quantity'] as num?)?.toDouble() ?? 1;
      weightedSum += await convertToBase(price, currency, baseCurrency) * qty;
      subtotals[currency] = (subtotals[currency] ?? 0) + price * qty;
      totalQty += qty;
    }

    var total = 0.0;
    for (final entry in subtotals.entries) {
      total += await convertToBase(entry.value, entry.key, baseCurrency);
    }

    return (
      total: double.tryParse(total.toStringAsFixed(2)),
      average: totalQty == 0
          ? null
          : double.tryParse((weightedSum / totalQty).toStringAsFixed(2)),
      count: rows.length,
    );
  }

  /// Reduces a latest-price row to its per-item price when the price row
  /// carries a positive package size.
  ///
  /// Returns the raw price value unchanged when no package size is present so
  /// legacy prices keep their unscaled behavior.
  double _scaledLatestPrice(Map<String, dynamic> row) {
    final price = (row['price'] as num).toDouble();
    final pkg = (row['package_quantity'] as num?)?.toDouble();
    if (pkg == null || !pkg.isFinite || pkg <= 0) return price;
    return price / pkg;
  }
}
