import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/recipe_detail_screen.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';

/// Displays all saved recipes with cost information.
///
/// Shows a list of recipe cards, an average cost banner, and an empty state.
/// Tapping a recipe opens its detail screen. Swiping left deletes with undo.
class RecipeListScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeListScreen].
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipes),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(settingsProvider);
              if (!settings.priceTrackingEnabled) {
                return const SizedBox.shrink();
              }
              return const PriceVisibilityToggle();
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final recipesAsync = ref.watch(allRecipesProvider);

          return recipesAsync.when(
            data: (recipes) => _buildContent(context, l10n, recipes, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_recipe',
        onPressed: () {
          unawaited(
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const RecipeFormScreen(),
              ),
            ).then((_) {
              ref.invalidate(allRecipesProvider);
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<Recipe> recipes,
    WidgetRef ref,
  ) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noRecipes,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noRecipesSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allRecipesProvider);
        await ref.read(allRecipesProvider.future);
      },
      child: ListView(
        children: [
          _AverageCostBanner(ref: ref),
          ...recipes.map(
            (recipe) => _RecipeCard(
              key: ValueKey(recipe.id),
              recipe: recipe,
            ),
          ),
        ],
      ),
    );
  }
}

/// A banner card showing the average cost across all recipes.
class _AverageCostBanner extends ConsumerWidget {
  const _AverageCostBanner({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final currencyCode = settings.baseCurrency;
    final symbol = currencySymbolFor(currencyCode);

    return FutureBuilder<double>(
      future: calculateAverageRecipeCost(ref),
      builder: (context, snapshot) {
        final cost = snapshot.data ?? 0.0;

        return Card(
          margin: const EdgeInsets.all(16).copyWith(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet),
                const SizedBox(width: 12),
                Text(
                  l10n.recipeAverageCost,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '$symbol${cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single recipe card showing name, ingredient count, and cost.
class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final currencyCode = settings.baseCurrency;
    final symbol = currencySymbolFor(currencyCode);

    return Dismissible(
      key: ValueKey('recipe_${recipe.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteRecipeConfirm),
            content: Text(recipe.name),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        unawaited(deleteRecipe(ref, recipe.id!));
        SnackbarHelper.showUndo(
          context,
          l10n.recipeDeleted,
          () {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RecipeFormScreen(
                    existingRecipeId: recipe.id,
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          title: Text(recipe.name),
          subtitle: FutureBuilder<List<RecipeIngredient>>(
            future: ref
                .read(databaseProvider)
                .getRecipeIngredients(
                  recipe.id!,
                ),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                children: [
                  Text(l10n.ingredientCount(count)),
                  const SizedBox(width: 12),
                  _RecipeCostLabel(
                    recipeId: recipe.id!,
                    currencySymbol: symbol,
                  ),
                ],
              );
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RecipeDetailScreen(recipeId: recipe.id!),
                ),
              ).then((_) {
                ref.invalidate(allRecipesProvider);
              }),
            );
          },
        ),
      ),
    );
  }
}

/// A label showing the calculated cost of a single recipe.
class _RecipeCostLabel extends ConsumerWidget {
  const _RecipeCostLabel({
    required this.recipeId,
    required this.currencySymbol,
  });

  final int recipeId;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<double>(
      future: calculateRecipeCost(ref, recipeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final cost = snapshot.data!;
        if (cost <= 0) {
          return Text(
            l10n.recipeCostUnknown,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Text(
          '$currencySymbol${cost.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
