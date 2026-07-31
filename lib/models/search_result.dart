import 'package:pantry_app/models/product.dart';

/// The source of a single search result.
///
/// Distinguishes products returned from the local database ([local]) from
/// products fetched live from a remote API ([api]).
enum ResultSource {
  /// The product came from the local database cache.
  local,

  /// The product came from a remote API (Open Food Facts or USDA).
  api,
}

/// A single search result with its pantry status.
///
/// Wraps a [Product] with the [source] it came from and whether the barcode
/// is already present in the active inventory ([isInPantry]). Immutable.
class SearchResult {
  /// Constructs a [SearchResult].
  ///
  /// [isInPantry] defaults to false.
  const SearchResult({
    required this.product,
    required this.source,
    this.isInPantry = false,
  });

  /// The resolved product.
  final Product product;

  /// Whether the product came from the local cache or a remote API.
  final ResultSource source;

  /// Whether the product barcode is already in the active inventory.
  final bool isInPantry;
}
