import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/csv_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;
  late CsvService csvService;

  setUp(() {
    mockDb = MockDatabaseHelper();
    csvService = CsvService(mockDb);

    registerFallbackValue(const Product(barcode: '', name: ''));
    registerFallbackValue(const InventoryItem(barcode: ''));
  });

  group('generateCsv', () {
    test('returns empty string when no data', () async {
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => []);
      final result = await csvService.generateCsv(inventoryId: 1);
      expect(result, '');
    });

    test('generates CSV with headers and all columns', () async {
      final rows = [
        {
          'product_name': 'Milk',
          'brand': 'Dairy Inc',
          'category': 'Dairy',
          'barcode': '123',
          'quantity': 2,
          'unit': 'L',
          'expiry_date': '2026-01-01',
          'location': 'fridge',
          'notes': 'organic',
          'date_added': 123456789,
          'serving_size': '200 ml',
          'nutriscore_grade': 'b',
          'energy_kcal': 42,
          'protein_g': 3.4,
          'carbs_g': 5.0,
          'fat_g': 1.0,
          'fiber_g': 0.0,
          'salt_g': 0.1,
          'inventory_name': 'Home',
        },
      ];
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final csv = await csvService.generateCsv(inventoryId: 1);
      expect(csv, isNotEmpty);
      expect(csv, contains('Product Name'));
      expect(csv, contains('Serving Size'));
      expect(csv, contains('Nutri-Score'));
      expect(csv, contains('Milk'));
      expect(csv, contains('b'));
      expect(csv, contains('200 ml'));
    });

    test('null fields export as empty strings, not "null"', () async {
      final rows = [
        {
          'product_name': 'Test',
          'brand': null,
          'category': null,
          'barcode': '999',
          'quantity': 1,
          'unit': 'pieces',
          'expiry_date': null,
          'location': 'pantry',
          'notes': null,
          'date_added': null,
          'serving_size': null,
          'nutriscore_grade': null,
          'energy_kcal': null,
          'protein_g': null,
          'carbs_g': null,
          'fat_g': null,
          'fiber_g': null,
          'salt_g': null,
          'inventory_name': 'Home',
        },
      ];
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final csv = await csvService.generateCsv(inventoryId: 1);
      expect(csv, isNot(contains('null')));
    });

    test('escapes fields containing commas', () async {
      final rows = [
        {
          'product_name': 'Milk',
          'brand': 'Dairy, Inc.',
          'category': 'Dairy',
          'barcode': '123',
          'quantity': 1,
          'unit': 'L',
          'expiry_date': '2026-01-01',
          'location': 'fridge',
          'notes': null,
          'date_added': null,
          'serving_size': null,
          'nutriscore_grade': null,
          'energy_kcal': null,
          'protein_g': null,
          'carbs_g': null,
          'fat_g': null,
          'fiber_g': null,
          'salt_g': null,
          'inventory_name': 'Home',
        },
      ];
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final csv = await csvService.generateCsv(inventoryId: 1);
      expect(csv, contains('"Dairy, Inc."'));
    });
  });

  group('importCsv', () {
    test('imports valid CSV and returns counts', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv =
          'Product Name,Brand,Category,Barcode,Quantity,Unit,Expiry Date,Location,Notes,Date Added,Serving Size,Nutri-Score,Energy (kcal/100g),Protein (g/100g),Carbs (g/100g),Fat (g/100g),Fiber (g/100g),Salt (g/100g),Inventory Name'
          '\nMilk,Dairy,,123,2,L,2026-01-01,fridge,,,,,42,3.4,5,1,,0.1,Home\n';

      final counts = await csvService.importCsv(csv, inventoryId: 2);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
      verify(() => mockDb.insertProduct(any())).called(1);
      verify(() => mockDb.insertInventoryItem(any())).called(1);
    });

    test('throws if required columns are missing', () {
      const csv = 'Bad,Headers\nvalue1,value2\n';
      expect(
        () => csvService.importCsv(csv, inventoryId: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('throws if content is empty', () {
      expect(
        () => csvService.importCsv('', inventoryId: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('handles quoted fields with commas', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv =
          'Product Name,Brand,Category,Barcode,Quantity,Unit,Expiry Date,'
          'Location,Notes,Date Added,Serving Size,Nutri-Score,'
          'Energy (kcal/100g),Protein (g/100g),Carbs (g/100g),'
          'Fat (g/100g),Fiber (g/100g),Salt (g/100g),Inventory Name'
          '\n"Milk, Whole",Dairy,,123,1,L,2026-01-01,fridge,,,,'
          '42,3.4,5,1,,0.1,Home\n';

      final counts = await csvService.importCsv(csv, inventoryId: 1);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });

    test('skips rows with empty barcode', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv = 'Product Name,Category,Barcode\nTest,Dairy,\n';

      final counts = await csvService.importCsv(csv, inventoryId: 1);
      expect(counts['products'], 0);
      expect(counts['items'], 0);
    });

    test('handles CRLF line endings', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv = 'Product Name,Barcode\r\nMilk,123\r\n';

      final counts = await csvService.importCsv(csv, inventoryId: 1);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });

    test('handles UTF-8 BOM prefix', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csvWithBom = '\uFEFFProduct Name,Barcode\nMilk,123\n';

      final counts = await csvService.importCsv(
        csvWithBom,
        inventoryId: 1,
      );
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });

    test('handles escaped double quotes in fields', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv =
          'Product Name,Brand,Barcode\n'
          '"Chips ""Extra Crunchy""",Lays,456\n';

      final counts = await csvService.importCsv(csv, inventoryId: 1);
      expect(counts['products'], 1);
    });

    test('round-trip: export then import preserves data', () async {
      final rows = [
        {
          'product_name': 'Milk',
          'brand': 'Dairy',
          'category': 'Beverages',
          'barcode': '789',
          'quantity': 2,
          'unit': 'L',
          'expiry_date': '2026-06-15',
          'location': 'fridge',
          'notes': 'organic',
          'date_added': 1700000000000,
          'serving_size': '200 ml',
          'nutriscore_grade': 'b',
          'energy_kcal': 42.0,
          'protein_g': 3.4,
          'carbs_g': 5.0,
          'fat_g': 1.0,
          'fiber_g': null,
          'salt_g': 0.1,
          'inventory_name': 'Home',
        },
      ];
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      final exported = await csvService.generateCsv(inventoryId: 1);
      final counts = await csvService.importCsv(exported, inventoryId: 1);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });

    test('importCsvFromBytes works with raw bytes', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csv = 'Product Name,Barcode\nMilk,123\n';
      final bytes = csv.codeUnits;

      final counts = await csvService.importCsvFromBytes(
        bytes,
        inventoryId: 1,
      );
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });
  });

  group('readFromPath', () {
    test('reads file content', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_read.csv');
      await tempFile.writeAsString('Product Name,Barcode\nMilk,123\n');
      try {
        final content = await CsvService.readFromPath(tempFile.path);
        expect(content, contains('Milk'));
      } finally {
        if (tempFile.existsSync()) tempFile.deleteSync();
      }
    });

    test('throws for non-existent path without filegate', () {
      expect(
        () => CsvService.readFromPath('/nonexistent/path.csv'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
