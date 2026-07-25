import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';

/// A styled table that displays the nutritional values of a recipe.
///
/// Shows each nutrient per 100 g and (when servings > 0) per serving.
/// The header uses the theme's primary container colour, and data rows
/// alternate between transparent and a subtle primary overlay.
class RecipeNutritionTable extends StatelessWidget {
  /// Creates a [RecipeNutritionTable] for the given [nutrition].
  const RecipeNutritionTable({required this.nutrition, super.key});

  /// The aggregated recipe nutrition data to display.
  final RecipeNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showPerServing = nutrition.servings > 0;

    final rows = <_NutrientRow>[
      _NutrientRow(
        l10n.energy,
        nutrition.per100gEnergyKcal,
        showPerServing ? nutrition.perServingEnergyKcal : null,
      ),
      _NutrientRow(
        l10n.protein,
        nutrition.per100gProteinG,
        showPerServing ? nutrition.perServingProteinG : null,
      ),
      _NutrientRow(
        l10n.carbs,
        nutrition.per100gCarbsG,
        showPerServing ? nutrition.perServingCarbsG : null,
      ),
      _NutrientRow(
        l10n.fat,
        nutrition.per100gFatG,
        showPerServing ? nutrition.perServingFatG : null,
      ),
      _NutrientRow(
        l10n.fiber,
        nutrition.per100gFiberG,
        showPerServing ? nutrition.perServingFiberG : null,
      ),
      _NutrientRow(
        l10n.salt,
        nutrition.per100gSaltG,
        showPerServing ? nutrition.perServingSaltG : null,
      ),
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 0.5,
      ),
      columnWidths: showPerServing
          ? const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            }
          : const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
            },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.nutrient,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.per100g,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (showPerServing)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.recipeNutritionPerServing,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(rows[i].name),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(rows[i].per100g),
              ),
              if (showPerServing)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(rows[i].perServing),
                ),
            ],
          ),
      ],
    );
  }
}

class _NutrientRow {
  const _NutrientRow(this.name, this.per100gValue, this.perServingValue);
  final String name;

  String get per100g => '${per100gValue.toStringAsFixed(1)} g';
  final double per100gValue;
  final double? perServingValue;

  String get perServing =>
      perServingValue != null ? '${perServingValue!.toStringAsFixed(1)} g' : '';
}
