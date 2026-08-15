import 'dart:async';

import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'market_trip_item_provider.g.dart';

/// The optional price to record on a market trip item.
class TripItemPriceInput {
  /// Creates a [TripItemPriceInput].
  const TripItemPriceInput({
    required this.amount,
    required this.currency,
    this.store,
  });

  /// The price amount.
  final double amount;

  /// ISO 4217 currency code for [amount].
  final String currency;

  /// The store where the item was purchased, if known.
  final String? store;
}

/// State of one trip-item add flow, scoped to a single trip inventory.
class MarketTripItemState {
  /// Creates a [MarketTripItemState].
  const MarketTripItemState({this.processingBarcode, this.lastError});

  /// The barcode currently being added, or null when idle. Guards against
  /// concurrent adds for the same product.
  final String? processingBarcode;

  /// The last error message produced by an add, or null.
  final String? lastError;

  /// Creates a copy of this state with the given fields replaced.
  MarketTripItemState copyWith({
    String? processingBarcode,
    String? lastError,
    bool clearError = false,
    bool clearProcessing = false,
  }) {
    return MarketTripItemState(
      processingBarcode: clearProcessing
          ? null
          : (processingBarcode ?? this.processingBarcode),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Orchestrates adding a scanned (or produce-searched) product to a market
/// trip as purchased, applying an optional price and expiry in one unit of
/// work.
///
/// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
/// lifecycle live in the screens. Writes go through
/// [shoppingListServiceProvider] and the shopping list providers for the
/// trip inventory are invalidated after every mutation.
@riverpod
class MarketTripItemController extends _$MarketTripItemController {
  @override
  MarketTripItemState build(int tripId) => const MarketTripItemState();

  /// Adds [product] to the trip as purchased and returns its id.
  ///
  /// Marks an existing pending row with the same barcode as purchased, or
  /// merges into an existing purchased row (same barcode) by incrementing
  /// its quantity, or inserts a new purchased row when neither exists.
  /// When [price] is given it is written to the item, and when [expiryDate]
  /// is given (and not before today) it is written too.
  ///
  /// Returns null when the call was ignored because an add for the same
  /// barcode is already in progress. Throws when the item cannot be
  /// resolved or persisted.
  Future<int?> addScannedProduct(
    Product product, {
    TripItemPriceInput? price,
    String? expiryDate,
  }) async {
    if (state.processingBarcode == product.barcode) {
      logInfo('Ignoring add for ${product.barcode} — already processing');
      return null;
    }
    state = state.copyWith(
      processingBarcode: product.barcode,
      clearError: true,
    );
    try {
      final db = ref.read(databaseProvider);
      final service = ref.read(shoppingListServiceProvider);

      final marked = await db.markShoppingItemsByBarcode(
        product.barcode,
        inventoryId: tripId,
      );
      // The notifier is autoDispose: if the confirm screen popped while the
      // add was in flight, this provider is disposed and `ref`/`state` can no
      // longer be used. Bail out early instead of throwing "Ref after
      // disposed" (the widgets that would react are gone anyway).
      if (!ref.mounted) return null;

      int? id;
      if (marked > 0) {
        id = (await _findPurchasedByBarcode(product.barcode))?.id;
      } else {
        final existing = await _findPurchasedByBarcode(product.barcode);
        if (!ref.mounted) return null;
        if (existing != null && existing.id != null) {
          final existingId = existing.id!;
          id = existingId;
          await service.updateShoppingItem(
            existing.copyWith(quantity: existing.quantity + 1),
          );
        } else {
          id = await service.addShoppingItem(
            ShoppingItem(
              name: product.name != 'Unknown' ? product.name : product.barcode,
              barcode: product.barcode,
              inventoryId: tripId,
              isPurchased: true,
              // Produce is weighed in grams by default, matching the
              // add-to-inventory produce default.
              unit: product.productType == ProductType.produce ? 'g' : 'pieces',
            ),
            activeInventoryId: tripId,
          );
        }
      }

      if (id == null) {
        throw StateError('No trip item id for barcode ${product.barcode}');
      }
      if (!ref.mounted) return null;

      if (price != null) {
        await service.updateShoppingItemPrice(
          id,
          priceAmount: price.amount,
          priceCurrency: price.currency,
          priceStore: price.store,
        );
        if (!ref.mounted) return null;
      }

      final iso = expiryDate;
      if (iso != null) {
        if (_isBeforeToday(iso)) {
          throw ArgumentError.value(
            iso,
            'expiryDate',
            'must not be before today',
          );
        }
        await service.updateShoppingItemExpiry(id, iso);
        if (!ref.mounted) return null;
      }

      ref
        ..invalidate(shoppingListByInventoryProvider(tripId))
        ..invalidate(shoppingListProvider)
        ..invalidate(pendingShoppingListProvider)
        ..invalidate(purchasedShoppingListProvider)
        ..invalidate(pendingShoppingCountProvider);
      return id;
    } on Exception catch (e) {
      logError('Failed to add scanned product to trip: $e');
      if (ref.mounted) {
        state = state.copyWith(lastError: e.toString());
      }
      rethrow;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(clearProcessing: true);
      }
    }
  }

  /// Returns the first purchased trip item whose barcode matches [barcode].
  Future<ShoppingItem?> _findPurchasedByBarcode(String barcode) async {
    final items = await ref
        .read(databaseProvider)
        .getShoppingList(inventoryId: tripId);
    for (final item in items) {
      if (item.isPurchased && item.barcode == barcode) return item;
    }
    return null;
  }

  /// Whether the ISO date string [iso] is strictly before today's date.
  static bool _isBeforeToday(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }
}
