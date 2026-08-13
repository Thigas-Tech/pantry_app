import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockFirebaseCacheService extends Mock implements FirebaseCacheService {}

class _MutableActiveInventory extends ActiveInventoryNotifier {
  _MutableActiveInventory(this.initial);

  final int initial;

  @override
  Future<int> build() async => initial;

  @override
  void setActiveInventory(int id) {
    state = AsyncValue.data(id);
  }
}

class _SaveRecipeTestWidget extends ConsumerStatefulWidget {
  const _SaveRecipeTestWidget({
    required this.name,
    required this.ingredients,
    this.existingRecipeId,
  });

  final String name;
  final int? existingRecipeId;
  final List<RecipeIngredient> ingredients;

  @override
  ConsumerState<_SaveRecipeTestWidget> createState() =>
      _SaveRecipeTestWidgetState();
}

class _SaveRecipeTestWidgetState extends ConsumerState<_SaveRecipeTestWidget> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        try {
          await ref
              .read(recipeServiceProvider)
              .saveRecipe(
                name: widget.name,
                existingRecipeId: widget.existingRecipeId,
                ingredients: widget.ingredients,
                activeInventoryId: await ref.read(
                  activeInventoryProvider.future,
                ),
              );
        } on Exception {
          // Expected for negative tests.
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _DeleteRecipeTestWidget extends ConsumerStatefulWidget {
  const _DeleteRecipeTestWidget({required this.id});

  final int id;

  @override
  ConsumerState<_DeleteRecipeTestWidget> createState() =>
      _DeleteRecipeTestWidgetState();
}

class _DeleteRecipeTestWidgetState
    extends ConsumerState<_DeleteRecipeTestWidget> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        await ref.read(recipeServiceProvider).deleteRecipe(widget.id);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  registerFallbackValue(const Recipe(name: ''));
  registerFallbackValue(const RecipeIngredient(recipeId: 0, name: ''));

  group('saveRecipe', () {
    late _MockDatabaseHelper mockDb;
    late _MockFirebaseCacheService mockCache;

    setUp(() {
      mockDb = _MockDatabaseHelper();
      mockCache = _MockFirebaseCacheService();
      when(() => mockDb.getRecipe(any())).thenAnswer((_) async => null);
      when(
        () => mockDb.insertRecipeWithIngredients(any(), any()),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDb.updateRecipeWithIngredients(any(), any()),
      ).thenAnswer((_) async => {});
    });

    testWidgets('calls cacheRecipe when creating a new recipe', (
      tester,
    ) async {
      when(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
            activeInventoryProvider.overrideWith(
              () => _MutableActiveInventory(1),
            ),
          ],
          child: const _SaveRecipeTestWidget(
            name: 'Soup',
            ingredients: [RecipeIngredient(recipeId: 0, name: 'Carrots')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(
        () => mockDb.insertRecipeWithIngredients(any(), any()),
      ).called(1);
      verify(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).called(1);
    });

    testWidgets('calls cacheRecipe when updating an existing recipe', (
      tester,
    ) async {
      when(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
            activeInventoryProvider.overrideWith(
              () => _MutableActiveInventory(1),
            ),
          ],
          child: const _SaveRecipeTestWidget(
            name: 'Soup',
            existingRecipeId: 1,
            ingredients: [RecipeIngredient(recipeId: 1, name: 'Carrots')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(
        () => mockDb.updateRecipeWithIngredients(any(), any()),
      ).called(1);
      verify(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).called(1);
    });

    testWidgets('caches recipe with correct id after insert', (tester) async {
      final captured = <(Recipe, List<RecipeIngredient>)>[];
      when(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).thenAnswer(
        (invocation) async {
          captured.add((
            invocation.positionalArguments[0] as Recipe,
            invocation.positionalArguments[1] as List<RecipeIngredient>,
          ));
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
            activeInventoryProvider.overrideWith(
              () => _MutableActiveInventory(1),
            ),
          ],
          child: const _SaveRecipeTestWidget(
            name: 'Soup',
            ingredients: [RecipeIngredient(recipeId: 0, name: 'Carrots')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      expect(captured.first.$1.id, 1);
    });

    testWidgets(
      'saveRecipe assigns a shared recipe id and passes it to cache',
      (
        tester,
      ) async {
        final captured = <(Recipe, List<RecipeIngredient>)>[];
        when(
          () => mockCache.cacheRecipe(
            any(),
            any(),
            recipeId: any(named: 'recipeId'),
          ),
        ).thenAnswer(
          (invocation) async {
            captured.add((
              invocation.positionalArguments[0] as Recipe,
              invocation.positionalArguments[1] as List<RecipeIngredient>,
            ));
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              firebaseCacheProvider.overrideWithValue(mockCache),
              activeInventoryProvider.overrideWith(
                () => _MutableActiveInventory(1),
              ),
            ],
            child: const _SaveRecipeTestWidget(
              name: 'Soup',
              ingredients: [RecipeIngredient(recipeId: 0, name: 'Carrots')],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(captured, hasLength(1));
        expect(
          captured.single.$1.sharedRecipeId,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ),
          ),
        );
      },
    );

    testWidgets('saveRecipe stamps the active inventory on create', (
      tester,
    ) async {
      final captured = <Recipe>[];
      when(() => mockDb.insertRecipeWithIngredients(any(), any())).thenAnswer(
        (invocation) async {
          captured.add(invocation.positionalArguments[0] as Recipe);
          return 1;
        },
      );
      when(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
            activeInventoryProvider.overrideWith(
              () => _MutableActiveInventory(2),
            ),
          ],
          child: const _SaveRecipeTestWidget(
            name: 'Soup',
            ingredients: [RecipeIngredient(recipeId: 0, name: 'Carrots')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      expect(captured.single.inventoryId, 2);
    });

    testWidgets('saveRecipe preserves existing inventory on update', (
      tester,
    ) async {
      when(() => mockDb.getRecipe(1)).thenAnswer(
        (_) async => const Recipe(
          id: 1,
          name: 'Soup',
          inventoryId: 3,
          createdAt: 1000,
        ),
      );
      final captured = <Recipe>[];
      when(() => mockDb.updateRecipeWithIngredients(any(), any())).thenAnswer(
        (invocation) async {
          captured.add(invocation.positionalArguments[0] as Recipe);
        },
      );
      when(
        () => mockCache.cacheRecipe(
          any(),
          any(),
          recipeId: any(named: 'recipeId'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
            activeInventoryProvider.overrideWith(
              () => _MutableActiveInventory(2),
            ),
          ],
          child: const _SaveRecipeTestWidget(
            name: 'Soup',
            existingRecipeId: 1,
            ingredients: [RecipeIngredient(recipeId: 1, name: 'Carrots')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      expect(captured.single.inventoryId, 3);
    });
  });

  group('deleteRecipe', () {
    late _MockDatabaseHelper mockDb;
    late _MockFirebaseCacheService mockCache;

    setUp(() {
      mockDb = _MockDatabaseHelper();
      mockCache = _MockFirebaseCacheService();
      when(
        () => mockCache.deleteSharedRecipe(any()),
      ).thenAnswer((_) async => {});
    });

    testWidgets('calls deleteSharedRecipe with the stored shared id', (
      tester,
    ) async {
      when(() => mockDb.getRecipe(1)).thenAnswer(
        (_) async => const Recipe(
          id: 1,
          name: 'Soup',
          createdAt: 1000,
          sharedRecipeId: 'shared-id-123',
        ),
      );
      when(() => mockDb.deleteRecipe(any())).thenAnswer((_) async => 1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(mockCache),
          ],
          child: const _DeleteRecipeTestWidget(id: 1),
        ),
      );

      await tester.pumpAndSettle();

      verify(() => mockDb.getRecipe(1)).called(1);
      verify(() => mockDb.deleteRecipe(1)).called(1);
      verify(() => mockCache.deleteSharedRecipe('shared-id-123')).called(1);
    });

    testWidgets(
      'does not call deleteSharedRecipe when recipe is null',
      (tester) async {
        when(() => mockDb.getRecipe(999)).thenAnswer((_) async => null);
        when(() => mockDb.deleteRecipe(any())).thenAnswer((_) async => 0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              firebaseCacheProvider.overrideWithValue(mockCache),
            ],
            child: const _DeleteRecipeTestWidget(id: 999),
          ),
        );

        await tester.pumpAndSettle();

        verify(() => mockDb.getRecipe(999)).called(1);
        verify(() => mockDb.deleteRecipe(999)).called(1);
        verifyNever(() => mockCache.deleteSharedRecipe(any()));
      },
    );

    testWidgets(
      'does not call deleteSharedRecipe when recipe has no shared id',
      (tester) async {
        when(() => mockDb.getRecipe(2)).thenAnswer(
          (_) async => const Recipe(id: 2, name: 'Soup', createdAt: 1000),
        );
        when(() => mockDb.deleteRecipe(any())).thenAnswer((_) async => 1);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              firebaseCacheProvider.overrideWithValue(mockCache),
            ],
            child: const _DeleteRecipeTestWidget(id: 2),
          ),
        );

        await tester.pumpAndSettle();

        verify(() => mockDb.deleteRecipe(2)).called(1);
        verifyNever(() => mockCache.deleteSharedRecipe(any()));
      },
    );
  });
}
