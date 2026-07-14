/// Identifies how a product was sourced or classified.
///
/// - [barcoded] — scanned via barcode from a packaged product.
/// - [produce] — identified by PLU code as fresh produce (no barcode).
/// - [custom] — created manually by the user.
enum ProductType {
  /// A product with a manufacturer barcode (EAN-13, UPC, etc.).
  barcoded,

  /// A fresh produce item identified by PLU (Price Look-Up) code.
  produce,

  /// A manually entered product not found in any database.
  custom,
}
