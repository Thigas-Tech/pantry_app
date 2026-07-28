import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/screens/product_picker_screen.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {
  _MockDatabaseHelper() {
    when(
      () =>
          getBarcodesInInventory(any(), inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => <String>{});
  }
}

class _MockOffAdapter extends Mock implements OffAdapter {}

class _MockUsdaApiClient extends Mock implements UsdaApiClient {}

void main() {
  late _MockDatabaseHelper mockDb;
  late _MockOffAdapter mockApi;
  late _MockUsdaApiClient mockUsda;

  const localProduct = Product(
    barcode: '001',
    name: 'Local Milk',
    brand: 'Brand A',
  );

  setUpAll(() {
    registerFallbackValue(const InventoryItem(barcode: 'fallback'));
    registerFallbackValue(
      const Product(barcode: 'fallback', name: 'Fallback'),
    );
  });

  setUp(() {
    mockDb = _MockDatabaseHelper();
    mockApi = _MockOffAdapter();
    mockUsda = _MockUsdaApiClient();

    when(() => mockDb.searchProducts(any())).thenAnswer((_) async => []);
    when(
      () => mockApi.searchProducts(
        any(),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockUsda.searchFood(any())).thenAnswer((_) async => []);
  });

  group('ProductPickerScreen', () {
    testWidgets('renders search bar and source dropdown', (tester) async {
      await pumpApp(
        tester,
        const ProductPickerScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockApi),
          usdaApiClientProvider.overrideWithValue(mockUsda),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ],
        settle: false,
      );
      await tester.pump();

      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byType(DropdownButton<SearchSource>), findsOneWidget);
    });

    testWidgets('tapping result pops with selected product', (tester) async {
      Product? result;
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductPickerScreen(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          apiServiceProvider.overrideWithValue(mockApi),
          usdaApiClientProvider.overrideWithValue(mockUsda),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ],
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(SearchBar), 'milk');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();

      expect(find.text('Local Milk'), findsOneWidget);

      await tester.tap(find.text('Local Milk'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.barcode, '001');
    });
  });
}
