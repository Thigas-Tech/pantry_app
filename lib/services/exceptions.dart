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
