import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';
import 'package:pantry_app/services/carousel_composition_service.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CarouselCompositionService', () {
    late DatabaseHelper dbHelper;
    late ProducePurchaseTracker tracker;
    late CarouselCompositionService service;

    setUp(() async {
      dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
      await dbHelper.database;
      tracker = ProducePurchaseTracker(dbHelper: dbHelper);
      service = CarouselCompositionService(purchaseTracker: tracker);
    });

    tearDown(() async {
      final db = await dbHelper.database;
      await db.close();
    });

    test('returns top 3 personalized items first', () async {
      await tracker.recordPurchase('apple');
      await tracker.recordPurchase('apple');
      await tracker.recordPurchase('banana');
      await tracker.recordPurchase('banana');
      await tracker.recordPurchase('carrot');

      final items = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );

      final personalized = items
          .takeWhile((i) => i.source == ProduceItemSource.personalized)
          .toList();
      expect(personalized.length, greaterThanOrEqualTo(1));
      expect(personalized.first.name, 'apple');
    });

    test('seasonal items follow personalized items', () async {
      final items = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );

      final lastPersonalized = items.lastIndexWhere(
        (i) => i.source == ProduceItemSource.personalized,
      );
      final firstSeasonal = items.indexWhere(
        (i) => i.source == ProduceItemSource.seasonal,
      );

      if (lastPersonalized >= 0 && firstSeasonal >= 0) {
        expect(lastPersonalized, lessThan(firstSeasonal));
      }
    });

    test('no duplicates between personalized and seasonal', () async {
      await tracker.recordPurchase('tomato');
      await tracker.recordPurchase('tomato');
      await tracker.recordPurchase('tomato');

      final items = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );

      final personalizedNames = items
          .where((i) => i.source == ProduceItemSource.personalized)
          .map((i) => i.name)
          .toSet();
      final seasonalNames = items
          .where((i) => i.source == ProduceItemSource.seasonal)
          .map((i) => i.name)
          .toSet();

      for (final name in personalizedNames) {
        expect(seasonalNames, isNot(contains(name)));
      }
    });

    test('empty history returns only seasonal items', () async {
      final items = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );

      final personalized = items
          .where((i) => i.source == ProduceItemSource.personalized)
          .toList();
      expect(personalized, isEmpty);

      final seasonal = items
          .where((i) => i.source == ProduceItemSource.seasonal)
          .toList();
      expect(seasonal, isNotEmpty);
    });

    test('hemisphere affects seasonal selection', () async {
      final northernSummer = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );
      final southernWinter = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.southern,
      );

      final nsSeasonal = northernSummer
          .where((i) => i.source == ProduceItemSource.seasonal)
          .map((i) => i.name)
          .toSet();
      final swSeasonal = southernWinter
          .where((i) => i.source == ProduceItemSource.seasonal)
          .map((i) => i.name)
          .toSet();

      // Jul northern summer != Jul southern winter
      expect(nsSeasonal, isNot(equals(swSeasonal)));
      // Both should have items
      expect(nsSeasonal, isNotEmpty);
      expect(swSeasonal, isNotEmpty);
    });

    test('personalized items capped at 3', () async {
      await tracker.recordPurchase('apple');
      await tracker.recordPurchase('banana');
      await tracker.recordPurchase('carrot');
      await tracker.recordPurchase('onion');
      await tracker.recordPurchase('potato');

      final items = await service.buildCarousel(
        date: DateTime(2024, 7, 15),
        hemisphere: Hemisphere.northern,
      );

      final personalized = items
          .where((i) => i.source == ProduceItemSource.personalized)
          .toList();
      expect(personalized.length, lessThanOrEqualTo(3));
    });
  });
}
