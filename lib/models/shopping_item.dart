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
/// ## Price tracking
///
/// [priceAmount], [priceCurrency], and [priceStore] store price data
/// entered while shopping. When the item is moved to inventory, the price
/// is saved to the canonical price table.
///
/// ## Ordering
///
/// Pending items are manually ordered via [sortOrder], driven by the
/// drag-to-reorder gesture on the shopping list screen. Purchased items
/// keep sortOrder zero and are ordered by purchase date instead.
///
/// See also:
/// - ShoppingListDao — data-access layer for this model.
/// - Product — the static product catalogue this item may reference.
/// - Price model — the canonical price-history model.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  /// Creates a [ShoppingItem].
  ///
  /// Only [name] is required; [barcode] is set when linking to an
  /// existing product.
  const factory ShoppingItem({
    /// Free-form product name or the linked product's name.
    required String name,

    /// The linked product barcode, or null for free-text items.
    String? barcode,

    /// Desired quantity to purchase. Defaults to 1.0.
    @Default(1.0) double quantity,

    /// Unit for [quantity] (e.g. 'pieces', 'g', 'ml').
    @Default('pieces') String unit,

    /// Whether this item has been purchased.
    @Default(false) bool isPurchased,

    /// Auto-increment primary key.
    int? id,

    /// Target pantry for move-to-inventory, or null if not set.
    int? inventoryId,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the item
    /// was added to the shopping list.
    int? dateAdded,

    /// Epoch timestamp (milliseconds since Unix epoch) of when the item
    /// was marked as purchased.
    int? datePurchased,

    /// Price entered while shopping, or null if no price was set.
    double? priceAmount,

    /// ISO 4217 currency code for [priceAmount] (e.g. 'USD', 'BRL').
    String? priceCurrency,

    /// Store where the item was or will be purchased.
    String? priceStore,

    /// Manual ordering position for pending items. Defaults to 0.
    @Default(0) double sortOrder,
  }) = _ShoppingItem;
}
