import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/csv_service.dart';

/// A mock of [DatabaseHelper] for isolating [CsvService] tests.
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

/// Unit tests for [CsvService] – CSV generation and import.
///
/// Uses a mock [DatabaseHelper] to avoid touching the real file system or
/// database.
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

    test('generates valid CSV with headers and data', () async {
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
      expect(csv, contains('Milk'));
      expect(csv, contains('123'));
      expect(csv, contains('2'));
      expect(csv, contains('fridge'));
      expect(csv, contains('Home'));
      expect(csv, contains('1970-01-02T'));
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
    Future<Map<String, int>> runImport(
      String csvContent, {
      int inventoryId = 1,
    }) async {
      final tempFile = File('${Directory.systemTemp.path}/test_import.csv');
      await tempFile.writeAsString(csvContent);
      try {
        return await csvService.importCsv(
          tempFile.path,
          inventoryId: inventoryId,
        );
      } finally {
        if (tempFile.existsSync()) tempFile.deleteSync();
      }
    }

    test('imports valid CSV and returns counts', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csvContent =
          'Product Name,Brand,Category,Barcode,Quantity,Unit,Expiry Date, '
          'Location,Notes,Date Added,Energy (kcal/100g),Protein (g/100g), '
          'Carbs (g/100g),Fat (g/100g),Fiber (g/100g),Salt (g/100g), '
          'Inventory Name\n'
          'Milk,Dairy,,123,2,L,2026-01-01,fridge,,'
          '2026-01-01T00:00:00.000,42,3.4,5.0,1.0,0.0,0.1,Home\n';

      final counts = await runImport(csvContent, inventoryId: 2);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
      verify(() => mockDb.insertProduct(any())).called(1);
      verify(() => mockDb.insertInventoryItem(any())).called(1);
    });

    test('throws if required columns are missing', () {
      const csvContent = 'Bad,Headers\nvalue1,value2\n';
      expect(
        () => runImport(csvContent),
        throwsA(isA<Exception>()),
      );
    });

    test('throws if file is empty', () {
      const csvContent = '';
      expect(
        () => runImport(csvContent),
        throwsA(isA<Exception>()),
      );
    });

    test('handles quoted fields with commas', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      const csvContent =
          'Product Name,Brand,Category,Barcode,Quantity,Unit,Expiry Date, '
          'Location,Notes,Date Added,Energy (kcal/100g),Protein (g/100g), '
          'Carbs (g/100g),Fat (g/100g),Fiber (g/100g),Salt (g/100g), '
          'Inventory Name\n'
          '"Milk, Whole",Dairy,,123,1,L,2026-01-01,fridge,,, '
          '42,3.4,5.0,1.0,0.0,0.1,Home\n';

      final counts = await runImport(csvContent);
      expect(counts['products'], 1);
      expect(counts['items'], 1);
    });
    test('throws exception when file does not exist', () {
      final csvService = CsvService(mockDb);
      expect(
        () => csvService.importCsv('/non_existent_path.csv', inventoryId: 1),
        throwsA(isA<Exception>()),
      );
    });
  });
}
