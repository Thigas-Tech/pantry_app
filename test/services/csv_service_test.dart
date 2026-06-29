/// Tests for [CsvService] – CSV generation and import.
///
/// Uses a mock [DatabaseHelper] to avoid touching the real file system
/// or database during tests.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/csv_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class FakeProduct extends Fake implements Product {}

class FakeInventoryItem extends Fake implements InventoryItem {}

void main() {
  late MockDatabaseHelper mockDb;
  late CsvService csvService;

  setUpAll(() {
    registerFallbackValue(FakeProduct());
    registerFallbackValue(FakeInventoryItem());
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    csvService = CsvService(mockDb);
  });

  group('generateCsv', () {
    test('returns empty string when no data', () async {
      /// An empty inventory produces an empty CSV string.
      when(() => mockDb.getExportData()).thenAnswer((_) async => []);
      final result = await csvService.generateCsv();
      expect(result, '');
    });

    test('generates valid CSV with data', () async {
      /// A single inventory row produces a CSV with a header row and
      /// the correct values.
      final rows = [
        {
          'product_name': 'Milk',
          'brand': 'Dairy',
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
        },
      ];
      when(() => mockDb.getExportData()).thenAnswer((_) async => rows);

      final csv = await csvService.generateCsv();
      expect(csv, isNotEmpty);
      expect(csv, contains('Product Name'));
      expect(csv, contains('Milk'));
      expect(csv, contains('123'));
      expect(csv, contains('2'));
      expect(csv, contains('fridge'));
      expect(csv, contains('1970-01-02T')); // ms timestamp → ISO
    });
  });

  group('importCsv', () {
    setUp(() {
      when(() => mockDb.insertProduct(any())).thenAnswer((_) async => {});
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);
    });

    test('imports valid CSV file and returns counts', () async {
      /// A correctly formatted CSV file is parsed and the database
      /// insert methods are called once per row.
      const csvContent =
          'Product Name,Brand,Category,Barcode,Quantity,Unit,Expiry Date,Location,Notes,Date Added,Energy (kcal/100g),Protein (g/100g),Carbs (g/100g),Fat (g/100g),Fiber (g/100g),Salt (g/100g)\n'
          // ignore: lines_longer_than_80_chars
          'Milk,Dairy,,123,2,L,2026-01-01,fridge,,2026-01-01T00:00:00.000,42,3.4,5.0,1.0,0.0,0.1\n';
      final tempFile = File('${Directory.systemTemp.path}/test_import.csv');
      await tempFile.writeAsString(csvContent);

      try {
        final counts = await csvService.importCsv(tempFile.path);
        expect(counts['products'], 1);
        expect(counts['items'], 1);
        verify(() => mockDb.insertProduct(any())).called(1);
        verify(() => mockDb.insertInventoryItem(any())).called(1);
      } finally {
        if (tempFile.existsSync()) tempFile.deleteSync();
      }
    });

    test('throws if required columns missing', () async {
      /// Importing a CSV without 'Barcode' or 'Product Name' columns
      /// throws an exception.
      const csvContent = 'Bad,Headers\nvalue1,value2\n';
      final tempFile = File('${Directory.systemTemp.path}/test_bad.csv');
      await tempFile.writeAsString(csvContent);

      try {
        expect(
          () => csvService.importCsv(tempFile.path),
          throwsA(isA<Exception>()),
        );
      } finally {
        if (tempFile.existsSync()) tempFile.deleteSync();
      }
    });
  });
}
