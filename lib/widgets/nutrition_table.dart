import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/utils/nutrient_catalog.dart';

/// A styled table that displays the nutritional values of a [Product].
///
/// Each row shows a nutrient name and its amount per 100 g / 100 ml. The
/// header uses the theme's primary container colour, and data rows
/// alternate between transparent and a subtle primary overlay for
/// readability in both light and dark themes.
///
/// The six core rows (energy, protein, carbs, fat, fiber, salt) are always
/// shown; any additional nutrients stored on the product are rendered below
/// them with their persisted unit.
class NutritionTable extends StatelessWidget {
  /// Creates a [NutritionTable] for the given [product].
  const NutritionTable({required this.product, super.key});

  /// The product whose nutrition data is displayed.
  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <_NutrientRow>[
      _NutrientRow(l10n.energy, '${product.energyKcal ?? '-'} kcal'),
      _NutrientRow(l10n.protein, '${product.proteinG ?? '-'} g'),
      _NutrientRow(l10n.carbs, '${product.carbsG ?? '-'} g'),
      _NutrientRow(l10n.fat, '${product.fatG ?? '-'} g'),
      _NutrientRow(l10n.fiber, '${product.fiberG ?? '-'} g'),
      _NutrientRow(l10n.salt, '${product.saltG ?? '-'} g'),
      for (final nutrient in product.additionalNutrients)
        _NutrientRow(
          _labelFor(context, nutrient),
          '${_formatValue(nutrient.value)} ${nutrient.unit}',
        ),
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 0.5,
      ),
      columnWidths: const {
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
                child: Text(rows[i].value),
              ),
            ],
          ),
      ],
    );
  }

  /// Returns the localized label for an additional nutrient.
  ///
  /// Falls back to the nutrient's Open Food Facts tag when the nutrient is
  /// not part of the curated catalog.
  String _labelFor(BuildContext context, ProductNutrient nutrient) {
    final nutrientType = NutrientCatalog.nutrientFromOffTag(nutrient.offTag);
    if (nutrientType == null) return nutrient.offTag;
    return AppLocalizations.of(context)!.localizeNutrient(nutrientType);
  }

  /// Formats a nutrient value for display.
  ///
  /// Whole numbers render without a trailing decimal (20 to "20") so the
  /// table reads cleanly; fractional values keep their decimals.
  String _formatValue(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';
}

class _NutrientRow {
  const _NutrientRow(this.name, this.value);
  final String name;
  final String value;
}
