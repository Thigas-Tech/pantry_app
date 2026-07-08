import 'package:freezed_annotation/freezed_annotation.dart';

part 'price.freezed.dart';

/// Sync status: not yet queued for Open Prices sync (no proof photo).
const String priceSyncLocalOnly = 'local_only';

/// Sync status: queued and waiting for upload to Open Prices.
const String priceSyncPending = 'pending';

/// Sync status: successfully synced to Open Prices.
const String priceSyncSynced = 'synced';

/// Sync status: sync failed, retry possible.
const String priceSyncFailed = 'failed';

/// A single price observation for a product.
///
/// Each [Price] represents one purchase or price observation at a specific
/// store on a specific date. A product may have many prices over time,
/// allowing the user to track trends and compute average spending.
///
/// ## Local vs contributed
///
/// Prices without a proof photo remain local ([syncStatus] is
/// [priceSyncLocalOnly]). When the user attaches a receipt or shelf-label
/// photo, the price can be shared with the [Open Prices](https://prices.openfoodfacts.org/)
/// community database.
///
/// ## Currency
///
/// Every price stores its original [currency] as an ISO 4217 code so that
/// multi-currency pantries are handled correctly. Display is always converted
/// to the user's base currency via CurrencyService.
///
/// See also:
/// - [Open Prices API](https://prices.openfoodfacts.org/api/docs)
/// - [ExchangeRate-API](https://open.er-api.com/) — free no-key currency
///   conversion used by the app.
@freezed
abstract class Price with _$Price {
  /// Creates a [Price].
  ///
  /// Only [barcode] and [price] are required; all other fields are optional.
  const factory Price({
    /// The product barcode this price is associated with.
    required String barcode,

    /// The monetary amount (taxes included).
    required double price,

    /// ISO 4217 currency code (e.g. `'BRL'`, `'USD'`, `'EUR'`).
    ///
    /// Defaults to `'USD'`; auto-detected from locale on first launch.
    @Default('USD') String currency,

    /// Auto-increment primary key.
    int? id,

    /// Free-form store or supermarket name.
    String? store,

    /// Whether this is a discounted / sale price.
    @Default(false) bool isDiscounted,

    /// Original price before discount, if [isDiscounted] is true.
    double? regularPrice,

    /// Epoch timestamp (milliseconds since Unix epoch) of the purchase.
    ///
    /// Defaults to the current time when no value is provided.
    int? datePurchased,

    /// Open prices sync status.
    ///
    /// - [priceSyncLocalOnly] — not shared (no proof photo).
    /// - [priceSyncPending] — queued for sync.
    /// - [priceSyncSynced] — successfully synced.
    /// - [priceSyncFailed] — sync failed.
    @Default(priceSyncLocalOnly) String syncStatus,

    /// Remote ID on Open Prices after successful sync.
    int? openPricesId,

    /// OpenStreetMap node/way ID for the store location.
    String? locationOsmId,

    /// OpenStreetMap location type (`NODE`, `WAY`, or `RELATION`).
    String? locationOsmType,

    /// NFC-e receipt series (reserved for future tax receipt integration).
    String? receiptSeries,

    /// NFC-e receipt number (reserved for future tax receipt integration).
    String? receiptNumber,

    /// NFC-e line-item index (reserved for future tax receipt integration).
    int? receiptItemIndex,

    /// Free-form notes about this price observation.
    String? notes,

    /// Epoch timestamp (milliseconds since Unix epoch) of when this record
    /// was created locally.
    int? dateAdded,
  }) = _Price;
}
