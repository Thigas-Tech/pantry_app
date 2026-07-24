import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/widgets/search_ingredient_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  void setActiveInventory(int newValue) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockApi;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockOffAdapter();
    SharedPreferences.setMockInitialValues({});
  });

  List<Override> sheetOverrides() => [
    databaseProvider.overrideWithValue(mockDb),
    apiServiceProvider.overrideWithValue(mockApi),
    hasConnectionProvider.overrideWith((ref) => Future.value(false)),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
  ];

  group('SearchIngredientSheet', () {
    testWidgets('shows search bar with autofocus', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SearchIngredientSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('shows hint on initial open', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SearchIngredientSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Search products by name'), findsAtLeast(1));
    });

    testWidgets('searches and shows local results', (tester) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Milk', brand: 'Brand'),
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SearchIngredientSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final searchField = find.byType(SearchBar);
      await tester.enterText(searchField, 'milk');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('tapping result returns the product', (tester) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Milk', brand: 'Brand'),
        ],
      );

      Product? result;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await SearchIngredientSheet.show(context);
            },
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final searchField = find.byType(SearchBar);
      await tester.enterText(searchField, 'milk');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.barcode, '123');
    });

    testWidgets('shows no results state', (tester) async {
      when(() => mockDb.searchProducts('xyzzy')).thenAnswer(
        (_) async => [],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SearchIngredientSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
        settle: false,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final searchField = find.byType(SearchBar);
      await tester.enterText(searchField, 'xyzzy');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(
        find.text('No products found. Try a custom item.'),
        findsAtLeast(1),
      );
    });
  });
}
