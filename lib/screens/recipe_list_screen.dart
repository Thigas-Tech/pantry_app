import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/recipe_detail_screen.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:pantry_app/widgets/price_mask.dart';
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

class _RecipeListScreenState extends ConsumerState<RecipeListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipes),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final inventoriesAsync = ref.watch(inventoryListProvider);
              final activeId = ref.watch(activeInventoryProvider).value ?? 1;
              final inventories = inventoriesAsync.asData?.value;
              InventorySummary? match;
              for (final inv in inventories ?? const <InventorySummary>[]) {
                if (inv.id == activeId) {
                  match = inv;
                  break;
                }
              }
              final name = match != null
                  ? l10n.displayInventoryName(match.name)
                  : null;
              return InventorySwitcherCard(
                name: name,
                nutriscoreGrade: null,
                isLoading: inventoriesAsync.isLoading,
                onTap: () async {
                  final result = await Navigator.of(context).push<Object>(
                    MaterialPageRoute(
                      builder: (_) => const ManageInventoriesScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ref.invalidate(allRecipesProvider);
                  }
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final settings =
                  ref.watch(settingsProvider).value ?? const Settings();
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
            loading: () => Center(child: ProgressIndicatorHelper.build()),
            error: (e, _) => Center(child: Text(l10n.errorGeneric)),
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
              if (context.mounted) ref.invalidate(allRecipesProvider);
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
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final currencyCode = settings.baseCurrency;
    final symbol = currencySymbolFor(currencyCode);
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final averageCost =
        ref.watch(averageRecipeCostProvider((activeId, currencyCode))).value ??
        0.0;

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
            PriceMask(
              formattedPrice: '$symbol${averageCost.toStringAsFixed(2)}',
              child: Text(
                '$symbol${averageCost.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single recipe card showing name, ingredient count, and cost.
class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({
    required this.recipe,
    super.key,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
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
      confirmDismiss: (direction) {
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
        unawaited(
          ref
              .read(recipeServiceProvider)
              .deleteRecipe(recipe.id!)
              .then((_) => invalidateRecipes(ref)),
        );
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
          subtitle: Row(
            children: [
              _IngredientCountLabel(recipeId: recipe.id!),
              const SizedBox(width: 12),
              _RecipeNutriScoreBadge(recipeId: recipe.id!),
              const SizedBox(width: 8),
              _RecipeCostLabel(
                recipeId: recipe.id!,
                currencySymbol: symbol,
              ),
            ],
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
                if (context.mounted) ref.invalidate(allRecipesProvider);
              }),
            );
          },
        ),
      ),
    );
  }
}

/// A small Nutri-Score badge for a recipe card in the list.
class _RecipeNutriScoreBadge extends ConsumerWidget {
  const _RecipeNutriScoreBadge({required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGrade = ref.watch(recipeNutriScoreProvider(recipeId));
    return asyncGrade.when(
      data: (grade) {
        if (grade == null) return const SizedBox.shrink();
        return NutriScoreBadge(grade: grade.toLowerCase(), size: 20);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// A small label showing the ingredient count of a recipe.
class _IngredientCountLabel extends ConsumerWidget {
  const _IngredientCountLabel({required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count =
        ref.watch(allRecipeIngredientsProvider(recipeId)).value?.length ?? 0;
    return Text(l10n.ingredientCount(count));
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
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final baseCurrency =
        (ref.watch(settingsProvider).value ?? const Settings()).baseCurrency;
    final cost = ref
        .watch(recipeCostProvider((recipeId, activeId, baseCurrency)))
        .value;

    if (cost == null) return const SizedBox.shrink();
    if (cost <= 0) {
      return Text(
        l10n.recipeCostUnknown,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final formattedPrice = '$currencySymbol${cost.toStringAsFixed(2)}';
    return PriceMask(
      formattedPrice: formattedPrice,
      child: Text(
        formattedPrice,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
