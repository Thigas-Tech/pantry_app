import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/quantity_parser.dart';

/// Parses a [Product]'s packaging size for pre-filling a price sheet, or
/// null when no size can be derived.
///
/// Reuses [parseQuantity] (which prioritizes the per-unit value of multi-pack
/// strings like "3 x 150 g") so the product detail screen and the market trip
/// offer the same package size. When the product has no packaging data (many
/// Open Food Facts products only carry a serving size), it falls back to
/// [parseServingQuantity] so a unit price can still be computed; the package
/// size always wins over the serving size when both are present.
({double quantity, String unit})? productPackageSize(Product product) {
  final parsed = parseQuantity(
    productQuantity: product.productQuantity,
    quantity: product.quantity,
  );
  if (parsed != null) {
    return (quantity: parsed.amount, unit: parsed.unit);
  }
  final serving = parseServingQuantity(
    servingQuantity: product.servingQuantity,
    servingSize: product.servingSize,
  );
  if (serving == null) return null;
  return (quantity: serving.amount, unit: serving.unit);
}
