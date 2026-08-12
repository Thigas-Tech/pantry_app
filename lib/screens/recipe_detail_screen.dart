import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:pantry_app/screens/recipe_history_screen.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'package:pantry_app/widgets/recipe_nutrition_table.dart';

/// Displays a single recipe in read-only mode with ingredients, instructions,
/// cost, and a prominent "I made this" action that deducts ingredients from
/// inventory and logs the event to recipe_history.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeDetailScreen] for the given [recipeId].
  const RecipeDetailScreen({required this.recipeId, super.key});

  /// The id of the recipe to display.
  final int recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isCooking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final recipe = await db.getRecipe(widget.recipeId);
    final ingredients = await db.getRecipeIngredients(widget.recipeId);
    logInfo(
      'Recipe ${widget.recipeId} loaded: ${recipe?.name ?? 'null'} '
      '(${ingredients.length} ingredients)',
    );
    if (!mounted) return;
    setState(() {
      _recipe = recipe;
      _isLoading = false;
    });
  }

  Future<void> _cook() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCooking = true);
    logInfo('Cooking recipe ${widget.recipeId}...');
    try {
      final result = await ref
          .read(recipeServiceProvider)
          .cookRecipe(
            widget.recipeId,
            activeInventoryId: ref.read(activeInventoryProvider),
            baseCurrency: ref.read(settingsProvider).baseCurrency,
          );
      logInfo('Recipe ${widget.recipeId} cooked successfully');
      if (!mounted) return;
      SnackbarHelper.showUndo(
        context,
        l10n.cookRecipeSuccess,
        () async {
          final db = ref.read(databaseProvider);
          final database = await db.database;
          await database.transaction((txn) async {
            for (final row in result.affectedRows) {
              final existing = await txn.query(
                'inventory',
                where: 'id = ?',
                whereArgs: [row.rowId],
              );
              if (existing.isNotEmpty) {
                await txn.update(
                  'inventory',
                  {'quantity': row.originalQuantity},
                  where: 'id = ?',
                  whereArgs: [row.rowId],
                );
              } else {
                final data = Map<String, dynamic>.from(row.originalRow);
                data['quantity'] = row.originalQuantity;
                data.remove('id');
                await txn.insert('inventory', data);
              }
            }
            await txn.delete(
              'recipe_history',
              where: 'id = ?',
              whereArgs: [result.historyEntryId],
            );
          });
          ref.invalidate(pantryProvider);
          invalidateRecipes(ref);
        },
      );
      if (!mounted) return;
      setState(() => _isCooking = false);
    } on RecipeCookException catch (e) {
      logException('Failed to cook recipe ${widget.recipeId}', e, null);
      if (!mounted) return;
      final msg = e.isEmpty
          ? l10n.recipeNoIngredients
          : e.shortages.entries
                .map((entry) => l10n.recipeShortage(entry.key, entry.value))
                .join('\n');
      SnackbarHelper.showError(context, msg);
      setState(() => _isCooking = false);
    } on Exception catch (e, st) {
      logException('Failed to cook recipe ${widget.recipeId}', e, st);
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.recipeCookFailed);
      setState(() => _isCooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final priceTrackingEnabled = settings.priceTrackingEnabled;
    final currencyCode = settings.baseCurrency;
    final symbol = currencySymbolFor(currencyCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?.name ?? ''),
        actions: [
          if (priceTrackingEnabled) const PriceVisibilityToggle(),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeFormScreen(
                      existingRecipeId: widget.recipeId,
                    ),
                  ),
                ).then((_) => _load()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeHistoryScreen(
                      recipeId: widget.recipeId,
                      recipeName: _recipe?.name ?? '',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: ProgressIndicatorHelper.build())
          : _recipe == null
          ? Center(child: Text(l10n.noRecipes))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final asyncData = ref.watch(
                      recipeIngredientsWithProductsProvider(widget.recipeId),
                    );
                    return asyncData.when(
                      data: (data) {
                        final grouped = <String, _DisplayIngredient>{};
                        for (final item in data) {
                          final key =
                              item.ingredient.barcode ?? item.ingredient.name;
                          final existing = grouped[key];
                          if (existing != null) {
                            grouped[key] = existing.copyWith(
                              totalQuantity:
                                  existing.totalQuantity +
                                  item.ingredient.quantity,
                            );
                          } else {
                            grouped[key] = _DisplayIngredient(
                              name: item.ingredient.name,
                              totalQuantity: item.ingredient.quantity,
                              unit: item.ingredient.unit,
                              barcode: item.ingredient.barcode,
                              product: item.product,
                            );
                          }
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${grouped.length} ${l10n.recipeIngredients}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...grouped.values.map(
                              (g) => ListTile(
                                dense: true,
                                leading: _buildIngredientImage(
                                  g.product?.imageUrl,
                                  g.barcode,
                                ),
                                title: Text(
                                  '${g.totalQuantity} x ${g.name}',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Text(
                        l10n.recipeIngredients,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      error: (_, _) => Text(
                        l10n.recipeIngredients,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  },
                ),
                const Divider(),
                _NutritionSection(recipeId: widget.recipeId),
                if (_recipe!.servings == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.setServingsHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const Divider(),
                if (_recipe!.instructions.isNotEmpty) ...[
                  Text(
                    l10n.recipeInstructions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_recipe!.instructions),
                  const SizedBox(height: 16),
                ],
                FutureBuilder<double>(
                  future: ref
                      .read(recipeServiceProvider)
                      .calculateRecipeCost(
                        widget.recipeId,
                        activeInventoryId: ref.read(activeInventoryProvider),
                        baseCurrency: ref.read(settingsProvider).baseCurrency,
                      ),
                  builder: (context, snapshot) {
                    final cost = snapshot.data ?? 0.0;
                    final formatted = '$symbol${cost.toStringAsFixed(2)}';
                    final servings = _recipe!.servings;
                    final perServing = servings > 0 ? cost / servings : 0.0;
                    final perServingFormatted = perServing > 0
                        ? '$symbol${perServing.toStringAsFixed(2)}'
                        : null;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.recipeCost,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            PriceMask(
                              formattedPrice: formatted,
                              child: Text(
                                formatted,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (perServingFormatted != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                l10n.costPerServing,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              PriceMask(
                                formattedPrice: perServingFormatted,
                                child: Text(
                                  perServingFormatted,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCooking ? null : _cook,
                    icon: _isCooking
                        ? ProgressIndicatorHelper.build(
                            size: 18,
                            strokeWidth: 2,
                          )
                        : const Icon(Icons.restaurant),
                    label: Text(l10n.madeRecipe),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIngredientImage(String? imageUrl, String? barcode) {
    if (imageUrl == null || barcode == null) {
      return _fallbackIngredientIcon();
    }
    final imageCache = ref.read(imageCacheProvider);
    return FutureBuilder<String?>(
      future: imageCache.cacheImage(imageUrl, barcode),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.file(
              File(snapshot.data!),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackIngredientIcon(),
            ),
          );
        }
        return ClipOval(
          child: Image.network(
            imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return CircleAvatar(
                radius: 20,
                child: ProgressIndicatorHelper.build(),
              );
            },
            errorBuilder: (_, _, _) => _fallbackIngredientIcon(),
          ),
        );
      },
    );
  }

  Widget _fallbackIngredientIcon() {
    return const CircleAvatar(radius: 20, child: Icon(Icons.fastfood));
  }
}

class _DisplayIngredient {
  const _DisplayIngredient({
    required this.name,
    required this.totalQuantity,
    required this.unit,
    this.barcode,
    this.product,
  });

  final String name;
  final String? barcode;
  final double totalQuantity;
  final String unit;
  final Product? product;

  _DisplayIngredient copyWith({double? totalQuantity}) => _DisplayIngredient(
    name: name,
    totalQuantity: totalQuantity ?? this.totalQuantity,
    unit: unit,
    barcode: barcode,
    product: product,
  );
}

/// Displays the aggregated nutrition table and Nutri-Score badge for a recipe.
class _NutritionSection extends ConsumerWidget {
  const _NutritionSection({required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nutritionAsync = ref.watch(recipeNutritionProvider(recipeId));
    final nutriscoreAsync = ref.watch(recipeNutriScoreProvider(recipeId));

    return nutritionAsync.when(
      data: (nutrition) {
        if (nutrition == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.nutritionInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                nutriscoreAsync.when(
                  data: (grade) {
                    if (grade == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Text(
                          l10n.recipeNutriScore,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        NutriScoreBadge(grade: grade.toLowerCase()),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RecipeNutritionTable(nutrition: nutrition),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
