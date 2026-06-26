class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'ProductNotFoundException: $message';
}

class FetchFailedException implements Exception {
  FetchFailedException(this.message);
  final String message;

  @override
  String toString() => 'FetchFailedException: $message';
}
