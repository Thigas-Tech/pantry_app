// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [RecipeService] used by screens and the recipe
/// providers.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.

@ProviderFor(recipeService)
final recipeServiceProvider = RecipeServiceProvider._();

/// Provides the singleton [RecipeService] used by screens and the recipe
/// providers.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.

final class RecipeServiceProvider
    extends $FunctionalProvider<RecipeService, RecipeService, RecipeService>
    with $Provider<RecipeService> {
  /// Provides the singleton [RecipeService] used by screens and the recipe
  /// providers.
  ///
  /// Kept alive for the app lifetime; the service holds no per-inventory
  /// state, so a single instance is safe.
  RecipeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeServiceHash();

  @$internal
  @override
  $ProviderElement<RecipeService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeService create(Ref ref) {
    return recipeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeService>(value),
    );
  }
}

String _$recipeServiceHash() => r'5d89deba79810e02ca9aeef591ff6d8eb13f0007';

/// Provides the cost of a single recipe for the given inventory and base
/// currency.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
/// query is cached across rebuilds and only recomputed when one of the
/// inputs changes.

@ProviderFor(recipeCost)
final recipeCostProvider = RecipeCostFamily._();

/// Provides the cost of a single recipe for the given inventory and base
/// currency.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
/// query is cached across rebuilds and only recomputed when one of the
/// inputs changes.

final class RecipeCostProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provides the cost of a single recipe for the given inventory and base
  /// currency.
  ///
  /// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
  /// query is cached across rebuilds and only recomputed when one of the
  /// inputs changes.
  RecipeCostProvider._({
    required RecipeCostFamily super.from,
    required (int, int, String) super.argument,
  }) : super(
         retry: null,
         name: r'recipeCostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeCostHash();

  @override
  String toString() {
    return r'recipeCostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    final argument = this.argument as (int, int, String);
    return recipeCost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeCostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeCostHash() => r'ec1e0f737bcd06bb07d9a5bb07fd0c4688f652df';

/// Provides the cost of a single recipe for the given inventory and base
/// currency.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
/// query is cached across rebuilds and only recomputed when one of the
/// inputs changes.

final class RecipeCostFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double>, (int, int, String)> {
  RecipeCostFamily._()
    : super(
        retry: null,
        name: r'recipeCostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the cost of a single recipe for the given inventory and base
  /// currency.
  ///
  /// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
  /// query is cached across rebuilds and only recomputed when one of the
  /// inputs changes.

  RecipeCostProvider call((int, int, String) args) =>
      RecipeCostProvider._(argument: args, from: this);

  @override
  String toString() => r'recipeCostProvider';
}

/// Provides the average cost across all recipes for the given inventory
/// and base currency.
///
/// Keyed by a (inventoryId, baseCurrency) record so the cost query is
/// cached across rebuilds.

@ProviderFor(averageRecipeCost)
final averageRecipeCostProvider = AverageRecipeCostFamily._();

/// Provides the average cost across all recipes for the given inventory
/// and base currency.
///
/// Keyed by a (inventoryId, baseCurrency) record so the cost query is
/// cached across rebuilds.

final class AverageRecipeCostProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provides the average cost across all recipes for the given inventory
  /// and base currency.
  ///
  /// Keyed by a (inventoryId, baseCurrency) record so the cost query is
  /// cached across rebuilds.
  AverageRecipeCostProvider._({
    required AverageRecipeCostFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'averageRecipeCostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$averageRecipeCostHash();

  @override
  String toString() {
    return r'averageRecipeCostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    final argument = this.argument as (int, String);
    return averageRecipeCost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AverageRecipeCostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$averageRecipeCostHash() => r'0a02f8e98875e026763ce48bfd3d84c7f7d06c97';

/// Provides the average cost across all recipes for the given inventory
/// and base currency.
///
/// Keyed by a (inventoryId, baseCurrency) record so the cost query is
/// cached across rebuilds.

final class AverageRecipeCostFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double>, (int, String)> {
  AverageRecipeCostFamily._()
    : super(
        retry: null,
        name: r'averageRecipeCostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the average cost across all recipes for the given inventory
  /// and base currency.
  ///
  /// Keyed by a (inventoryId, baseCurrency) record so the cost query is
  /// cached across rebuilds.

  AverageRecipeCostProvider call((int, String) args) =>
      AverageRecipeCostProvider._(argument: args, from: this);

  @override
  String toString() => r'averageRecipeCostProvider';
}

/// Provides the scaled cost per ingredient for a recipe, keyed by the
/// ingredient barcode.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
/// own inventory wins over the active one, matching [recipeCost].
/// Ingredients without a barcode or without a recorded price are absent
/// from the map.

@ProviderFor(recipeIngredientCosts)
final recipeIngredientCostsProvider = RecipeIngredientCostsFamily._();

/// Provides the scaled cost per ingredient for a recipe, keyed by the
/// ingredient barcode.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
/// own inventory wins over the active one, matching [recipeCost].
/// Ingredients without a barcode or without a recorded price are absent
/// from the map.

final class RecipeIngredientCostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  /// Provides the scaled cost per ingredient for a recipe, keyed by the
  /// ingredient barcode.
  ///
  /// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
  /// own inventory wins over the active one, matching [recipeCost].
  /// Ingredients without a barcode or without a recorded price are absent
  /// from the map.
  RecipeIngredientCostsProvider._({
    required RecipeIngredientCostsFamily super.from,
    required (int, int, String) super.argument,
  }) : super(
         retry: null,
         name: r'recipeIngredientCostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeIngredientCostsHash();

  @override
  String toString() {
    return r'recipeIngredientCostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    final argument = this.argument as (int, int, String);
    return recipeIngredientCosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeIngredientCostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeIngredientCostsHash() =>
    r'e323e13415b769e774c435ef7d8ea89b3606a587';

/// Provides the scaled cost per ingredient for a recipe, keyed by the
/// ingredient barcode.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
/// own inventory wins over the active one, matching [recipeCost].
/// Ingredients without a barcode or without a recorded price are absent
/// from the map.

final class RecipeIngredientCostsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, double>>,
          (int, int, String)
        > {
  RecipeIngredientCostsFamily._()
    : super(
        retry: null,
        name: r'recipeIngredientCostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the scaled cost per ingredient for a recipe, keyed by the
  /// ingredient barcode.
  ///
  /// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
  /// own inventory wins over the active one, matching [recipeCost].
  /// Ingredients without a barcode or without a recorded price are absent
  /// from the map.

  RecipeIngredientCostsProvider call((int, int, String) args) =>
      RecipeIngredientCostsProvider._(argument: args, from: this);

  @override
  String toString() => r'recipeIngredientCostsProvider';
}
