import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';

import '../helpers/pump_app.dart';

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;

  @override
  void setActiveInventory(int newValue) {}
}

class _MockDatabaseHelper extends Mock implements DatabaseHelper {
  _MockDatabaseHelper() {
    when(
      () =>
          getBarcodesInInventory(any(), inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => <String>{});
  }
}

InventoryWithProduct _testItem(
  String name, {
  required String barcode,
  DateTime? expiryDate,
}) {
  return InventoryWithProduct(
    id: 1,
    barcode: barcode,
    quantity: 1,
    unit: 'pcs',
    location: 'pantry',
    productName: name,
    expiryDate: expiryDate?.toIso8601String().substring(0, 10),
    inventoryId: 1,
  );
}

void main() {
  late MockImageCacheService mockImageCache;

  setUp(() {
    mockImageCache = MockImageCacheService();
    when(
      () => mockImageCache.cacheImage(any(), any()),
    ).thenAnswer((_) async => null);
  });

  testWidgets('HomeScreen at 360dp small screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));

    final now = DateTime.now();
    final items = [
      _testItem(
        'Milk',
        barcode: '1',
        expiryDate: now.subtract(const Duration(days: 1)),
      ),
      _testItem(
        'Cheese',
        barcode: '2',
        expiryDate: now.add(const Duration(days: 1)),
      ),
      _testItem(
        'Apples',
        barcode: '3',
        expiryDate: now.add(const Duration(days: 30)),
      ),
      _testItem('Canned Beans', barcode: '4'),
    ];

    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Home'},
      ],
    );
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer(
      (_) async => items.map((e) {
        return {
          'id': e.id,
          'barcode': e.barcode,
          'quantity': e.quantity,
          'unit': e.unit,
          'expiry_date': e.expiryDate,
          'location': e.location,
          'notes': null,
          'date_added': null,
          'inventory_id': e.inventoryId,
          'product_name': e.productName,
          'product_image_url': null,
          'inventory_name': 'Home',
          'nutriscore_grade': null,
          'nutriscore_not_applicable_category': null,
          'product_category': null,
          'product_search_text': null,
          'product_type': null,
        };
      }).toList(),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        inventoryListProvider.overrideWith(
          (ref) => [
            InventorySummary.fromMap({'id': 1, 'name': 'Home'}),
          ],
        ),
        activeInventoryProvider.overrideWith(
          _FakeActiveInventoryNotifier.new,
        ),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_360dp.png'),
    );
  });
}
