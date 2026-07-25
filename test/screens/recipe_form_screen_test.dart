import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

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

  setUp(() {
    mockDb = MockDatabaseHelper();
    SharedPreferences.setMockInitialValues({});
  });

  group('_addIngredient dedup', () {
    testWidgets('same barcode deduplicates with doubled quantity', (
      tester,
    ) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'name': 'Flour', 'barcode': '123456'},
        ],
      );

      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
        ],
      );

      // First add
      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);

      // Second add (same barcode)
      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      // Still one row, quantity doubled
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('1.0'), findsNothing);
    });

    testWidgets('different barcodes create separate rows', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'name': 'Flour', 'barcode': '123'},
          {'name': 'Sugar', 'barcode': '456'},
        ],
      );

      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
        ],
      );

      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('free-text ingredients without barcode add separate rows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
        ],
      );

      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });
  });
}
