// Canonical produce barcode format helpers.
//
// Produce items use a synthetic barcode prefixed with `produce-` followed by
// a normalized version of the produce name. Normalization ensures consistent
// matching between recipe ingredients and inventory rows regardless of how
// the name was entered (casing, whitespace, etc.).

/// Returns the canonical produce barcode for [produceName].
///
/// The name part is normalized via [normalizeProduceName] so that every entry
/// point generates the same barcode for the same produce.
///
/// Example: `produceBarcode('Apple')` -> `'produce-apple'`
String produceBarcode(String produceName) =>
    'produce-${normalizeProduceName(produceName)}';

/// Normalizes a produce name for barcode generation.
///
/// Steps:
/// 1. Trim leading/trailing whitespace.
/// 2. Lowercase.
/// 3. Collapse internal whitespace to a single underscore.
///
/// Example: `normalizeProduceName('  Organic Banana  ')` -> `'organic_banana'`
String normalizeProduceName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

/// Returns the canonical form of a produce barcode if [barcode] starts with
/// `produce-`, or the original [barcode] unchanged otherwise.
///
/// This is used to normalize existing synthetic barcodes before lookup so that
/// `produce-Apple`, `produce-apple`, and `produce-  Apple  ` all resolve to
/// the same canonical key `produce-apple`.
///
/// Example: `normalizeProduceBarcode('produce-Organic Banana')`
///   -> `'produce-organic_banana'`
String normalizeProduceBarcode(String barcode) {
  const prefix = 'produce-';
  if (!barcode.startsWith(prefix)) return barcode;
  final name = barcode.substring(prefix.length);
  return produceBarcode(name);
}
