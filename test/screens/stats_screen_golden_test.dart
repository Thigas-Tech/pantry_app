import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/stats_provider.dart';
import 'package:pantry_app/screens/stats_screen.dart';

import '../helpers/pump_app.dart';

PantryStats _populatedStats() => const PantryStats(
  totalProducts: 5,
  totalItems: 12,
  averageNutriscoreNumeric: 3,
  expiredCount: 2,
  expiringSoonCount: 3,
  goodCount: 7,
  addedThisWeek: 4,
  addedThisMonth: 8,
  weeklyAdditions: [
    WeeklyCount(weekLabel: 'W26', count: 2),
    WeeklyCount(weekLabel: 'W27', count: 2),
  ],
  itemsByLocation: {'pantry': 8, 'fridge': 4},
  categoriesTop: [
    CategoryCount(category: 'Dairy', count: 4),
    CategoryCount(category: 'Grains', count: 3),
  ],
  nutriscoreDistribution: {'a': 1, 'b': 2, 'c': 2},
  itemsBySource: {'api': 4, 'manual': 1},
  localPhotos: PhotoStats(
    total: 5,
    withNutrition: 2,
    withIngredients: 1,
    withProduct: 3,
  ),
  offPhotos: PhotoStats(
    total: 3,
    withNutrition: 1,
    withIngredients: 1,
    withProduct: 2,
  ),
);

void main() {
  testWidgets('StatsScreen at 360dp populated state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: [
        statsProvider.overrideWith((ref) => _populatedStats()),
      ],
    );

    await expectLater(
      find.byType(StatsScreen),
      matchesGoldenFile('goldens/stats_screen_360dp.png'),
    );
  });
}
