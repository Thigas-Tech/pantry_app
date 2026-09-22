import 'package:freezed_annotation/freezed_annotation.dart';

part 'pantry_stats.freezed.dart';

/// Aggregated statistics for a single pantry inventory.
///
/// Computed from SQL aggregation queries in the product and inventory DAOs.
/// All counts and distributions
/// are scoped to the active inventory.
@freezed
abstract class PantryStats with _$PantryStats {
  /// Creates a [PantryStats].
  const factory PantryStats({
    /// Number of products cached in the local database.
    required int totalProducts,

    /// Number of inventory items in the active pantry.
    required int totalItems,

    /// Average numeric Nutri-Score of cached products
    /// (5 = A, 4 = B, ... 1 = E).
    required double averageNutriscoreNumeric,

    /// Items already past their expiry date in the active pantry.
    required int expiredCount,

    /// Items expiring within the configured expiring-soon window in the
    /// active pantry.
    required int expiringSoonCount,

    /// Items with a healthy expiry date in the active pantry.
    required int goodCount,

    /// Sum of counts in [weeklyAdditions] for the active pantry.
    required int addedThisWeek,

    /// Total items added within the recent weekly-addition window
    /// (same value as [addedThisWeek]).
    required int addedThisMonth,

    /// Weekly addition counts for the active pantry, newest week first
    /// (up to eight weeks).
    required List<WeeklyCount> weeklyAdditions,

    /// Count of items per storage location (pantry, fridge, freezer,
    /// custom) in the active pantry.
    required Map<String, int> itemsByLocation,

    /// Top product categories by item count, parent-level names localized
    /// to the user's language.
    required List<CategoryCount> categoriesTop,

    /// Count of cached products per Nutri-Score grade.
    required Map<String, int> nutriscoreDistribution,

    /// Count of cached products per source (API-fetched vs manual).
    required Map<String, int> itemsBySource,

    /// Photo-completeness counts for locally captured product photos.
    required PhotoStats localPhotos,

    /// Photo-completeness counts for OFF product photos.
    required PhotoStats offPhotos,

    /// Total estimated value of priced items in the active pantry, in the
    /// base currency.
    @Default(0) double totalValue,

    /// Average price of priced items in the active pantry, in the base
    /// currency.
    @Default(0) double averagePrice,

    /// Number of items with at least one recorded price in the active
    /// pantry.
    @Default(0) int pricedItemCount,

    /// Monthly expenditure in the base currency for the active pantry,
    /// recent months first.
    @Default([]) List<MonthlySpending> monthlySpending,

    /// Spending and item counts grouped by store for the active pantry.
    @Default([]) List<StoreSpending> storeSpending,

    /// Average Nutri-Score per store for the active pantry.
    @Default([]) List<StoreNutriscore> nutriscoreByStore,

    /// Number of recipes cooked in the last 30 days.
    @Default(0) int mealsCooked,

    /// Total cost of recipes cooked in the last 30 days, in the base
    /// currency.
    @Default(0) double totalRecipeCost,

    /// Average numeric Nutri-Score across saved recipes; not yet populated
    /// by the stats aggregation.
    @Default(0) double averageRecipeNutriScore,

    /// Name of the most-cooked recipe, or empty when none has been cooked.
    @Default('') String mostCookedRecipe,
  }) = _PantryStats;
}

/// A single week's item-addition count.
@freezed
abstract class WeeklyCount with _$WeeklyCount {
  /// Creates a [WeeklyCount].
  const factory WeeklyCount({
    /// ISO year-week label (strftime %Y-%W format).
    required String weekLabel,

    /// Number of items added in that week.
    required int count,
  }) = _WeeklyCount;
}

/// A category name and its product count (top N list).
@freezed
abstract class CategoryCount with _$CategoryCount {
  /// Creates a [CategoryCount].
  const factory CategoryCount({
    /// Parent-level category name, localized to the user's language.
    required String category,

    /// Number of items in that category.
    required int count,
  }) = _CategoryCount;
}

/// Counts of products with photos attached, local or from OFF.
@freezed
abstract class PhotoStats with _$PhotoStats {
  /// Creates a [PhotoStats].
  const factory PhotoStats({
    /// Total cached products counted.
    required int total,

    /// Products with a nutrition photo attached.
    required int withNutrition,

    /// Products with an ingredients photo attached.
    required int withIngredients,

    /// Products with a product photo attached.
    required int withProduct,
  }) = _PhotoStats;
}

/// Monthly expenditure for the pricing section of the stats screen.
@freezed
abstract class MonthlySpending with _$MonthlySpending {
  /// Creates a [MonthlySpending].
  const factory MonthlySpending({
    /// ISO year-month label, e.g. "2026-07".
    required String month,

    /// Total spending in base currency for this month.
    required double total,
  }) = _MonthlySpending;
}

/// Total spending and item count grouped by store.
@freezed
abstract class StoreSpending with _$StoreSpending {
  /// Creates a [StoreSpending].
  const factory StoreSpending({
    /// Store name.
    required String store,

    /// Total spending at this store in base currency.
    required double total,

    /// Number of priced items purchased at this store.
    required int itemCount,
  }) = _StoreSpending;
}

/// Average Nutri-Score per store.
@freezed
abstract class StoreNutriscore with _$StoreNutriscore {
  /// Creates a [StoreNutriscore].
  const factory StoreNutriscore({
    /// Store name.
    required String store,

    /// Average numeric Nutri-Score (5 = A, 4 = B, ... 1 = E).
    required double averageScore,
  }) = _StoreNutriscore;
}
