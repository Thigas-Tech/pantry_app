import 'package:flutter/foundation.dart';

/// The result of parsing a quantity string.
@immutable
class ParsedQuantity {
  /// Creates a [ParsedQuantity].
  const ParsedQuantity({required this.amount, required this.unit});

  /// The numeric amount.
  final double amount;

  /// The normalized unit string.
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedQuantity && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => 'ParsedQuantity(amount: $amount, unit: $unit)';
}

/// Parses quantity strings from the Open Food Facts API into numeric
/// amount and normalized unit pairs.
///
/// Handles formats like "500 ml", "3 x 150 g", and "6 eggs", plus unit
/// normalization such as cl to ml, kilogram to kg, and milligram to mg.
final _multiPack = RegExp(
  r'^(\d+)\s*[xX×]\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+(?: [a-zA-Z]+)?)',
);
final _simpleQuantity = RegExp(
  r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+(?: [a-zA-Z]+)?)?',
);

/// Maps known unit strings to normalized forms.
const _unitMap = <String, String>{
  'g': 'g',
  'gram': 'g',
  'grams': 'g',
  'kg': 'kg',
  'kilogram': 'kg',
  'kilograms': 'kg',
  'mg': 'mg',
  'milligram': 'mg',
  'milligrams': 'mg',
  'mcg': 'mcg',
  'microgram': 'mcg',
  'micrograms': 'mcg',
  'µg': 'mcg',
  'ml': 'ml',
  'milliliter': 'ml',
  'milliliters': 'ml',
  'millilitre': 'ml',
  'millilitres': 'ml',
  'cl': 'ml',
  'centiliter': 'ml',
  'centiliters': 'ml',
  'l': 'L',
  'liter': 'L',
  'liters': 'L',
  'litre': 'L',
  'litres': 'L',
  'oz': 'oz',
  'ounce': 'oz',
  'ounces': 'oz',
  'fl oz': 'fl oz',
  'floz': 'fl oz',
  'fluid ounce': 'fl oz',
  'fluid ounces': 'fl oz',
  'lb': 'lb',
  'lbs': 'lb',
  'pound': 'lb',
  'pounds': 'lb',
  'pieces': 'pieces',
  'piece': 'pieces',
  'count': 'pieces',
};

/// Parses a quantity from OFF API fields into a [ParsedQuantity].
///
/// Priority:
/// 1. Uses [productQuantity] and [productQuantityUnit] when both present,
///    but for multi-pack strings like "3 x 150 g" the per-unit value is
///    extracted from the [quantity] string instead of the normalized total.
/// 2. Falls back to parsing the raw [quantity] string.
/// 3. Returns null when nothing is parseable.
ParsedQuantity? parseQuantity({
  double? productQuantity,
  String? productQuantityUnit,
  String? quantity,
}) {
  // If we have a multi-pack pattern, always parse the display string
  // for the per-unit value, regardless of normalized fields.
  if (quantity != null && quantity.isNotEmpty) {
    final parsed = _parseQuantityString(quantity);
    if (parsed != null) return parsed;
  }

  // Fall back to normalized fields.
  if (productQuantity != null && productQuantity > 0) {
    final unit = normalizeUnit(productQuantityUnit);
    if (unit != null) {
      return ParsedQuantity(amount: productQuantity, unit: unit);
    }
  }

  // productQuantityUnit alone (no quantity number) — nothing to do.
  return null;
}

/// Parses a raw OFF quantity string into [ParsedQuantity].
///
/// Handles:
/// - "500 ml" -> amount=500, unit=ml
/// - "3 x 150 g" -> amount=150, unit=g  (per-unit value)
/// - "6 eggs" -> amount=6, unit=pieces
ParsedQuantity? _parseQuantityString(String quantity) {
  final trimmed = quantity.trim();
  if (trimmed.isEmpty) return null;

  // Multi-pack: "N x M unit" -> use M (per-unit).
  final multiMatch = _multiPack.firstMatch(trimmed);
  if (multiMatch != null) {
    final amount = double.tryParse(multiMatch.group(2)!);
    final unit = normalizeUnit(multiMatch.group(3));
    if (amount != null && amount > 0 && unit != null) {
      return ParsedQuantity(amount: amount, unit: unit);
    }
  }

  // Simple pattern: "N unit" or "Nunit".
  final simpleMatch = _simpleQuantity.firstMatch(trimmed);
  if (simpleMatch != null) {
    final amount = double.tryParse(simpleMatch.group(1)!);
    if (amount == null || amount <= 0) return null;

    final rawUnit = simpleMatch.group(2);
    if (rawUnit != null && rawUnit.isNotEmpty) {
      final unit = normalizeUnit(rawUnit);
      if (unit != null) {
        return ParsedQuantity(amount: amount, unit: unit);
      }
      // Unrecognized unit — cannot auto-fill.
      return null;
    }

    // Number only, no unit found.
    return null;
  }

  return null;
}

/// Parses USDA foodPortion data into a [ParsedQuantity].
///
/// Always uses [usdaGramWeight] when present and > 0, returning it with
/// unit "g". This matches the design decision to pre-fill produce
/// items in weight mode with gram weights from the USDA API.
///
/// Returns null when no usable gram weight is available.
ParsedQuantity? parseUsdaQuantity({
  double? usdaServingAmount,
  String? usdaServingUnit,
  double? usdaGramWeight,
}) {
  if (usdaGramWeight != null && usdaGramWeight > 0) {
    return ParsedQuantity(amount: usdaGramWeight, unit: 'g');
  }
  return null;
}

/// Parses a serving size from product data into a [ParsedQuantity].
///
/// Priority:
/// 1. Uses [servingQuantity] as the amount when > 0, and extracts the unit
///    from [servingSize] (e.g. servingQuantity: 30, servingSize: "30g"]
///    returns amount=30, unit="g").
/// 2. Falls back to parsing the [servingSize] string entirely.
/// 3. Returns null when nothing is parseable.
ParsedQuantity? parseServingQuantity({
  double? servingQuantity,
  String? servingSize,
}) {
  if (servingQuantity != null && servingQuantity > 0) {
    if (servingSize != null && servingSize.isNotEmpty) {
      final parsed = _parseQuantityString(servingSize);
      if (parsed != null) {
        return ParsedQuantity(amount: servingQuantity, unit: parsed.unit);
      }
    }
    return null;
  }
  if (servingSize != null && servingSize.isNotEmpty) {
    return _parseQuantityString(servingSize);
  }
  return null;
}

/// Parses a packaging string into the TOTAL package size a price applies
/// to.
///
/// Unlike [parseQuantity], which resolves multi-pack strings to their
/// per-unit value, this resolves "3 x 150 g" to 450 g — the size of the
/// whole package a price observation covers. Bonus-pack strings like
/// "2 x 300 g + 1 x 50 g" are summed when all segments share a unit; mixed
/// units fall back to [productQuantity] with [productQuantityUnit].
///
/// Priority:
/// 1. Parse [quantity] as the total package size.
/// 2. Fall back to [productQuantity] + [productQuantityUnit] when both are
///    usable.
/// 3. Return null when nothing is parseable.
ParsedQuantity? parsePackageQuantity({
  String? quantity,
  double? productQuantity,
  String? productQuantityUnit,
}) {
  final trimmed = quantity?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    final segments = trimmed.split('+').map((s) => s.trim()).toList();
    double? total;
    String? unit;
    for (final segment in segments) {
      final parsed = _parsePackageSegment(segment);
      if (parsed == null) {
        total = null;
        break;
      }
      if (unit != null && unit != parsed.unit) {
        // Mixed units cannot be summed into one package size.
        total = null;
        break;
      }
      unit = parsed.unit;
      total = (total ?? 0) + parsed.amount;
    }
    if (total != null && total > 0 && unit != null) {
      return ParsedQuantity(amount: total, unit: unit);
    }
  }

  if (productQuantity != null && productQuantity > 0) {
    final unit = normalizeUnit(productQuantityUnit);
    if (unit != null) {
      return ParsedQuantity(amount: productQuantity, unit: unit);
    }
  }

  return null;
}

/// Parses one package segment ("N x M unit" or "N unit") into its total
/// amount and normalized unit.
ParsedQuantity? _parsePackageSegment(String segment) {
  final multiMatch = _multiPack.firstMatch(segment);
  if (multiMatch != null) {
    final multiplier = double.tryParse(multiMatch.group(1)!);
    final amount = double.tryParse(multiMatch.group(2)!);
    final unit = normalizeUnit(multiMatch.group(3));
    if (multiplier != null &&
        multiplier > 0 &&
        amount != null &&
        amount > 0 &&
        unit != null) {
      return ParsedQuantity(amount: multiplier * amount, unit: unit);
    }
  }

  final simpleMatch = _simpleQuantity.firstMatch(segment);
  if (simpleMatch != null) {
    final amount = double.tryParse(simpleMatch.group(1)!);
    if (amount == null || amount <= 0) return null;

    final rawUnit = simpleMatch.group(2);
    if (rawUnit != null && rawUnit.isNotEmpty) {
      final unit = normalizeUnit(rawUnit);
      if (unit != null) {
        return ParsedQuantity(amount: amount, unit: unit);
      }
      // Unrecognized unit — cannot resolve the package size.
      return null;
    }

    // Number only, no unit found.
    return null;
  }

  return null;
}

/// Normalizes an OFF unit string to the app's internal representation.
///
/// Returns null for unrecognised or empty units.
String? normalizeUnit(String? unit) {
  if (unit == null || unit.isEmpty) return null;
  final lower = unit.trim().toLowerCase();
  return _unitMap[lower];
}
