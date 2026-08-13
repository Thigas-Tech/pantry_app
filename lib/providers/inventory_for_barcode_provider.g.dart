// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_for_barcode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the inventory items for a specific barcode in the given
/// inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated list, matching the price providers. The
/// provider caches the query result across rebuilds, so the screen no
/// longer re-runs the database query on every build; mutation handlers
/// invalidate the family to refresh.

@ProviderFor(inventoryForBarcode)
final inventoryForBarcodeProvider = InventoryForBarcodeFamily._();

/// Provides the inventory items for a specific barcode in the given
/// inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated list, matching the price providers. The
/// provider caches the query result across rebuilds, so the screen no
/// longer re-runs the database query on every build; mutation handlers
/// invalidate the family to refresh.

final class InventoryForBarcodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          FutureOr<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $FutureProvider<List<InventoryItem>> {
  /// Provides the inventory items for a specific barcode in the given
  /// inventory.
  ///
  /// Keyed by a (barcode, inventoryId) record so each pantry keeps an
  /// independent, cache-isolated list, matching the price providers. The
  /// provider caches the query result across rebuilds, so the screen no
  /// longer re-runs the database query on every build; mutation handlers
  /// invalidate the family to refresh.
  InventoryForBarcodeProvider._({
    required InventoryForBarcodeFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'inventoryForBarcodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryForBarcodeHash();

  @override
  String toString() {
    return r'inventoryForBarcodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryItem>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return inventoryForBarcode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryForBarcodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryForBarcodeHash() =>
    r'ee8ea9d9d48a4dd88ae55f5697bc47530cd3e48d';

/// Provides the inventory items for a specific barcode in the given
/// inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated list, matching the price providers. The
/// provider caches the query result across rebuilds, so the screen no
/// longer re-runs the database query on every build; mutation handlers
/// invalidate the family to refresh.

final class InventoryForBarcodeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<InventoryItem>>,
          (String, int)
        > {
  InventoryForBarcodeFamily._()
    : super(
        retry: null,
        name: r'inventoryForBarcodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the inventory items for a specific barcode in the given
  /// inventory.
  ///
  /// Keyed by a (barcode, inventoryId) record so each pantry keeps an
  /// independent, cache-isolated list, matching the price providers. The
  /// provider caches the query result across rebuilds, so the screen no
  /// longer re-runs the database query on every build; mutation handlers
  /// invalidate the family to refresh.

  InventoryForBarcodeProvider call((String, int) args) =>
      InventoryForBarcodeProvider._(argument: args, from: this);

  @override
  String toString() => r'inventoryForBarcodeProvider';
}
