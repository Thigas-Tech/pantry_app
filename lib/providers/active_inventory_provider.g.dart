// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the ID of the currently selected inventory (pantry).
///
/// The value is persisted to [SharedPreferences] under the key
/// active_inventory_id so that the selection survives app restarts.
/// On initialization the provider reads the persisted value and validates
/// that the corresponding inventory still exists in the database. If the
/// persisted inventory was deleted, the provider falls back to the first
/// available inventory or, when no inventories exist, reseeds the default
/// "Home" inventory.
///
/// Defaults to 1 (the built‑in "Home" inventory created during migration)
/// on the very first run or when no persisted value is found.

@ProviderFor(ActiveInventoryNotifier)
final activeInventoryProvider = ActiveInventoryNotifierProvider._();

/// Holds the ID of the currently selected inventory (pantry).
///
/// The value is persisted to [SharedPreferences] under the key
/// active_inventory_id so that the selection survives app restarts.
/// On initialization the provider reads the persisted value and validates
/// that the corresponding inventory still exists in the database. If the
/// persisted inventory was deleted, the provider falls back to the first
/// available inventory or, when no inventories exist, reseeds the default
/// "Home" inventory.
///
/// Defaults to 1 (the built‑in "Home" inventory created during migration)
/// on the very first run or when no persisted value is found.
final class ActiveInventoryNotifierProvider
    extends $AsyncNotifierProvider<ActiveInventoryNotifier, int> {
  /// Holds the ID of the currently selected inventory (pantry).
  ///
  /// The value is persisted to [SharedPreferences] under the key
  /// active_inventory_id so that the selection survives app restarts.
  /// On initialization the provider reads the persisted value and validates
  /// that the corresponding inventory still exists in the database. If the
  /// persisted inventory was deleted, the provider falls back to the first
  /// available inventory or, when no inventories exist, reseeds the default
  /// "Home" inventory.
  ///
  /// Defaults to 1 (the built‑in "Home" inventory created during migration)
  /// on the very first run or when no persisted value is found.
  ActiveInventoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeInventoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeInventoryNotifierHash();

  @$internal
  @override
  ActiveInventoryNotifier create() => ActiveInventoryNotifier();
}

String _$activeInventoryNotifierHash() =>
    r'bc7fe0f5c29eb95f9cf3ab952aba1dbf3747ed3c';

/// Holds the ID of the currently selected inventory (pantry).
///
/// The value is persisted to [SharedPreferences] under the key
/// active_inventory_id so that the selection survives app restarts.
/// On initialization the provider reads the persisted value and validates
/// that the corresponding inventory still exists in the database. If the
/// persisted inventory was deleted, the provider falls back to the first
/// available inventory or, when no inventories exist, reseeds the default
/// "Home" inventory.
///
/// Defaults to 1 (the built‑in "Home" inventory created during migration)
/// on the very first run or when no persisted value is found.

abstract class _$ActiveInventoryNotifier extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
