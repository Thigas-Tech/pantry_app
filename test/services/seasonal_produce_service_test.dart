import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/services/seasonal_produce_service.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';

void main() {
  group('SeasonalProduceService.getSeasonalProduce', () {
    test('returns non-empty list for northern summer', () {
      final items = SeasonalProduceService.getSeasonalProduce(
        DateTime(2024, 7, 15),
        Hemisphere.northern,
      );
      expect(items, isNotEmpty);
    });

    test('returns non-empty list for northern winter', () {
      final items = SeasonalProduceService.getSeasonalProduce(
        DateTime(2024, 1, 15),
        Hemisphere.northern,
      );
      expect(items, isNotEmpty);
    });

    test('returns non-empty list for southern summer (Dec)', () {
      final items = SeasonalProduceService.getSeasonalProduce(
        DateTime(2024, 12, 15),
        Hemisphere.southern,
      );
      expect(items, isNotEmpty);
    });

    test('excludes specified names case-insensitively', () {
      final items = SeasonalProduceService.getSeasonalProduce(
        DateTime(2024, 7, 15),
        Hemisphere.northern,
        excludeNames: {'TOMATO', 'CORN'},
      );
      expect(
        items.any((i) => i.toLowerCase() == 'tomato'),
        isFalse,
      );
      expect(
        items.any((i) => i.toLowerCase() == 'corn'),
        isFalse,
      );
    });

    test('excludes names case-insensitively even if exclude is lowercase', () {
      final items = SeasonalProduceService.getSeasonalProduce(
        DateTime(2024, 7, 15),
        Hemisphere.northern,
        excludeNames: {'tomato'},
      );
      expect(
        items.any((i) => i.toLowerCase() == 'tomato'),
        isFalse,
      );
    });

    test('all items in seasonal lists exist in ProduceServingPresets', () {
      for (final hemisphere in [Hemisphere.northern, Hemisphere.southern]) {
        for (final date in [
          DateTime(2024, 1, 15),
          DateTime(2024, 4, 15),
          DateTime(2024, 7, 15),
          DateTime(2024, 10, 15),
        ]) {
          final items = SeasonalProduceService.getSeasonalProduce(
            date,
            hemisphere,
          );
          for (final item in items) {
            expect(
              ProduceServingPresets.forName(item),
              isNotNull,
              reason:
                  '$item not in ProduceServingPresets '
                  'for $hemisphere on $date',
            );
          }
        }
      }
    });
  });
}
