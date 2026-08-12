// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aggregated statistics for the active pantry inventory.
///
/// Computed from SQL aggregation queries in [ProductDao] and
/// [InventoryDao]. Depends on [activeInventoryProvider] so it
/// refreshes when the user switches pantries. Auto-disposes to
/// release memory when leaving the Stats tab.

@ProviderFor(stats)
final statsProvider = StatsProvider._();

/// Aggregated statistics for the active pantry inventory.
///
/// Computed from SQL aggregation queries in [ProductDao] and
/// [InventoryDao]. Depends on [activeInventoryProvider] so it
/// refreshes when the user switches pantries. Auto-disposes to
/// release memory when leaving the Stats tab.

final class StatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PantryStats>,
          PantryStats,
          FutureOr<PantryStats>
        >
    with $FutureModifier<PantryStats>, $FutureProvider<PantryStats> {
  /// Aggregated statistics for the active pantry inventory.
  ///
  /// Computed from SQL aggregation queries in [ProductDao] and
  /// [InventoryDao]. Depends on [activeInventoryProvider] so it
  /// refreshes when the user switches pantries. Auto-disposes to
  /// release memory when leaving the Stats tab.
  StatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsHash();

  @$internal
  @override
  $FutureProviderElement<PantryStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PantryStats> create(Ref ref) {
    return stats(ref);
  }
}

String _$statsHash() => r'a6936a9c97dcf4754f2bea443d9ba1341c06d606';
