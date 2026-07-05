import 'dart:io';
import 'dart:math';

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

    test('round-trip with 10 real OFF products preserves all data', () async {
      when(
        () => mockDb.insertProduct(any()),
      ).thenAnswer((_) => Future.value());
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      final rows = _buildProductFixtureRows();
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final exported = await csvService.generateCsv(inventoryId: 1);

      // All 10 product names should appear in the exported CSV.
      const names = [
        'Nutella',
        'isabelle',
        "Alvalle Gazpacho l'original",
        'Pain de mie Bio grandes tranches',
        'Goldium crémeux',
        'Excellence 85% cacao',
        'Jben',
        'Fromage Blanc Nature',
        'Mateus Rosé Original',
        'Vin',
      ];
      for (final name in names) {
        expect(exported, contains(name));
      }

      final counts = await csvService.importCsv(exported, inventoryId: 1);
      expect(counts['products'], 10);
      expect(counts['items'], 10);
      verify(() => mockDb.insertProduct(any())).called(10);
      verify(() => mockDb.insertInventoryItem(any())).called(10);
    });

    test('imported products have correct Nutri-Score grades', () async {
      final products = <Product>[];
      when(
        () => mockDb.insertProduct(captureAny(that: isA<Product>())),
      ).thenAnswer((invocation) {
        products.add(invocation.positionalArguments.first as Product);
        return Future.value();
      });
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      final rows = _buildProductFixtureRows();
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final exported = await csvService.generateCsv(inventoryId: 1);
      await csvService.importCsv(exported, inventoryId: 1);

      final byBarcode = {for (final p in products) p.barcode: p};

      expect(byBarcode['3017620422003']!.nutriscoreGrade, 'e'); // Nutella
      expect(byBarcode['3274080005003']!.nutriscoreGrade, 'a'); // Cristaline
      expect(byBarcode['3168930163480']!.nutriscoreGrade, 'b'); // Gazpacho
      expect(byBarcode['3760049794298']!.nutriscoreGrade, 'c'); // Bread
      expect(byBarcode['6111259092495']!.nutriscoreGrade, 'd'); // Goldium
      expect(byBarcode['3046920022606']!.nutriscoreGrade, 'e'); // Lindt 85%
      expect(byBarcode['6111242106949']!.nutriscoreGrade, 'd'); // Jben
      expect(byBarcode['6111246721261']!.nutriscoreGrade, 'c'); // Milky
      // Wines have not-applicable preserved.
      expect(byBarcode['5601012011500']!.nutriscoreGrade, 'not-applicable');
      expect(byBarcode['4304493261570']!.nutriscoreGrade, 'not-applicable');
    });

    test('imported products have correct nutrition values', () async {
      final products = <Product>[];
      when(
        () => mockDb.insertProduct(captureAny(that: isA<Product>())),
      ).thenAnswer((invocation) {
        products.add(invocation.positionalArguments.first as Product);
        return Future.value();
      });
      when(() => mockDb.insertInventoryItem(any())).thenAnswer((_) async => 1);

      final rows = _buildProductFixtureRows();
      when(
        () => mockDb.getExportData(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      final exported = await csvService.generateCsv(inventoryId: 1);
      await csvService.importCsv(exported, inventoryId: 1);

      final byBarcode = {for (final p in products) p.barcode: p};

      // Nutella: E, 539 kcal, 57.5g carbs, 6.3g protein.
      expect(byBarcode['3017620422003']!.energyKcal, 539);
      expect(byBarcode['3017620422003']!.carbsG, 57.5);
      expect(byBarcode['3017620422003']!.proteinG, 6.3);

      // Lindt: E, 584 kcal, 12.5g protein, 46g fat.
      expect(byBarcode['3046920022606']!.proteinG, 12.5);
      expect(byBarcode['3046920022606']!.fatG, 46);

      // Cristaline: A, null nutrition.
      expect(byBarcode['3274080005003']!.energyKcal, null);
      expect(byBarcode['3274080005003']!.proteinG, null);

      // Gazpacho: B, 40 kcal, 200ml serving.
      expect(byBarcode['3168930163480']!.energyKcal, 40);
      expect(byBarcode['3168930163480']!.servingSize, '200 ml');

      // Bread: C, 5.1g fiber, 35.7g serving.
      expect(byBarcode['3760049794298']!.fiberG, 5.1);
      expect(byBarcode['3760049794298']!.servingSize, '35.7 g');

      // Goldium: D, 24g fat.
      expect(byBarcode['6111259092495']!.fatG, 24);
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

/// Builds 10 export rows from real Open Food Facts products with
/// randomised expiry dates, quantities, units, and locations.
List<Map<String, dynamic>> _buildProductFixtureRows() {
  final rng = Random(42); // deterministic
  final now = DateTime.now();
  const threeMonths = 90;

  final products = <Map<String, dynamic>>[
    {
      'product_name': 'Nutella',
      'brand': 'Nutella, Ferrero',
      'category': 'Confectionary based spreads',
      'barcode': '3017620422003',
      'serving_size': null,
      'nutriscore_grade': 'e',
      'energy_kcal': 539,
      'protein_g': 6.3,
      'carbs_g': 57.5,
      'fat_g': 30.9,
      'fiber_g': null,
      'salt_g': 0.107,
    },
    {
      'product_name': 'isabelle',
      'brand': 'Cristaline',
      'category': 'Eaux de sources',
      'barcode': '3274080005003',
      'serving_size': '1l',
      'nutriscore_grade': 'a',
      'energy_kcal': null,
      'protein_g': null,
      'carbs_g': null,
      'fat_g': null,
      'fiber_g': null,
      'salt_g': 0.00275,
    },
    {
      'product_name': "Alvalle Gazpacho l'original",
      'brand': 'Alvalle',
      'category': 'Gaspacho',
      'barcode': '3168930163480',
      'serving_size': '200 ml',
      'nutriscore_grade': 'b',
      'energy_kcal': 40,
      'protein_g': 0.9,
      'carbs_g': 3.5,
      'fat_g': 2.2,
      'fiber_g': 1.2,
      'salt_g': 0.61,
    },
    {
      'product_name': 'Pain de mie Bio grandes tranches',
      'brand': 'La Boulangère Bio',
      'category': 'Pains de mie aux céréales',
      'barcode': '3760049794298',
      'serving_size': '35.7 g',
      'nutriscore_grade': 'c',
      'energy_kcal': 303,
      'protein_g': 8.6,
      'carbs_g': 46,
      'fat_g': 8.3,
      'fiber_g': 5.1,
      'salt_g': 1.1,
    },
    {
      'product_name': 'Goldium crémeux',
      'brand': null,
      'category': 'Desserts lactés fermentés',
      'barcode': '6111259092495',
      'serving_size': null,
      'nutriscore_grade': 'd',
      'energy_kcal': 225,
      'protein_g': 5,
      'carbs_g': 3,
      'fat_g': 24,
      'fiber_g': 0.1,
      'salt_g': 0.32,
    },
    {
      'product_name': 'Excellence 85% cacao',
      'brand': 'Lindt',
      'category': 'Chocolats noirs en tablette',
      'barcode': '3046920022606',
      'serving_size': '100 g',
      'nutriscore_grade': 'e',
      'energy_kcal': 584,
      'protein_g': 12.5,
      'carbs_g': 22,
      'fat_g': 46,
      'fiber_g': 0,
      'salt_g': 0.02,
    },
    {
      'product_name': 'Jben',
      'brand': 'Jaouda',
      'category': 'Fromages à tartiner',
      'barcode': '6111242106949',
      'serving_size': '160g',
      'nutriscore_grade': 'd',
      'energy_kcal': 235,
      'protein_g': 8,
      'carbs_g': 3.5,
      'fat_g': 21,
      'fiber_g': 0,
      'salt_g': 0.46,
    },
    {
      'product_name': 'Fromage Blanc Nature',
      'brand': 'Milky Food Professional',
      'category': 'Fromages blancs natures',
      'barcode': '6111246721261',
      'serving_size': '100 g',
      'nutriscore_grade': 'c',
      'energy_kcal': 159,
      'protein_g': 5,
      'carbs_g': 10,
      'fat_g': 11,
      'fiber_g': 0,
      'salt_g': 0.1,
    },
    {
      'product_name': 'Mateus Rosé Original',
      'brand': 'Mateus',
      'category': 'Portugese wijnen',
      'barcode': '5601012011500',
      'serving_size': null,
      'nutriscore_grade': 'not-applicable',
      'energy_kcal': null,
      'protein_g': null,
      'carbs_g': null,
      'fat_g': null,
      'fiber_g': null,
      'salt_g': null,
    },
    {
      'product_name': 'Vin',
      'brand': 'Cimarosa',
      'category': 'White wines',
      'barcode': '4304493261570',
      'serving_size': null,
      'nutriscore_grade': 'not-applicable',
      'energy_kcal': null,
      'protein_g': null,
      'carbs_g': null,
      'fat_g': null,
      'fiber_g': null,
      'salt_g': 0,
    },
  ];

  const units = ['pieces', 'g', 'kg', 'ml', 'L'];
  const locations = ['pantry', 'fridge', 'freezer'];

  return products.map((p) {
    final days = rng.nextInt(threeMonths);
    final date = now.add(Duration(days: days));
    return {
      ...p,
      'quantity': rng.nextInt(4) + 1,
      'unit': units[rng.nextInt(units.length)],
      'expiry_date':
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'location': locations[rng.nextInt(locations.length)],
      'notes': null,
      'date_added': now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      'inventory_name': 'Home',
    };
  }).toList();
}
