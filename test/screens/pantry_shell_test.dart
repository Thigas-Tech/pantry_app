import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';

import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {
  _MockDatabaseHelper() {
    when(
      () =>
          getBarcodesInInventory(any(), inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => <String>{});
  }
}

void main() {
  testWidgets('renders NavigationBar with 5 destinations', (tester) async {
    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => []);

    await pumpApp(
      tester,
      const PantryShell(),
      settle: false,
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        inventoryCountProvider.overrideWith((ref) => 0),
        activeInventoryProvider.overrideWith(
          ActiveInventoryNotifier.new,
        ),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        connectivityProvider.overrideWith((ref) => const Stream.empty()),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
        allRecipesProvider.overrideWith((ref) => []),
      ],
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('second tab shows RecipeListScreen', (tester) async {
    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => []);

    await pumpApp(
      tester,
      const PantryShell(),
      settle: false,
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        inventoryCountProvider.overrideWith((ref) => 0),
        activeInventoryProvider.overrideWith(
          ActiveInventoryNotifier.new,
        ),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        connectivityProvider.overrideWith((ref) => const Stream.empty()),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
        allRecipesProvider.overrideWith((ref) => []),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restaurant_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeListScreen), findsOneWidget);
  });
}
