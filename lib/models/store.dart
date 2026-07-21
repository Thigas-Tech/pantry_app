import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/price.dart';

part 'store.freezed.dart';

/// A store where the user buys products.
///
/// Each [Store] represents a physical or online retailer. Store names are
/// used in [Price] records and persisted in the stores table so they can
/// be suggested via autocomplete on the price entry sheet.
@freezed
abstract class Store with _$Store {
  /// Creates a [Store].
  const factory Store({
    /// Auto-increment primary key.
    required int id,

    /// Human-readable store name (e.g. 'Walmart', 'Costco').
    required String name,
  }) = _Store;
}
