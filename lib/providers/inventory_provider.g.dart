// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of all inventories as typed [InventorySummary] rows.

@ProviderFor(inventoryList)
final inventoryListProvider = InventoryListProvider._();

/// Provides the list of all inventories as typed [InventorySummary] rows.

final class InventoryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventorySummary>>,
          List<InventorySummary>,
          FutureOr<List<InventorySummary>>
        >
    with
        $FutureModifier<List<InventorySummary>>,
        $FutureProvider<List<InventorySummary>> {
  /// Provides the list of all inventories as typed [InventorySummary] rows.
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
  $FutureProviderElement<List<InventorySummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventorySummary>> create(Ref ref) {
    return inventoryList(ref);
  }
}

String _$inventoryListHash() => r'59ddcc78fdaccc1bca6f4c2022939424a8624cba';

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
    r'a6e8f3750601590fed1be6d76e79ce993e9f5f94';

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
