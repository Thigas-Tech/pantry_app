import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_item.freezed.dart';

/// An item on the user's shopping list.
///
/// Each [ShoppingItem] represents a product the user intends to buy.
/// Items can be linked to an existing product via [barcode] or entered
/// as free-form text via [name]. When the user later purchases an item
/// they mark it as [isPurchased] and may optionally move it to a pantry
/// ([inventoryId]).
///
/// ## NFC-e integration
///
/// When the receipt scanning feature parses an NFC-e QR code, items in
/// the shopping list whose barcode matches a receipt line are
/// automatically marked as purchased via
/// ShoppingListDao.markPurchasedByBarcode.
///
/// See also:
/// - ShoppingListDao — data-access layer for this model.
/// - Product — the static product catalogue this item may reference.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  /// Creates a [ShoppingItem].
  ///
  /// Only [name] is required; [barcode] is set when linking to an
  /// existing product.
  const factory ShoppingItem({
    /// Free-form product name or the linked product's name.
    required String name,

    /// The linked product barcode, or `null` for free-text items.
    String? barcode,

    /// Desired quantity to purchase. Defaults to 1.0.
    @Default(1.0) double quantity,

    /// Unit for [quantity] (e.g. `'pieces'`, `'g'`, `'ml'`).
    @Default('pieces') String unit,

    /// Whether this item has been purchased.
    @Default(false) bool isPurchased,

    /// Auto-increment primary key.
    int? id,

    /// Target pantry for move-to-inventory, or `null` if not set.
    int? inventoryId,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the item
    /// was added to the shopping list.
    int? dateAdded,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the item
    /// was marked as purchased.
    int? datePurchased,
  }) = _ShoppingItem;
}
