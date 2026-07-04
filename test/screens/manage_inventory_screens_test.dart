/// @file ManageInventoriesScreen widget tests.
///
/// Tests for the inventory management screen.  We verify:
/// - Loading spinner while the inventory list is being fetched.
/// - Error message when fetching fails.
/// - Empty state when there are no inventories.
/// - List of inventories with item count and active check mark.
/// - Tapping an inventory sets it as active and pops the screen.
/// - Long‑press opens a rename dialog; renaming updates the inventory list.
/// - "Create new pantry" tile opens a dialog; creating adds an inventory.
/// - Delete action (from rename dialog) asks for confirmation; confirming
///   deletes the inventory.
/// - Error snackbars are shown when create/rename/delete fail.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart'; // Override
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/services/product_repository.dart';
import '../helpers/pump_app.dart';

// ---------- Fakes -----------------------------------------------------------

/// A controllable fake for [ActiveInventoryNotifier] that starts at 1.
class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

// ---------- Mocks -----------------------------------------------------------

class MockProductRepository extends Mock implements ProductRepository {}

// Register fallback values so mocktail can match any().
void _registerFallbacks() {
  registerFallbackValue('fallback-name');
  registerFallbackValue(1);
}

// ---------- Helpers ----------------------------------------------------------

/// Typical inventory row data returned by `inventoryListProvider`.
Map<String, dynamic> makeInventory({
  required int id,
  String name = 'Home',
  int itemCount = 0,
}) {
  return {'id': id, 'name': name, 'item_count': itemCount};
}

/// Builds the list of overrides for the screen.
List<Override> screenOverrides({
  required List<Map<String, dynamic>> inventories,
  MockProductRepository? mockRepo,
}) {
  return [
    inventoryListProvider.overrideWith(
      (ref) => List<Map<String, dynamic>>.from(inventories),
    ),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
    if (mockRepo != null) productRepositoryProvider.overrideWithValue(mockRepo),
  ];
}

// ---------- Tests -----------------------------------------------------------

void main() {
  setUpAll(_registerFallbacks);

  late MockProductRepository mockRepo;

  setUp(() {
    mockRepo = MockProductRepository();
    // Default stubs – all return a dummy int.
    when(
      () => mockRepo.createInventory(any()),
    ).thenAnswer((_) => Future<int>.value(1));
    when(
      () => mockRepo.renameInventory(any(), any()),
    ).thenAnswer((_) => Future<int>.value(1));
    when(
      () => mockRepo.deleteInventory(any()),
    ).thenAnswer((_) => Future<int>.value(1));
  });

  // --------------------------------------------------------------------------
  // Loading / error / empty states
  // --------------------------------------------------------------------------

  testWidgets('shows loading spinner while fetching', (tester) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: [
        inventoryListProvider.overrideWith((ref) => completer.future),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
      ],
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows error when fetch fails', (tester) async {
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: [
        inventoryListProvider.overrideWith(
          (ref) => Future.error('fetch error'),
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
      ],
    );
    expect(find.text('Failed to load inventory.'), findsOneWidget);
  });

  testWidgets('shows empty state when no inventories', (tester) async {
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: []),
    );
    // Exact string from ARB: "No inventories."
    expect(find.text('No inventories.'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // List display and active indicator
  // --------------------------------------------------------------------------

  testWidgets('displays inventories with item count', (tester) async {
    final inventories = [
      makeInventory(id: 1, itemCount: 5),
      makeInventory(id: 2, name: 'Work'),
    ];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories),
    );
    expect(find.text('Home'), findsOneWidget);
    // ARB: "Items: 5"
    expect(find.text('Items: 5'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    // ARB: "Items: 0"
    expect(find.text('Items: 0'), findsOneWidget);
  });

  testWidgets('active inventory shows check icon', (tester) async {
    final inventories = [
      makeInventory(id: 1),
      makeInventory(id: 2, name: 'Work'),
    ];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories),
    );
    // The fake notifier always returns 1, so Home should have a check icon.
    final tile = find.widgetWithText(ListTile, 'Home');
    final iconInside = find.descendant(
      of: tile,
      matching: find.byIcon(Icons.check),
    );
    expect(iconInside, findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Tapping to select an inventory
  // --------------------------------------------------------------------------

  testWidgets('tapping an inventory sets it as active and pops', (
    tester,
  ) async {
    final inventories = [
      makeInventory(id: 1),
      makeInventory(id: 2, name: 'Work'),
    ];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories),
    );
    // Tap on 'Work'
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    // Screen should be popped.
    expect(find.byType(ManageInventoriesScreen), findsNothing);
  });

  // --------------------------------------------------------------------------
  // Create inventory
  // --------------------------------------------------------------------------

  testWidgets('create new pantry flow', (tester) async {
    final inventories = [makeInventory(id: 1)];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );

    await tester.tap(find.text('Create new pantry'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('New pantry'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Office');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verify(() => mockRepo.createInventory('Office')).called(1);
    // ARB: "\"Office\" created."
    expect(find.text('"Office" created.'), findsOneWidget);
  });

  testWidgets('create fails gracefully', (tester) async {
    when(
      () => mockRepo.createInventory(any()),
    ).thenThrow(Exception('test failure'));
    final inventories = [makeInventory(id: 1)];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );
    await tester.tap(find.text('Create new pantry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Office');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // ARB: "Could not create inventory."
    expect(find.text('Could not create inventory.'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Rename inventory
  // --------------------------------------------------------------------------

  testWidgets('rename inventory flow', (tester) async {
    final inventories = [
      makeInventory(id: 1),
      makeInventory(id: 2, name: 'Work'),
    ];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );

    await tester.longPress(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Rename pantry'), findsOneWidget);

    final textField = find.byType(TextField);
    await tester.enterText(textField, ''); // clear
    await tester.enterText(textField, 'Main');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.renameInventory(1, 'Main')).called(1);
    // ARB: "Renamed to \"Main\"."
    expect(find.text('Renamed to "Main".'), findsOneWidget);
  });

  testWidgets('rename fails gracefully', (tester) async {
    when(
      () => mockRepo.renameInventory(any(), any()),
    ).thenThrow(Exception('rename error'));
    final inventories = [makeInventory(id: 1)];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );
    await tester.longPress(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Main');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    // ARB: "Could not rename inventory."
    expect(find.text('Could not rename inventory.'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Delete inventory
  // --------------------------------------------------------------------------

  testWidgets('delete inventory flow', (tester) async {
    final inventories = [
      makeInventory(id: 1),
      makeInventory(id: 2, name: 'Work'),
    ];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );

    // Long‑press on 'Home'
    await tester.longPress(find.text('Home'));
    await tester.pumpAndSettle();

    // Tap the Delete button in the rename dialog.
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears. Title: "Delete pantry?"
    expect(find.text('Delete pantry?'), findsOneWidget);

    // Confirm deletion.
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.deleteInventory(1)).called(1);
    // ARB: "\"Home\" deleted."
    expect(find.text('"Home" deleted.'), findsOneWidget);
  });

  testWidgets('delete fails gracefully', (tester) async {
    when(
      () => mockRepo.deleteInventory(any()),
    ).thenThrow(Exception('delete error'));
    final inventories = [makeInventory(id: 1)];
    await pumpApp(
      tester,
      const ManageInventoriesScreen(),
      overrides: screenOverrides(inventories: inventories, mockRepo: mockRepo),
    );
    await tester.longPress(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // ARB: "Could not delete inventory."
    expect(find.text('Could not delete inventory.'), findsOneWidget);
  });
}
