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
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockOffAdapter extends Mock implements OffAdapter {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockOffAdapter mockOff;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockOff = MockOffAdapter();

    when(() => mockDb.searchProducts(any())).thenAnswer(
      (_) async => <Product>[],
    );
    when(
      () => mockDb.getDistinctProductsFromInventory(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  List<Override> sheetOverrides() => [
    databaseProvider.overrideWithValue(mockDb),
    apiServiceProvider.overrideWithValue(mockOff),
    hasConnectionProvider.overrideWith((ref) => Future.value(false)),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
  ];

  group('AddToShoppingListSheet', () {
    testWidgets('shows search bar with autofocus', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Add custom item'), findsOneWidget);
    });

    testWidgets('shows empty state on initial open', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Search products by name'),
        findsAtLeast(1),
      );
    });

    testWidgets('shows add custom item form', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add custom item'));
      await tester.pumpAndSettle();

      expect(find.text('Item name'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
    });

    testWidgets('can go back from custom form to search', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add custom item'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('searches and shows results', (tester) async {
      when(() => mockDb.searchProducts('milk')).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Milk', brand: 'Brand'),
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
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

    testWidgets('shows inventory products in empty state', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'barcode': '111', 'name': 'Milk'},
          {'barcode': '222', 'name': 'Bread'},
        ],
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('From your pantry'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('In your pantry'), findsAtLeast(1));
    });

    testWidgets('inventory section hidden when empty', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToShoppingListSheet.show(context),
            child: const Text('Open'),
          ),
        ),
        overrides: sheetOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('From your pantry'), findsNothing);
    });
  });
}
