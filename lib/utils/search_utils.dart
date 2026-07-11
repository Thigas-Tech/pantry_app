import 'package:diacritic/diacritic.dart';
import 'package:pantry_app/models/product.dart';

/// Normalises [input] for search purposes.
///
/// Steps:
/// 1. Remove diacritics using the `diacritic` package.
/// 2. Trim and collapse whitespace.
/// 3. Lower-case the result.
String normalizeForSearch(String input) {
  if (input.isEmpty) return input;
  return removeDiacritics(
    input,
  ).trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Builds the normalized search text for a given [product].
///
/// Concatenates the most searchable fields, then applies
/// [normalizeForSearch] so that the column matches the same
/// normalization applied to user queries.
String buildSearchText(Product product) {
  final raw = [
    product.name,
    if (product.brand != null && product.brand!.isNotEmpty) product.brand!,
    product.barcode,
    if (product.category != null && product.category!.isNotEmpty)
      product.category!,
  ].join(' ');
  return normalizeForSearch(raw);
}
