// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of all inventories (id, name).

@ProviderFor(inventoryList)
final inventoryListProvider = InventoryListProvider._();

/// Provides the list of all inventories (id, name).

final class InventoryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Provides the list of all inventories (id, name).
  InventoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return inventoryList(ref);
  }
}

String _$inventoryListHash() => r'05835531b94bd53b38034b3191e8b6ce376c7d28';

/// Provides the count of inventory items in the active pantry.

@ProviderFor(inventoryCount)
final inventoryCountProvider = InventoryCountProvider._();

/// Provides the count of inventory items in the active pantry.

final class InventoryCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the count of inventory items in the active pantry.
  InventoryCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return inventoryCount(ref);
  }
}

String _$inventoryCountHash() => r'030583b548a5797092b2642c6cc4ac96dda021a8';

/// Provides the total count of inventory items across ALL inventories.
///
/// Used to detect the first item ever added to any pantry (0→1 transition)
/// so the empty-pantry onboarding can auto-dismiss.

@ProviderFor(totalInventoryCount)
final totalInventoryCountProvider = TotalInventoryCountProvider._();

/// Provides the total count of inventory items across ALL inventories.
///
/// Used to detect the first item ever added to any pantry (0→1 transition)
/// so the empty-pantry onboarding can auto-dismiss.

final class TotalInventoryCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the total count of inventory items across ALL inventories.
  ///
  /// Used to detect the first item ever added to any pantry (0→1 transition)
  /// so the empty-pantry onboarding can auto-dismiss.
  TotalInventoryCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalInventoryCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalInventoryCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalInventoryCount(ref);
  }
}

String _$totalInventoryCountHash() =>
    r'ca400fc7bad25ba1097d25b0f0614ed768d428b6';

/// Provides the average Nutri-Score letter for the active inventory.
///
/// Returns a grade ('a'–'e') or null if none of the products in the
/// current pantry have [NutriScoreBadge] data.

@ProviderFor(averageNutriscore)
final averageNutriscoreProvider = AverageNutriscoreProvider._();

/// Provides the average Nutri-Score letter for the active inventory.
///
/// Returns a grade ('a'–'e') or null if none of the products in the
/// current pantry have [NutriScoreBadge] data.

final class AverageNutriscoreProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the average Nutri-Score letter for the active inventory.
  ///
  /// Returns a grade ('a'–'e') or null if none of the products in the
  /// current pantry have [NutriScoreBadge] data.
  AverageNutriscoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'averageNutriscoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$averageNutriscoreHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return averageNutriscore(ref);
  }
}

String _$averageNutriscoreHash() => r'9ea08b1d91046a9691656ff5af2cdf6709d2000f';
