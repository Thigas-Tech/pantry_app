// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the shared [RecipeApiClient] instance.
///
/// keepAlive because recipe suggestion lookup is used by the notification
/// coordinator on startup and by the settings screen for the whole session.

@ProviderFor(recipeApiClient)
final recipeApiClientProvider = RecipeApiClientProvider._();

/// Provides the shared [RecipeApiClient] instance.
///
/// keepAlive because recipe suggestion lookup is used by the notification
/// coordinator on startup and by the settings screen for the whole session.

final class RecipeApiClientProvider
    extends
        $FunctionalProvider<RecipeApiClient, RecipeApiClient, RecipeApiClient>
    with $Provider<RecipeApiClient> {
  /// Provides the shared [RecipeApiClient] instance.
  ///
  /// keepAlive because recipe suggestion lookup is used by the notification
  /// coordinator on startup and by the settings screen for the whole session.
  RecipeApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeApiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeApiClientHash();

  @$internal
  @override
  $ProviderElement<RecipeApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeApiClient create(Ref ref) {
    return recipeApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeApiClient>(value),
    );
  }
}

String _$recipeApiClientHash() => r'3aab803dc29afae9337bffbe2a9acbd9614b41f1';

/// Provides the shared [RecipeSuggestionService] instance.
///
/// keepAlive for the same reason as [recipeApiClientProvider].

@ProviderFor(recipeSuggestionService)
final recipeSuggestionServiceProvider = RecipeSuggestionServiceProvider._();

/// Provides the shared [RecipeSuggestionService] instance.
///
/// keepAlive for the same reason as [recipeApiClientProvider].

final class RecipeSuggestionServiceProvider
    extends
        $FunctionalProvider<
          RecipeSuggestionService,
          RecipeSuggestionService,
          RecipeSuggestionService
        >
    with $Provider<RecipeSuggestionService> {
  /// Provides the shared [RecipeSuggestionService] instance.
  ///
  /// keepAlive for the same reason as [recipeApiClientProvider].
  RecipeSuggestionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeSuggestionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeSuggestionServiceHash();

  @$internal
  @override
  $ProviderElement<RecipeSuggestionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeSuggestionService create(Ref ref) {
    return recipeSuggestionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeSuggestionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeSuggestionService>(value),
    );
  }
}

String _$recipeSuggestionServiceHash() =>
    r'140e02d9e492ccdbc0685962881e4fa8c3e25743';
