// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the price history for a specific barcode in the given inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated history.

@ProviderFor(priceHistory)
final priceHistoryProvider = PriceHistoryFamily._();

/// Provides the price history for a specific barcode in the given inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated history.

final class PriceHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Price>>,
          List<Price>,
          FutureOr<List<Price>>
        >
    with $FutureModifier<List<Price>>, $FutureProvider<List<Price>> {
  /// Provides the price history for a specific barcode in the given inventory.
  ///
  /// Keyed by a (barcode, inventoryId) record so each pantry keeps an
  /// independent, cache-isolated history.
  PriceHistoryProvider._({
    required PriceHistoryFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'priceHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$priceHistoryHash();

  @override
  String toString() {
    return r'priceHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Price>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Price>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return priceHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PriceHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$priceHistoryHash() => r'c7bef902d4281296e75e0dba5c90610d5623ab41';

/// Provides the price history for a specific barcode in the given inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated history.

final class PriceHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Price>>, (String, int)> {
  PriceHistoryFamily._()
    : super(
        retry: null,
        name: r'priceHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the price history for a specific barcode in the given inventory.
  ///
  /// Keyed by a (barcode, inventoryId) record so each pantry keeps an
  /// independent, cache-isolated history.

  PriceHistoryProvider call((String, int) args) =>
      PriceHistoryProvider._(argument: args, from: this);

  @override
  String toString() => r'priceHistoryProvider';
}

/// Provides the most recent price for a specific barcode in the given
/// inventory, or null.
///
/// Keyed by a (barcode, inventoryId) record.

@ProviderFor(latestPrice)
final latestPriceProvider = LatestPriceFamily._();

/// Provides the most recent price for a specific barcode in the given
/// inventory, or null.
///
/// Keyed by a (barcode, inventoryId) record.

final class LatestPriceProvider
    extends $FunctionalProvider<AsyncValue<Price?>, Price?, FutureOr<Price?>>
    with $FutureModifier<Price?>, $FutureProvider<Price?> {
  /// Provides the most recent price for a specific barcode in the given
  /// inventory, or null.
  ///
  /// Keyed by a (barcode, inventoryId) record.
  LatestPriceProvider._({
    required LatestPriceFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'latestPriceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$latestPriceHash();

  @override
  String toString() {
    return r'latestPriceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Price?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Price?> create(Ref ref) {
    final argument = this.argument as (String, int);
    return latestPrice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestPriceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$latestPriceHash() => r'9dba81037fb6bc784c9cba5d18522416f7e1ce37';

/// Provides the most recent price for a specific barcode in the given
/// inventory, or null.
///
/// Keyed by a (barcode, inventoryId) record.

final class LatestPriceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Price?>, (String, int)> {
  LatestPriceFamily._()
    : super(
        retry: null,
        name: r'latestPriceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the most recent price for a specific barcode in the given
  /// inventory, or null.
  ///
  /// Keyed by a (barcode, inventoryId) record.

  LatestPriceProvider call((String, int) args) =>
      LatestPriceProvider._(argument: args, from: this);

  @override
  String toString() => r'latestPriceProvider';
}

/// Whether prices are hidden for privacy.

@ProviderFor(pricesHidden)
final pricesHiddenProvider = PricesHiddenProvider._();

/// Whether prices are hidden for privacy.

final class PricesHiddenProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether prices are hidden for privacy.
  PricesHiddenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pricesHiddenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pricesHiddenHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return pricesHidden(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pricesHiddenHash() => r'a2e69ff8cf5b35a63a71631590cc4170ba26fd9d';

/// Provides the total value of the currently active inventory, converted
/// to the user's base currency.

@ProviderFor(inventoryValue)
final inventoryValueProvider = InventoryValueProvider._();

/// Provides the total value of the currently active inventory, converted
/// to the user's base currency.

final class InventoryValueProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// Provides the total value of the currently active inventory, converted
  /// to the user's base currency.
  InventoryValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryValueHash();

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    return inventoryValue(ref);
  }
}

String _$inventoryValueHash() => r'a0c7326063f689b5f0920bbc759c629414953c0c';

/// Provides the average item price in the currently active inventory,
/// converted to the user's base currency.

@ProviderFor(averagePrice)
final averagePriceProvider = AveragePriceProvider._();

/// Provides the average item price in the currently active inventory,
/// converted to the user's base currency.

final class AveragePriceProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// Provides the average item price in the currently active inventory,
  /// converted to the user's base currency.
  AveragePriceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'averagePriceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$averagePriceHash();

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    return averagePrice(ref);
  }
}

String _$averagePriceHash() => r'1c238360e6a80a4bc52b525732aaa6d763c64e1e';

/// Provides the count of priced items in the currently active inventory.

@ProviderFor(pricedItemCount)
final pricedItemCountProvider = PricedItemCountProvider._();

/// Provides the count of priced items in the currently active inventory.

final class PricedItemCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the count of priced items in the currently active inventory.
  PricedItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pricedItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pricedItemCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pricedItemCount(ref);
  }
}

String _$pricedItemCountHash() => r'00a05a6f3475067b3d4e3768217f63b0082795cd';

/// Provides the count of prices pending sync to Open Prices.

@ProviderFor(pendingSyncCount)
final pendingSyncCountProvider = PendingSyncCountProvider._();

/// Provides the count of prices pending sync to Open Prices.

final class PendingSyncCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provides the count of prices pending sync to Open Prices.
  PendingSyncCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSyncCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSyncCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingSyncCount(ref);
  }
}

String _$pendingSyncCountHash() => r'60e373dafaa001c83196704eef785aea37478af8';
