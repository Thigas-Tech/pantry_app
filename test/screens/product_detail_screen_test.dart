/// @file ProductDetailScreen widget tests.
///
/// Tests for the screen that shows full product details and the associated
/// inventory items for the active pantry.  The screen is a
/// ConsumerStatefulWidget because it manages inventory operations and a
/// refresh counter.
///
/// We test:
/// - Product metadata (name, image, barcode, brand, category, serving size).
/// - Nutrition table (always present; shows dashes when data is missing).
/// - Ingredients expansion tile.
/// - Inventory list states: loading, error, empty, populated.
/// - Add/Edit/Delete inventory item flows, including:
///   - Navigator push/pop with result.
///   - Repository calls (add, update, delete).
///   - Notification scheduling / cancellation.
///   - Snackbar messages.
/// - Open Food Facts button presence.
///
/// The default test viewport is too small for this long screen, so we
/// temporarily enlarge it with `setLargeScreen()` before every test.
///
/// Every test uses the `pumpApp` helper, which sets up the required
/// providers and locales.  We override `productRepositoryProvider` and
/// `notificationServiceProvider` with stubbed mocks.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/misc.dart'; // for Override
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/services/product_repository.dart';
import '../helpers/pump_app.dart';

// ---------- Test data -------------------------------------------------------

/// A fully populated product used in most tests.
const testProduct = Product(
  barcode: '5901234123457',
  name: 'Test Product',
  brand: 'Test Brand',
  category: 'Dairy',
  imageUrl: 'https://example.com/image.jpg',
  servingSize: '250ml',
  energyKcal: 42,
  proteinG: 3.1,
  carbsG: 5.2,
  fatG: 1.8,
  fiberG: 0.5,
  saltG: 0.1,
  ingredients: 'Milk, sugar, flavourings',
);

/// A product without any optional data.
const minimalProduct = Product(
  barcode: '1111111111111',
  name: 'Bare Bones',
);

/// A sample inventory item.
InventoryItem makeItem({
  int? id,
  String barcode = '5901234123457',
  double quantity = 2,
  String unit = 'pcs',
  String location = 'pantry',
  String? expiryDate,
}) {
  return InventoryItem(
    id: id,
    barcode: barcode,
    quantity: quantity,
    unit: unit,
    location: location,
    expiryDate: expiryDate,
  );
}

// ---------- Fakes -----------------------------------------------------------

/// A fake [ActiveInventoryNotifier] that always holds 1.
class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

// ---------- Mocks -----------------------------------------------------------

class MockProductRepository extends Mock implements ProductRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void _registerFallbacks() {
  registerFallbackValue(const InventoryItem(barcode: 'fallback'));
  registerFallbackValue(
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel',
        'name',
        channelDescription: 'desc',
        importance: Importance.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
  registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
}

// ---------- Test harness overrides ------------------------------------------

/// Returns the provider overrides needed by the screen.
List<Override> screenOverrides({
  required MockProductRepository mockRepo,
  required MockNotificationService mockNotif,
}) {
  return [
    productRepositoryProvider.overrideWithValue(mockRepo),
    notificationServiceProvider.overrideWithValue(mockNotif),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
  ];
}

// ---------- Helpers ----------------------------------------------------------

/// Makes the test viewport tall enough to render the entire product detail
/// layout without scrolling, and resets it after the test.
void setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ---------- Tests -----------------------------------------------------------

void main() {
  setUpAll(_registerFallbacks);

  late MockProductRepository mockRepo;
  late MockNotificationService mockNotif;

  setUp(() {
    mockRepo = MockProductRepository();
    mockNotif = MockNotificationService();
    when(
      () => mockNotif.scheduleExpiryReminders(any()),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => mockNotif.cancelReminders(any()),
    ).thenAnswer((_) => Future<void>.value());
    // Default inventory – empty list
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);
  });

  // --------------------------------------------------------------------------
  // Product information display
  // --------------------------------------------------------------------------

  testWidgets('displays product name in app bar', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('Test Product'), findsOneWidget);
  });

  testWidgets('shows product image when imageUrl is provided', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('hides image when imageUrl is null', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: minimalProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('displays barcode, brand, category, and serving size', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.textContaining('5901234123457'), findsOneWidget);
    expect(find.textContaining('Test Brand'), findsOneWidget);
    expect(find.textContaining('Dairy'), findsOneWidget);
    expect(find.textContaining('250ml'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Nutrition table (always present; shows dashes when no data)
  // --------------------------------------------------------------------------

  testWidgets('nutrition table is always visible', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
  });

  testWidgets('nutrition table shows dashes for missing data', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: minimalProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    // The table is still shown, but values are '- kcal', '- g', etc.
    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('- kcal'), findsWidgets);
  });

  // --------------------------------------------------------------------------
  // Ingredients
  // --------------------------------------------------------------------------

  testWidgets('shows ingredients expansion tile', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
  });

  testWidgets('expands ingredients on tap', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('Milk, sugar, flavourings'), findsNothing);
    await tester.tap(find.text('Ingredients'));
    await tester.pumpAndSettle();
    expect(find.text('Milk, sugar, flavourings'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Inventory list states
  // --------------------------------------------------------------------------

  testWidgets('shows loading while inventory is fetching', (tester) async {
    setLargeScreen(tester);
    final completer = Completer<List<InventoryItem>>();
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows error when inventory fetch fails', (tester) async {
    setLargeScreen(tester);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) => Future.error('network error'));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    // The exact string depends on localisation; we check for a key substring.
    expect(find.textContaining('Failed'), findsOneWidget);
  });

  testWidgets('shows empty inventory message', (tester) async {
    setLargeScreen(tester);
    // Default stub already returns empty list.
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    expect(find.textContaining('No items'), findsOneWidget);
  });

  testWidgets('shows inventory items', (tester) async {
    setLargeScreen(tester);
    final items = [
      makeItem(
        id: 1,
        quantity: 3,
        unit: 'L',
        location: 'fridge',
        expiryDate: '2026-12-31',
      ),
      makeItem(id: 2, quantity: 1),
    ];
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => items);

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    // quantity is double, so 3 becomes "3.0"
    expect(find.textContaining('3.0 L'), findsOneWidget);
    expect(find.textContaining('fridge'), findsOneWidget);
    expect(find.textContaining('1.0 pcs'), findsOneWidget);
    expect(find.textContaining('pantry'), findsWidgets);
  });

  // --------------------------------------------------------------------------
  // Add to inventory
  // --------------------------------------------------------------------------

  testWidgets('add to inventory flow', (tester) async {
    setLargeScreen(tester);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepo.addInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.text('Add to Inventory'));
    await tester.pumpAndSettle();

    expect(find.byType(AddToInventoryScreen), findsOneWidget);

    final newItem = makeItem(id: 3, quantity: 1);
    tester.state<NavigatorState>(find.byType(Navigator)).pop(newItem);
    await tester.pumpAndSettle();

    verify(() => mockRepo.addInventoryItem(newItem)).called(1);
    verify(() => mockNotif.scheduleExpiryReminders(newItem)).called(1);
    // The snackbar says "Item added to pantry."
    expect(find.textContaining('Item added'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Edit inventory item
  // --------------------------------------------------------------------------

  testWidgets('edit inventory item flow', (tester) async {
    setLargeScreen(tester);
    final existingItem = makeItem(id: 5, unit: 'kg');
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [existingItem]);
    when(
      () => mockRepo.updateInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(AddToInventoryScreen), findsOneWidget);

    final updatedItem = existingItem.copyWith(quantity: 5);
    tester.state<NavigatorState>(find.byType(Navigator)).pop(updatedItem);
    await tester.pumpAndSettle();

    verify(() => mockRepo.updateInventoryItem(updatedItem)).called(1);
    verify(() => mockNotif.cancelReminders(existingItem.id!)).called(1);
    verify(() => mockNotif.scheduleExpiryReminders(updatedItem)).called(1);
    // The snackbar says "Item updated."
    expect(find.textContaining('Item updated'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Delete inventory item
  // --------------------------------------------------------------------------

  testWidgets('delete inventory item flow', (tester) async {
    setLargeScreen(tester);
    final item = makeItem(id: 10);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);
    when(
      () => mockRepo.deleteInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Verify the dialog title appears.
    expect(find.text('Delete item?'), findsOneWidget);

    // Tap the confirmation button (not the title).
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.deleteInventoryItem(item.id!)).called(1);
    verify(() => mockNotif.cancelReminders(item.id!)).called(1);
    // The snackbar says something like "Item removed from pantry."
    expect(find.textContaining('Item removed'), findsOneWidget);
  });
  // --------------------------------------------------------------------------
  // Open Food Facts button
  // --------------------------------------------------------------------------

  testWidgets('shows Open Food Facts button', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    final button = find.byTooltip('View on Open Food Facts');
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.open_in_browser)),
      findsOneWidget,
    );
  });
}
