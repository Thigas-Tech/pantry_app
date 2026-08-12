// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [RecipeDao] instance.

@ProviderFor(recipeDao)
final recipeDaoProvider = RecipeDaoProvider._();

/// Provides a singleton [RecipeDao] instance.

final class RecipeDaoProvider
    extends $FunctionalProvider<RecipeDao, RecipeDao, RecipeDao>
    with $Provider<RecipeDao> {
  /// Provides a singleton [RecipeDao] instance.
  RecipeDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeDaoHash();

  @$internal
  @override
  $ProviderElement<RecipeDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeDao create(Ref ref) {
    return recipeDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeDao>(value),
    );
  }
}

String _$recipeDaoHash() => r'6ac7381bc4903d55e0209f663d866baf3ae9a04f';

/// Provides a singleton [RecipeIngredientDao] instance.

@ProviderFor(recipeIngredientDao)
final recipeIngredientDaoProvider = RecipeIngredientDaoProvider._();

/// Provides a singleton [RecipeIngredientDao] instance.

final class RecipeIngredientDaoProvider
    extends
        $FunctionalProvider<
          RecipeIngredientDao,
          RecipeIngredientDao,
          RecipeIngredientDao
        >
    with $Provider<RecipeIngredientDao> {
  /// Provides a singleton [RecipeIngredientDao] instance.
  RecipeIngredientDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeIngredientDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeIngredientDaoHash();

  @$internal
  @override
  $ProviderElement<RecipeIngredientDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeIngredientDao create(Ref ref) {
    return recipeIngredientDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeIngredientDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeIngredientDao>(value),
    );
  }
}

String _$recipeIngredientDaoHash() =>
    r'6f7843d53e1d155f417b179d6290b1bb67d5e0a4';

@ProviderFor(_currencyService)
final _currencyServiceProvider = _CurrencyServiceProvider._();

final class _CurrencyServiceProvider
    extends
        $FunctionalProvider<CurrencyService, CurrencyService, CurrencyService>
    with $Provider<CurrencyService> {
  _CurrencyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_currencyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_currencyServiceHash();

  @$internal
  @override
  $ProviderElement<CurrencyService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CurrencyService create(Ref ref) {
    return _currencyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrencyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrencyService>(value),
    );
  }
}

String _$_currencyServiceHash() => r'960b4626fd1f5ee1a99537b2f52507979f390e16';

/// Provides all recipes for the active inventory, ordered by updated_at
/// descending.
///
/// Watches [activeInventoryProvider] so the list automatically reloads when
/// the user switches pantries.

@ProviderFor(allRecipes)
final allRecipesProvider = AllRecipesProvider._();

/// Provides all recipes for the active inventory, ordered by updated_at
/// descending.
///
/// Watches [activeInventoryProvider] so the list automatically reloads when
/// the user switches pantries.

final class AllRecipesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recipe>>,
          List<Recipe>,
          FutureOr<List<Recipe>>
        >
    with $FutureModifier<List<Recipe>>, $FutureProvider<List<Recipe>> {
  /// Provides all recipes for the active inventory, ordered by updated_at
  /// descending.
  ///
  /// Watches [activeInventoryProvider] so the list automatically reloads when
  /// the user switches pantries.
  AllRecipesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allRecipesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allRecipesHash();

  @$internal
  @override
  $FutureProviderElement<List<Recipe>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Recipe>> create(Ref ref) {
    return allRecipes(ref);
  }
}

String _$allRecipesHash() => r'bf79441f7f55125cd908c1a3243cdd98a2e70086';

/// Provides ingredients for a specific recipe.

@ProviderFor(allRecipeIngredients)
final allRecipeIngredientsProvider = AllRecipeIngredientsFamily._();

/// Provides ingredients for a specific recipe.

final class AllRecipeIngredientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecipeIngredient>>,
          List<RecipeIngredient>,
          FutureOr<List<RecipeIngredient>>
        >
    with
        $FutureModifier<List<RecipeIngredient>>,
        $FutureProvider<List<RecipeIngredient>> {
  /// Provides ingredients for a specific recipe.
  AllRecipeIngredientsProvider._({
    required AllRecipeIngredientsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'allRecipeIngredientsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allRecipeIngredientsHash();

  @override
  String toString() {
    return r'allRecipeIngredientsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RecipeIngredient>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecipeIngredient>> create(Ref ref) {
    final argument = this.argument as int;
    return allRecipeIngredients(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllRecipeIngredientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allRecipeIngredientsHash() =>
    r'b042e103d11d99d240ce308308334dff8b15cfac';

/// Provides ingredients for a specific recipe.

final class AllRecipeIngredientsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RecipeIngredient>>, int> {
  AllRecipeIngredientsFamily._()
    : super(
        retry: null,
        name: r'allRecipeIngredientsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides ingredients for a specific recipe.

  AllRecipeIngredientsProvider call(int recipeId) =>
      AllRecipeIngredientsProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'allRecipeIngredientsProvider';
}

/// Provides aggregated nutrition data for a recipe.
///
/// Returns [RecipeNutrition] computed from the recipe's ingredients and their
/// product nutrition data. Auto-disposes when no listener remains.

@ProviderFor(recipeNutrition)
final recipeNutritionProvider = RecipeNutritionFamily._();

/// Provides aggregated nutrition data for a recipe.
///
/// Returns [RecipeNutrition] computed from the recipe's ingredients and their
/// product nutrition data. Auto-disposes when no listener remains.

final class RecipeNutritionProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeNutrition?>,
          RecipeNutrition?,
          FutureOr<RecipeNutrition?>
        >
    with $FutureModifier<RecipeNutrition?>, $FutureProvider<RecipeNutrition?> {
  /// Provides aggregated nutrition data for a recipe.
  ///
  /// Returns [RecipeNutrition] computed from the recipe's ingredients and their
  /// product nutrition data. Auto-disposes when no listener remains.
  RecipeNutritionProvider._({
    required RecipeNutritionFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recipeNutritionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeNutritionHash();

  @override
  String toString() {
    return r'recipeNutritionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecipeNutrition?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecipeNutrition?> create(Ref ref) {
    final argument = this.argument as int;
    return recipeNutrition(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeNutritionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeNutritionHash() => r'1274a79f40f9fbf1f6123733958a7d22ee0e79ad';

/// Provides aggregated nutrition data for a recipe.
///
/// Returns [RecipeNutrition] computed from the recipe's ingredients and their
/// product nutrition data. Auto-disposes when no listener remains.

final class RecipeNutritionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecipeNutrition?>, int> {
  RecipeNutritionFamily._()
    : super(
        retry: null,
        name: r'recipeNutritionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides aggregated nutrition data for a recipe.
  ///
  /// Returns [RecipeNutrition] computed from the recipe's ingredients and their
  /// product nutrition data. Auto-disposes when no listener remains.

  RecipeNutritionProvider call(int recipeId) =>
      RecipeNutritionProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeNutritionProvider';
}

/// Provides ingredients with their product data (including image URL).
///
/// Fetches each ingredient's product via [ProductRepository] so that images
/// are available for display. Ingredients without a barcode get a null
/// product.

@ProviderFor(recipeIngredientsWithProducts)
final recipeIngredientsWithProductsProvider =
    RecipeIngredientsWithProductsFamily._();

/// Provides ingredients with their product data (including image URL).
///
/// Fetches each ingredient's product via [ProductRepository] so that images
/// are available for display. Ingredients without a barcode get a null
/// product.

final class RecipeIngredientsWithProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IngredientWithProduct>>,
          List<IngredientWithProduct>,
          FutureOr<List<IngredientWithProduct>>
        >
    with
        $FutureModifier<List<IngredientWithProduct>>,
        $FutureProvider<List<IngredientWithProduct>> {
  /// Provides ingredients with their product data (including image URL).
  ///
  /// Fetches each ingredient's product via [ProductRepository] so that images
  /// are available for display. Ingredients without a barcode get a null
  /// product.
  RecipeIngredientsWithProductsProvider._({
    required RecipeIngredientsWithProductsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recipeIngredientsWithProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeIngredientsWithProductsHash();

  @override
  String toString() {
    return r'recipeIngredientsWithProductsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<IngredientWithProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IngredientWithProduct>> create(Ref ref) {
    final argument = this.argument as int;
    return recipeIngredientsWithProducts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeIngredientsWithProductsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeIngredientsWithProductsHash() =>
    r'298f5257153649329f460b78531cc21061665c8f';

/// Provides ingredients with their product data (including image URL).
///
/// Fetches each ingredient's product via [ProductRepository] so that images
/// are available for display. Ingredients without a barcode get a null
/// product.

final class RecipeIngredientsWithProductsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<IngredientWithProduct>>, int> {
  RecipeIngredientsWithProductsFamily._()
    : super(
        retry: null,
        name: r'recipeIngredientsWithProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides ingredients with their product data (including image URL).
  ///
  /// Fetches each ingredient's product via [ProductRepository] so that images
  /// are available for display. Ingredients without a barcode get a null
  /// product.

  RecipeIngredientsWithProductsProvider call(int recipeId) =>
      RecipeIngredientsWithProductsProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeIngredientsWithProductsProvider';
}

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores.

@ProviderFor(recipeNutriScore)
final recipeNutriScoreProvider = RecipeNutriScoreFamily._();

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores.

final class RecipeNutriScoreProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the Nutri-Score grade for a recipe.
  ///
  /// Returns a grade letter ('A'–'E') or null if not enough ingredients have
  /// known scores.
  RecipeNutriScoreProvider._({
    required RecipeNutriScoreFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recipeNutriScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeNutriScoreHash();

  @override
  String toString() {
    return r'recipeNutriScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as int;
    return recipeNutriScore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeNutriScoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeNutriScoreHash() => r'4388929de4af2fe0c84d09107681b4a7f2a58d4a';

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores.

final class RecipeNutriScoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, int> {
  RecipeNutriScoreFamily._()
    : super(
        retry: null,
        name: r'recipeNutriScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the Nutri-Score grade for a recipe.
  ///
  /// Returns a grade letter ('A'–'E') or null if not enough ingredients have
  /// known scores.

  RecipeNutriScoreProvider call(int recipeId) =>
      RecipeNutriScoreProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeNutriScoreProvider';
}
