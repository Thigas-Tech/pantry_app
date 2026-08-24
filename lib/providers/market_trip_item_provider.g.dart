// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_trip_item_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates adding a scanned (or produce-searched) product to a market
/// trip as purchased, applying an optional price and expiry in one unit of
/// work.
///
/// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
/// lifecycle live in the screens. Writes go through
/// [shoppingListServiceProvider] and the shopping list providers for the
/// trip inventory are invalidated after every mutation.

@ProviderFor(MarketTripItemController)
final marketTripItemControllerProvider = MarketTripItemControllerFamily._();

/// Orchestrates adding a scanned (or produce-searched) product to a market
/// trip as purchased, applying an optional price and expiry in one unit of
/// work.
///
/// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
/// lifecycle live in the screens. Writes go through
/// [shoppingListServiceProvider] and the shopping list providers for the
/// trip inventory are invalidated after every mutation.
final class MarketTripItemControllerProvider
    extends $NotifierProvider<MarketTripItemController, MarketTripItemState> {
  /// Orchestrates adding a scanned (or produce-searched) product to a market
  /// trip as purchased, applying an optional price and expiry in one unit of
  /// work.
  ///
  /// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
  /// lifecycle live in the screens. Writes go through
  /// [shoppingListServiceProvider] and the shopping list providers for the
  /// trip inventory are invalidated after every mutation.
  MarketTripItemControllerProvider._({
    required MarketTripItemControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'marketTripItemControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$marketTripItemControllerHash();

  @override
  String toString() {
    return r'marketTripItemControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MarketTripItemController create() => MarketTripItemController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketTripItemState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketTripItemState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketTripItemControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketTripItemControllerHash() =>
    r'04f66f3515e1f2946f4591f9eb9857f7d84ca01f';

/// Orchestrates adding a scanned (or produce-searched) product to a market
/// trip as purchased, applying an optional price and expiry in one unit of
/// work.
///
/// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
/// lifecycle live in the screens. Writes go through
/// [shoppingListServiceProvider] and the shopping list providers for the
/// trip inventory are invalidated after every mutation.

final class MarketTripItemControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MarketTripItemController,
          MarketTripItemState,
          MarketTripItemState,
          MarketTripItemState,
          int
        > {
  MarketTripItemControllerFamily._()
    : super(
        retry: null,
        name: r'marketTripItemControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Orchestrates adding a scanned (or produce-searched) product to a market
  /// trip as purchased, applying an optional price and expiry in one unit of
  /// work.
  ///
  /// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
  /// lifecycle live in the screens. Writes go through
  /// [shoppingListServiceProvider] and the shopping list providers for the
  /// trip inventory are invalidated after every mutation.

  MarketTripItemControllerProvider call(int tripId) =>
      MarketTripItemControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'marketTripItemControllerProvider';
}

/// Orchestrates adding a scanned (or produce-searched) product to a market
/// trip as purchased, applying an optional price and expiry in one unit of
/// work.
///
/// Kept free of UI concerns: navigation, snackbars, and the scan-resolution
/// lifecycle live in the screens. Writes go through
/// [shoppingListServiceProvider] and the shopping list providers for the
/// trip inventory are invalidated after every mutation.

abstract class _$MarketTripItemController
    extends $Notifier<MarketTripItemState> {
  late final _$args = ref.$arg as int;
  int get tripId => _$args;

  MarketTripItemState build(int tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MarketTripItemState, MarketTripItemState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MarketTripItemState, MarketTripItemState>,
              MarketTripItemState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
