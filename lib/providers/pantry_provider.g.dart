// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the joined list of inventory items for the currently active
/// pantry.
///
/// This keep-alive async notifier provider is watched by the home screen to
/// display the pantry contents grouped by expiry status. It reads the active
/// inventory ID from [activeInventoryProvider] and calls
/// [DatabaseHelper.getInventoryWithProduct] with that ID.
///
/// Mutations (add, delete, move) should be performed through the notifier
/// methods, which update the provider state automatically so that any
/// widget watching [pantryProvider] is notified immediately.

@ProviderFor(Pantry)
final pantryProvider = PantryProvider._();

/// Provides the joined list of inventory items for the currently active
/// pantry.
///
/// This keep-alive async notifier provider is watched by the home screen to
/// display the pantry contents grouped by expiry status. It reads the active
/// inventory ID from [activeInventoryProvider] and calls
/// [DatabaseHelper.getInventoryWithProduct] with that ID.
///
/// Mutations (add, delete, move) should be performed through the notifier
/// methods, which update the provider state automatically so that any
/// widget watching [pantryProvider] is notified immediately.
final class PantryProvider
    extends $AsyncNotifierProvider<Pantry, List<InventoryWithProduct>> {
  /// Provides the joined list of inventory items for the currently active
  /// pantry.
  ///
  /// This keep-alive async notifier provider is watched by the home screen to
  /// display the pantry contents grouped by expiry status. It reads the active
  /// inventory ID from [activeInventoryProvider] and calls
  /// [DatabaseHelper.getInventoryWithProduct] with that ID.
  ///
  /// Mutations (add, delete, move) should be performed through the notifier
  /// methods, which update the provider state automatically so that any
  /// widget watching [pantryProvider] is notified immediately.
  PantryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pantryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pantryHash();

  @$internal
  @override
  Pantry create() => Pantry();
}

String _$pantryHash() => r'186125bf8d269c434b10e3584ae07487f7ce9e7d';

/// Provides the joined list of inventory items for the currently active
/// pantry.
///
/// This keep-alive async notifier provider is watched by the home screen to
/// display the pantry contents grouped by expiry status. It reads the active
/// inventory ID from [activeInventoryProvider] and calls
/// [DatabaseHelper.getInventoryWithProduct] with that ID.
///
/// Mutations (add, delete, move) should be performed through the notifier
/// methods, which update the provider state automatically so that any
/// widget watching [pantryProvider] is notified immediately.

abstract class _$Pantry extends $AsyncNotifier<List<InventoryWithProduct>> {
  FutureOr<List<InventoryWithProduct>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<InventoryWithProduct>>,
              List<InventoryWithProduct>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<InventoryWithProduct>>,
                List<InventoryWithProduct>
              >,
              AsyncValue<List<InventoryWithProduct>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
