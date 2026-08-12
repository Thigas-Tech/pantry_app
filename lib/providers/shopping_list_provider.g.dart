// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [PhotoService] instance.

@ProviderFor(photoService)
final photoServiceProvider = PhotoServiceProvider._();

/// Provides a singleton [PhotoService] instance.

final class PhotoServiceProvider
    extends $FunctionalProvider<PhotoService, PhotoService, PhotoService>
    with $Provider<PhotoService> {
  /// Provides a singleton [PhotoService] instance.
  PhotoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoServiceHash();

  @$internal
  @override
  $ProviderElement<PhotoService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoService create(Ref ref) {
    return photoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoService>(value),
    );
  }
}

String _$photoServiceHash() => r'9edcf0ebaf6bf82d66bba3d5ec4788b38528107c';

/// Provides all shopping list items, scoped to the active inventory.

@ProviderFor(shoppingList)
final shoppingListProvider = ShoppingListProvider._();

/// Provides all shopping list items, scoped to the active inventory.

final class ShoppingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingItem>>,
          List<ShoppingItem>,
          FutureOr<List<ShoppingItem>>
        >
    with
        $FutureModifier<List<ShoppingItem>>,
        $FutureProvider<List<ShoppingItem>> {
  /// Provides all shopping list items, scoped to the active inventory.
  ShoppingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListHash();

  @$internal
  @override
  $FutureProviderElement<List<ShoppingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingItem>> create(Ref ref) {
    return shoppingList(ref);
  }
}

String _$shoppingListHash() => r'9f797101de088ce7685e8f387fce1c58e53eaf5f';

/// Provides only pending (not purchased) shopping list items, scoped to the
/// active inventory.

@ProviderFor(pendingShoppingList)
final pendingShoppingListProvider = PendingShoppingListProvider._();

/// Provides only pending (not purchased) shopping list items, scoped to the
/// active inventory.

final class PendingShoppingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingItem>>,
          List<ShoppingItem>,
          FutureOr<List<ShoppingItem>>
        >
    with
        $FutureModifier<List<ShoppingItem>>,
        $FutureProvider<List<ShoppingItem>> {
  /// Provides only pending (not purchased) shopping list items, scoped to the
  /// active inventory.
  PendingShoppingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingShoppingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingShoppingListHash();

  @$internal
  @override
  $FutureProviderElement<List<ShoppingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingItem>> create(Ref ref) {
    return pendingShoppingList(ref);
  }
}

String _$pendingShoppingListHash() =>
    r'02b30da1359fef113dce41ff83cb1683e4a16eab';

/// Provides only purchased shopping list items, scoped to the active inventory.

@ProviderFor(purchasedShoppingList)
final purchasedShoppingListProvider = PurchasedShoppingListProvider._();

/// Provides only purchased shopping list items, scoped to the active inventory.

final class PurchasedShoppingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingItem>>,
          List<ShoppingItem>,
          FutureOr<List<ShoppingItem>>
        >
    with
        $FutureModifier<List<ShoppingItem>>,
        $FutureProvider<List<ShoppingItem>> {
  /// Provides only purchased shopping list items, scoped to the active inventory.
  PurchasedShoppingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasedShoppingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasedShoppingListHash();

  @$internal
  @override
  $FutureProviderElement<List<ShoppingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingItem>> create(Ref ref) {
    return purchasedShoppingList(ref);
  }
}

String _$purchasedShoppingListHash() =>
    r'304a7c6c5ef9c321d802d3fccf20f095c9862ea9';

/// Provides the count of pending (not purchased) items, scoped to the active
/// inventory.

@ProviderFor(pendingShoppingCount)
final pendingShoppingCountProvider = PendingShoppingCountProvider._();

/// Provides the count of pending (not purchased) items, scoped to the active
/// inventory.

final class PendingShoppingCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the count of pending (not purchased) items, scoped to the active
  /// inventory.
  PendingShoppingCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingShoppingCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingShoppingCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingShoppingCount(ref);
  }
}

String _$pendingShoppingCountHash() =>
    r'46ac86d11d5494262e660d413dbe52b608edeafc';

/// Provides distinct product barcodes and names from the active inventory
/// for the "From your pantry" suggestions in the add-to-shopping-list sheet.

@ProviderFor(inventoryProducts)
final inventoryProductsProvider = InventoryProductsProvider._();

/// Provides distinct product barcodes and names from the active inventory
/// for the "From your pantry" suggestions in the add-to-shopping-list sheet.

final class InventoryProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryProductOption>>,
          List<InventoryProductOption>,
          FutureOr<List<InventoryProductOption>>
        >
    with
        $FutureModifier<List<InventoryProductOption>>,
        $FutureProvider<List<InventoryProductOption>> {
  /// Provides distinct product barcodes and names from the active inventory
  /// for the "From your pantry" suggestions in the add-to-shopping-list sheet.
  InventoryProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryProductOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryProductOption>> create(Ref ref) {
    return inventoryProducts(ref);
  }
}

String _$inventoryProductsHash() => r'8683b12b619a215d0a43b0dd0d3f09fdd3433aa7';
