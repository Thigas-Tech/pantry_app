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
    required int totalProducts,
    required int totalItems,
    required double averageNutriscoreNumeric,
    required int expiredCount,
    required int expiringSoonCount,
    required int goodCount,
    required int addedThisWeek,
    required int addedThisMonth,
    required List<WeeklyCount> weeklyAdditions,
    required Map<String, int> itemsByLocation,
    required List<CategoryCount> categoriesTop,
    required Map<String, int> nutriscoreDistribution,
    required Map<String, int> itemsBySource,
    required PhotoStats localPhotos,
    required PhotoStats offPhotos,
    @Default(0) double totalValue,
    @Default(0) double averagePrice,
    @Default(0) int pricedItemCount,
  }) = _PantryStats;
}

/// A single week's item-addition count.
@freezed
abstract class WeeklyCount with _$WeeklyCount {
  /// Creates a [WeeklyCount].
  const factory WeeklyCount({
    required String weekLabel,
    required int count,
  }) = _WeeklyCount;
}

/// A category name and its product count (top N list).
@freezed
abstract class CategoryCount with _$CategoryCount {
  /// Creates a [CategoryCount].
  const factory CategoryCount({
    required String category,
    required int count,
  }) = _CategoryCount;
}

/// Counts of products with photos attached, local or from OFF.
@freezed
abstract class PhotoStats with _$PhotoStats {
  /// Creates a [PhotoStats].
  const factory PhotoStats({
    required int total,
    required int withNutrition,
    required int withIngredients,
    required int withProduct,
  }) = _PhotoStats;
}
