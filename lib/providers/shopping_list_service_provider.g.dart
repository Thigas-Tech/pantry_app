// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [ShoppingListService] used by screens.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.

@ProviderFor(shoppingListService)
final shoppingListServiceProvider = ShoppingListServiceProvider._();

/// Provides the singleton [ShoppingListService] used by screens.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.

final class ShoppingListServiceProvider
    extends
        $FunctionalProvider<
          ShoppingListService,
          ShoppingListService,
          ShoppingListService
        >
    with $Provider<ShoppingListService> {
  /// Provides the singleton [ShoppingListService] used by screens.
  ///
  /// Kept alive for the app lifetime; the service holds no per-inventory
  /// state, so a single instance is safe.
  ShoppingListServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListServiceHash();

  @$internal
  @override
  $ProviderElement<ShoppingListService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListService create(Ref ref) {
    return shoppingListService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListService>(value),
    );
  }
}

String _$shoppingListServiceHash() =>
    r'b279f1fcbfd7c11bad16e3841cd9a772b9ae7592';
