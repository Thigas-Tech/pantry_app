/// Thrown when a product barcode is not found in Open Food Facts.
class ProductNotFoundException implements Exception {
  /// Creates a [ProductNotFoundException] for the given [barcode].
  ProductNotFoundException(this.barcode);

  /// The barcode that was not found.
  final String barcode;

  @override
  String toString() => 'ProductNotFoundException: $barcode';
}

/// Thrown when a product cannot be fetched due to a network error or
/// other transient failure, and no cached copy exists.
class FetchFailedException implements Exception {
  /// Creates a [FetchFailedException] with a human-readable [message].
  FetchFailedException(this.message);

  /// A description of the failure.
  final String message;

  @override
  String toString() => 'FetchFailedException: $message';
}

/// Thrown when there is insufficient stock in the inventory to cook a recipe.
///
/// [shortages] maps ingredient names to the additional quantity needed.
class RecipeCookException implements Exception {
  /// Creates a [RecipeCookException] with the given [shortages].
  const RecipeCookException(this.shortages);

  /// Ingredient names and the additional amount needed (quantity beyond
  /// what is available).
  final Map<String, double> shortages;

  /// Whether shortages is empty.
  bool get isEmpty => shortages.isEmpty;
}
