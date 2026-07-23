import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'recipe_form_screen.dart';

/// Displays a single recipe in read-only mode with ingredients, instructions,
/// cost, and a prominent "I made this" action that deducts ingredients from
/// inventory and logs the event to recipe_history.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeDetailScreen] for the given [recipeId].
  const RecipeDetailScreen({super.key, required this.recipeId});

  /// The id of the recipe to display.
  final int recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  List<RecipeIngredient> _ingredients = [];
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
    if (!mounted) return;
    setState(() {
      _recipe = recipe;
      _ingredients = ingredients;
      _isLoading = false;
    });
  }

  Future<void> _cook() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCooking = true);
    try {
      final result = await cookRecipe(ref, widget.recipeId);
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
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _isCooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
          ? Center(child: Text(l10n.noRecipes))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.recipeIngredients,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._ingredients.map(
                  (ing) => ListTile(
                    dense: true,
                    title: Text('${ing.quantity} x ${ing.name}'),
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
                  future: calculateRecipeCost(ref, widget.recipeId),
                  builder: (context, snapshot) {
                    final cost = snapshot.data ?? 0.0;
                    final formatted = '$symbol${cost.toStringAsFixed(2)}';
                    return Row(
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
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCooking ? null : _cook,
                    icon: _isCooking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
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
}
