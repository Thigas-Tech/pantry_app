import 'package:flutter/foundation.dart';
import 'package:pantry_app/utils/money.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

/// The per-unit price of a product, expressed in the base unit of its
/// measurement group.
///
/// [unit] is one of 'pieces', 'g', or 'ml' (the base unit returned by
/// [UnitConverter.baseUnitFor]). Display layers scale the [amount] to the
/// most readable representation (per 100 g, per L, per piece).
@immutable
class UnitPrice {
  /// Creates a [UnitPrice].
  const UnitPrice({required this.amount, required this.unit});

  /// The price for a single base unit (one piece, one gram, one milliliter).
  final double amount;

  /// The base unit this price applies to.
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitPrice && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => 'UnitPrice(amount: $amount, unit: $unit)';
}

/// Pure, dependency-free helpers for unit-aware price math.
///
/// These functions know nothing about the database or the Open Food Facts
/// API — they convert and scale prices given already-resolved package sizes.
/// Callers decide where the package size comes from (price row, product
/// record, or inventory row).
class PriceCalculator {
  PriceCalculator._();

  /// Scales [price] down to the cost of [ingredientQuantity] in
  /// [ingredientUnit], given a package of [packageQuantity] in
  /// [packageUnit].
  ///
  /// Converts the ingredient quantity into the package unit when the two
  /// belong to the same measurement group (e.g. ml -> L, kg -> g), then
  /// multiplies the package [price] by the fraction used.
  ///
  /// Returns:
  ///   - 0.0 when the ingredient quantity is zero (nothing is used);
  ///   - null when the package size is missing, zero, negative, or
  ///     non-finite, when [packageUnit] is missing, when the price is not
  ///     finite or positive, when the units belong to different measurement
  ///     groups, or when the inputs are non-finite.
  ///
  /// The result is rounded to cents so recipe totals never carry fractional
  /// cents.
  static double? scaledIngredientCost({
    required double price,
    required double ingredientQuantity,
    required String ingredientUnit,
    double? packageQuantity,
    String? packageUnit,
  }) {
    final packageQty = packageQuantity;
    if (packageQty == null || !packageQty.isFinite || packageQty <= 0) {
      return null;
    }
    if (packageUnit == null) return null;
    if (!price.isFinite || price <= 0) return null;
    if (!ingredientQuantity.isFinite) return null;
    if (ingredientQuantity <= 0) return 0;
    if (!UnitConverter.areUnitsCompatible(ingredientUnit, packageUnit)) {
      return null;
    }

    final qtyInPackageUnits = UnitConverter.convert(
      ingredientQuantity,
      ingredientUnit,
      packageUnit,
    );
    final scaled = price * (qtyInPackageUnits / packageQty);
    if (!scaled.isFinite) return null;
    return Money.roundToCents(scaled);
  }

  /// Computes the price per base unit (piece, gram, or milliliter) of a
  /// package priced at [price], whose size is [packageQuantity]
  /// [packageUnit].
  ///
  /// Returns null when the package size is missing, zero, negative, or
  /// non-finite, when [packageUnit] is missing, or when [price] is not
  /// finite.
  static UnitPrice? unitPrice({
    required double price,
    double? packageQuantity,
    String? packageUnit,
  }) {
    final packageQty = packageQuantity;
    if (packageQty == null || !packageQty.isFinite || packageQty <= 0) {
      return null;
    }
    if (packageUnit == null) return null;
    if (!price.isFinite) return null;

    final base = UnitConverter.baseUnitFor(packageUnit);
    final double perUnit;
    if (base == 'g') {
      perUnit = price / UnitConverter.normalizeToGrams(packageQty, packageUnit);
    } else if (base == 'ml') {
      perUnit =
          price /
          UnitConverter.normalizeToMilliliters(
            packageQty,
            packageUnit,
          );
    } else {
      perUnit = price / packageQty;
    }
    if (!perUnit.isFinite) return null;
    return UnitPrice(amount: perUnit, unit: base);
  }
}
