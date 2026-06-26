class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'ProductNotFoundException: $message';
}
