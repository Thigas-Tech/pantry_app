/// Resolved price value for a shopping item, used for totals.
///
/// An [isEstimate] price is derived from the latest tracked price for the
/// product (from the prices table) rather than a price the user entered.
class ShoppingPrice {
  /// Creates a [ShoppingPrice].
  const ShoppingPrice({
    required this.amount,
    required this.currency,
    required this.isEstimate,
    this.store,
  });

  /// The monetary amount.
  final double amount;

  /// ISO 4217 currency code.
  final String currency;

  /// Whether this price is an estimate derived from tracked prices.
  final bool isEstimate;

  /// Optional store for entered prices.
  final String? store;
}

/// The computed total for a list of [ShoppingPrice] entries.
class ShoppingTotal {
  /// Creates a [ShoppingTotal].
  const ShoppingTotal({
    required this.byCurrency,
    required this.estimatedAmount,
  });

  /// Total amount per currency code.
  final Map<String, double> byCurrency;

  /// Total estimated amount across all currencies.
  final double estimatedAmount;
}

/// Groups [prices] into per-currency totals.
///
/// Returns a [ShoppingTotal] whose [ShoppingTotal.byCurrency] maps each
/// currency code to the sum of amounts in that currency, and whose
/// [ShoppingTotal.estimatedAmount] is the sum of all estimate amounts (across
/// all currencies, used only for the disclosure label). Empty input yields an
/// empty map and zero estimate.
ShoppingTotal groupShoppingPrices(List<ShoppingPrice> prices) {
  final byCurrency = <String, double>{};
  var estimated = 0.0;
  for (final price in prices) {
    byCurrency.update(
      price.currency,
      (v) => v + price.amount,
      ifAbsent: () => price.amount,
    );
    if (price.isEstimate) estimated += price.amount;
  }
  return ShoppingTotal(byCurrency: byCurrency, estimatedAmount: estimated);
}
