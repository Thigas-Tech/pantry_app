import 'package:flutter/foundation.dart';

/// A single point on the price history chart.
///
/// Produced by the price-history conversion in PriceRepository: the [date]
/// is the local purchase (or recording) date, [amount] is already converted
/// to the user's base currency, and [store] is the optional store label
/// shown in the chart tooltip.
@immutable
class PriceHistoryPoint {
  /// Creates a [PriceHistoryPoint].
  const PriceHistoryPoint({
    required this.date,
    required this.amount,
    this.store,
  });

  /// The local date of the price observation.
  final DateTime date;

  /// The monetary amount in the user's base currency.
  final double amount;

  /// The store where the price was recorded, if known.
  final String? store;
}
