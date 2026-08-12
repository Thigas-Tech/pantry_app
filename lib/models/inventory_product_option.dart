/// A distinct product available in the active inventory, for the
/// "from your pantry" shopping-list suggestions.
///
/// This is the typed view of a distinct-product row so that UI code never
/// touches raw database maps. All fields are immutable.
class InventoryProductOption {
  /// Creates an [InventoryProductOption].
  const InventoryProductOption({
    required this.barcode,
    this.name,
    this.imageUrl,
    this.productType,
  });

  /// Maps a raw distinct-product row into an [InventoryProductOption].
  ///
  /// Missing or malformed values fall back to safe defaults (empty strings)
  /// instead of throwing.
  factory InventoryProductOption.fromMap(Map<String, Object?> map) {
    return InventoryProductOption(
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String?,
      imageUrl: map['image_url'] as String?,
      productType: map['product_type'] as String?,
    );
  }

  /// The product barcode.
  final String barcode;

  /// The product display name, when known.
  final String? name;

  /// The product image URL, when available.
  final String? imageUrl;

  /// The product type tag (for example 'produce').
  final String? productType;
}
