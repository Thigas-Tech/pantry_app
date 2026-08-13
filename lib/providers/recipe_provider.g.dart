// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$allRecipesHash() => r'7f51fcf1827279802883f284bbd7c94360c8af89';

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

String _$recipeNutritionHash() => r'5707947178845512a94e9dd1ce95553eefbaafc6';

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
    r'7c1b3e8fc90a8dff8f79677d96785925e45807a4';

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
/// known scores. Uses only the local cache, never the network.

@ProviderFor(recipeNutriScore)
final recipeNutriScoreProvider = RecipeNutriScoreFamily._();

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores. Uses only the local cache, never the network.

final class RecipeNutriScoreProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the Nutri-Score grade for a recipe.
  ///
  /// Returns a grade letter ('A'–'E') or null if not enough ingredients have
  /// known scores. Uses only the local cache, never the network.
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

String _$recipeNutriScoreHash() => r'e5800af47bbf92f27fc72433487801d57700b3f0';

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores. Uses only the local cache, never the network.

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
  /// known scores. Uses only the local cache, never the network.

  RecipeNutriScoreProvider call(int recipeId) =>
      RecipeNutriScoreProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeNutriScoreProvider';
}
