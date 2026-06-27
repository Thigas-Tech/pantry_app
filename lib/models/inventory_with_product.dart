/// A read‑only view that joins an [InventoryItem] with its corresponding
/// [Product] metadata.
///
/// This class is **not** persisted directly. Instead, it is built on the fly
/// by [DatabaseHelper.getInventoryWithProduct] using a SQL `INNER JOIN`
/// between the `inventory` and `products` tables. It provides all the data
/// needed by the home screen to display a single inventory card, avoiding
/// the need for multiple separate queries.
///
/// ## Fields
///
/// The first eight fields mirror those of [InventoryItem]. The last two
/// ([productName] and [productImageUrl]) are pulled from the `products` table
/// and provide human‑readable labels and images.
///
/// ## Immutability
///
/// This class is fully immutable – all fields are `final`. To modify data,
/// update the underlying [InventoryItem] or [Product] through the repository.
class InventoryWithProduct {
  /// Constructs an [InventoryWithProduct] instance.
  ///
  /// Only [barcode], [quantity], [unit], and [location] are required. All
  /// other fields are optional because they may be missing from the database
  /// row (e.g., a product may not have an image URL).
  const InventoryWithProduct({
    /// The product barcode (foreign key).
    required this.barcode,

    /// The quantity of this inventory item, in [unit].
    required this.quantity,

    /// The unit of measurement (e.g. `'pcs'`, `'g'`).
    required this.unit,

    /// The storage location (e.g. `'pantry'`, `'fridge'`).
    required this.location,

    /// The auto‑generated primary key of the inventory row.
    this.id,

    /// The expiry date in ISO 8601 format (`YYYY-MM-DD`), or `null`.
    this.expiryDate,

    /// Free‑form notes the user may have added.
    this.notes,

    /// Epoch timestamp (milliseconds) when the item was first added.
    this.dateAdded,

    /// The product name from the `products` table.
    ///
    /// May be `null` if the join somehow fails – though with an `INNER JOIN`
    /// this should not happen in practice.
    this.productName,

    /// A URL to the product’s front image from Open Food Facts.
    this.productImageUrl,
  });

  /// Constructs an [InventoryWithProduct] from a raw database row.
  ///
  /// The row is expected to come from [DatabaseHelper.getInventoryWithProduct]
  /// and must contain all the columns listed in that query.
  ///
  /// Defaults are applied to [quantity], [unit], and [location] as a safety
  /// net in case the database contains unexpected `NULL` values.
  factory InventoryWithProduct.fromMap(Map<String, dynamic> map) {
    return InventoryWithProduct(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? 'pcs',
      expiryDate: map['expiry_date'] as String?,
      location: map['location'] as String? ?? 'pantry',
      notes: map['notes'] as String?,
      dateAdded: map['date_added'] as int?,
      productName: map['product_name'] as String?,
      productImageUrl: map['product_image_url'] as String?,
    );
  }

  /// The auto‑generated inventory row ID.
  final int? id;

  /// The product barcode (e.g. EAN‑13).
  final String barcode;

  /// The quantity of this item, expressed in [unit].
  final double quantity;

  /// The unit of measurement for [quantity] (e.g. `'pcs'`, `'g'`).
  final String unit;

  /// The expiry date in ISO 8601 format (`YYYY-MM-DD`), if set.
  final String? expiryDate;

  /// The storage location (e.g. `'pantry'`, `'fridge'`, `'freezer'`).
  final String location;

  /// User‑provided notes about this item.
  final String? notes;

  /// Epoch timestamp of when this item was first added to inventory.
  final int? dateAdded;

  /// The product name from the `products` table, for display purposes.
  final String? productName;

  /// A URL to the product’s front image from Open Food Facts.
  final String? productImageUrl;
}
