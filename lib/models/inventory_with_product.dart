import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';

/// A read‑only view that joins an [InventoryItem] with its corresponding
/// [Product] metadata and inventory details.
///
/// This class is **not** persisted directly. Instead, it is built on the fly
/// by [DatabaseHelper.getInventoryWithProduct] using a `LEFT JOIN` on
/// `products` and an `INNER JOIN` on `inventories`. The `LEFT JOIN` ensures
/// inventory items remain visible even after a cache flush deletes their
/// product records. It provides all the data needed by the home screen to
/// display a single inventory card, avoiding the need for multiple separate
/// queries.
///
/// ## Fields
///
/// The first nine fields mirror those of [InventoryItem]. The last four
/// ([productName], [productImageUrl], [productCategory], and [inventoryName])
/// are pulled from the joined tables and provide human‑readable labels,
/// images, categories, and inventory names.
///
/// ## Immutability
///
/// This class is fully immutable – all fields are `final`. To modify data,
/// update the underlying [InventoryItem] or [Product] through the repository.
class InventoryWithProduct {
  /// Constructs an [InventoryWithProduct] instance.
  ///
  /// Only [barcode], [quantity], [unit], [location], and [inventoryId] are
  /// required. All other fields are optional because they may be missing from
  /// the database row (e.g., a product may not have an image URL).
  const InventoryWithProduct({
    /// The product barcode (foreign key).
    required this.barcode,

    /// The quantity of this inventory item, in [unit].
    required this.quantity,

    /// The unit of measurement (e.g. `'pcs'`, `'g'`).
    required this.unit,

    /// The storage location (e.g. `'pantry'`, `'fridge'`).
    required this.location,

    /// The ID of the inventory this item belongs to.
    required this.inventoryId,

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
    /// May be `null` if the product record was deleted (e.g. after a cache
    /// flush) — the `LEFT JOIN` in the query still returns the inventory row
    /// with `NULL` product columns.
    this.productName,

    /// A URL to the product’s front image from Open Food Facts.
    this.productImageUrl,

    /// The name of the inventory this item belongs to.
    this.inventoryName,

    /// The Nutri-Score grade from the `products` table (e.g. `'a'`–`'e'`).
    /// May be `'not-applicable'` when the Nutri-Score system does not apply.
    this.nutriscoreGrade,

    /// The category that makes Nutri-Score not applicable, if any
    /// (e.g. `'en:food-additives'`).
    this.nutriscoreNotApplicableCategory,

    /// The product category from the `products` table (e.g. `'Spreads'`).
    ///
    /// May be `null` if the product record was deleted or the category
    /// was not set. Used for category filter chips on the home screen.
    this.productCategory,

    /// The normalized search text from the `products` table.
    this.productSearchText,
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
      inventoryId: map['inventory_id'] as int? ?? 1,
      productName: map['product_name'] as String?,
      productImageUrl: map['product_image_url'] as String?,
      inventoryName: map['inventory_name'] as String?,
      nutriscoreGrade: map['nutriscore_grade'] as String?,
      nutriscoreNotApplicableCategory:
          map['nutriscore_not_applicable_category'] as String?,
      productCategory: map['product_category'] as String?,
      productSearchText: map['product_search_text'] as String?,
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

  /// The ID of the inventory (pantry) this item belongs to.
  final int inventoryId;

  /// The product name from the `products` table, for display purposes.
  final String? productName;

  /// A URL to the product’s front image from Open Food Facts.
  final String? productImageUrl;

  /// The display name of the inventory this item belongs to.
  final String? inventoryName;

  /// The Nutri-Score grade of the product (`'a'` through `'e'`), or `null`
  /// if unavailable.
  final String? nutriscoreGrade;

  /// The product category that makes Nutri-Score not applicable, if any
  /// (e.g. `'en:food-additives'`).
  final String? nutriscoreNotApplicableCategory;

  /// The product category from the `products` table (e.g. `'Spreads'`).
  ///
  /// May be `null` if the product record was deleted or the category
  /// was not set. Used for category filter chips on the home screen.
  final String? productCategory;

  /// The normalized search text from the `products` table.
  final String? productSearchText;
}
