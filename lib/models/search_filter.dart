/// Which data source to search.
///
/// Controls where the search queries for results.
enum SearchSource {
  /// Open Food Facts API plus the local cache.
  off,

  /// USDA FoodData Central API.
  usda,

  /// Current active inventory items only.
  inventory,
}
