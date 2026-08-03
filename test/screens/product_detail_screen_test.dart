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
/// temporarily enlarge it with setLargeScreen() before every test.
///
/// Every test uses the pumpApp helper, which sets up the required
/// providers and locales.  We override productRepositoryProvider and
/// notificationServiceProvider with stubbed mocks.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/misc.dart'; // for Override
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';
import '../services/mock_notification_service.dart';

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

/// A produce product with no serving size (simulates quick-add produce).
const produceProductNoServing = Product(
  barcode: 'produce-Apple',
  name: 'Apple',
  productType: ProductType.produce,
  energyKcal: 52,
  proteinG: 0.3,
  carbsG: 13.8,
  fatG: 0.2,
  fiberG: 2.4,
);

/// A produce product whose name has no serving preset.
const unknownProduce = Product(
  barcode: 'produce-XYZ',
  name: 'Unknown Fruit',
  productType: ProductType.produce,
);

/// A product where Nutri-Score is not applicable (e.g. food additives).
const notApplicableProduct = Product(
  barcode: '9999999999999',
  name: 'Sweetener',
  nutriscoreGrade: 'not-applicable',
  nutriscoreNotApplicableCategory: 'en:food-additives',
);

/// A product with a valid Nutri-Score grade.
const gradeAProduct = Product(
  barcode: '8888888888888',
  name: 'Healthy Snack',
  nutriscoreGrade: 'a',
);

/// A manual product with submitted status.
const submittedManualProduct = Product(
  barcode: '123456789',
  name: 'Manual Submitted',
  source: 'manual',
  submissionStatus: 'submitted',
);

/// A manual product with failed status.
const failedManualProduct = Product(
  barcode: '234567890',
  name: 'Manual Failed',
  source: 'manual',
  submissionStatus: 'failed',
);

/// A manual product with pending status.
const pendingManualProduct = Product(
  barcode: '345678901',
  name: 'Manual Pending',
  source: 'manual',
  submissionStatus: 'pending',
);

/// A manual product with no submission status.
const notSubmittedManualProduct = Product(
  barcode: '456789012',
  name: 'Manual Not Submitted',
  source: 'manual',
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

/// A fake [SettingsNotifier] that returns imperial settings globally.
class FakeSettingsNotifierImperial extends SettingsNotifier {
  @override
  Settings build() => const Settings(
    unitSystem: UnitSystem.imperial,
  );
}

// ---------- Mocks -----------------------------------------------------------

class MockProductRepository extends Mock implements ProductRepository {}

class MockProductSubmissionService extends Mock
    implements ProductSubmissionService {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

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
  registerFallbackValue(const Product(barcode: 'fallback', name: 'Fallback'));
}

// ---------- Test harness overrides ------------------------------------------

/// Returns the provider overrides needed by the screen.
List<Override> screenOverrides({
  required MockProductRepository mockRepo,
  required MockNotificationService mockNotif,
  MockProductSubmissionService? mockSubmissionService,
  MockDatabaseHelper? mockDb,
}) {
  return [
    productRepositoryProvider.overrideWithValue(mockRepo),
    notificationServiceProvider.overrideWithValue(mockNotif),
    if (mockSubmissionService != null)
      productSubmissionServiceProvider.overrideWithValue(mockSubmissionService),
    if (mockDb != null) databaseProvider.overrideWithValue(mockDb),
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
  late MockDatabaseHelper mockDb;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockProductRepository();
    mockNotif = MockNotificationService();
    mockDb = MockDatabaseHelper();
    when(() => mockDb.getLastAddDate()).thenAnswer((_) => Future.value());
    when(
      () => mockNotif.scheduleExpiryReminders(
        any(),
        productName: any(named: 'productName'),
        expiringSoonTitle: any(named: 'expiringSoonTitle'),
        buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
        expiringTodayTitle: any(named: 'expiringTodayTitle'),
        buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => mockNotif.cancelReminders(any()),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => mockNotif.cancelInactivityReminder(),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => mockNotif.scheduleInactivityReminder(
        lastAddDateEpoch: any(named: 'lastAddDateEpoch'),
        thresholdDays: any(named: 'thresholdDays'),
        title: any(named: 'title'),
        buildBody: any(named: 'buildBody'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
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

  testWidgets('shows preset serving size for produce without servingSize', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: produceProductNoServing),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    // Apple's Medium preset is 182 g -> "1 medium (182 g)"
    expect(find.textContaining('182'), findsOneWidget);
  });

  testWidgets('shows 100 g for unknown produce without servingSize', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: unknownProduce),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('100 g'), findsOneWidget);
  });

  testWidgets('shows N/A for non-produce with null servingSize', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: minimalProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('N/A'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Nutri-Score badge
  // --------------------------------------------------------------------------

  testWidgets('shows grey dashed badge when nutriscore is not applicable', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: notApplicableProduct),
      overrides: screenOverrides(
        mockRepo: mockRepo,
        mockNotif: mockNotif,
      ),
    );
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('hides nutriscore row when nutriscoreGrade is null', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: minimalProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.byType(NutriScoreBadge), findsNothing);
  });

  testWidgets('shows valid nutriscore badge for grade a', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: gradeAProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('A'), findsOneWidget);
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

    expect(find.textContaining('3 L'), findsOneWidget);
    expect(find.textContaining('Fridge'), findsOneWidget);
    expect(find.textContaining('1 pcs'), findsOneWidget);
    expect(find.textContaining('Pantry'), findsWidgets);
  });

  // --------------------------------------------------------------------------
  // Add to inventory
  // --------------------------------------------------------------------------

  testWidgets(
    'add to inventory flow creates item and shows snackbar',
    (
      tester,
    ) async {
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
      when(
        () => mockRepo.cacheProduct(any()),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ProductDetailScreen(product: testProduct),
        overrides: screenOverrides(
          mockRepo: mockRepo,
          mockNotif: mockNotif,
          mockDb: mockDb,
        ),
      );

      await tester.tap(find.text('Add to Inventory'));
      await tester.pumpAndSettle();

      expect(find.byType(AddToInventoryScreen), findsOneWidget);

      final newItem = makeItem(id: 3, quantity: 1);
      tester.state<NavigatorState>(find.byType(Navigator)).pop(newItem);
      await tester.pumpAndSettle();

      verify(() => mockRepo.addInventoryItem(newItem)).called(1);
      verify(
        () => mockNotif.scheduleExpiryReminders(
          any(),
          productName: any(named: 'productName'),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
        ),
      ).called(1);
      // The snackbar says "Item added to pantry."
      expect(find.textContaining('Item added'), findsOneWidget);
    },
  );

  // --------------------------------------------------------------------------
  // Edit inventory item
  // --------------------------------------------------------------------------

  testWidgets(
    'edit inventory item flow updates item and shows snackbar',
    (
      tester,
    ) async {
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
        overrides: screenOverrides(
          mockRepo: mockRepo,
          mockNotif: mockNotif,
          mockDb: mockDb,
        ),
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(AddToInventoryScreen), findsOneWidget);

      final updatedItem = existingItem.copyWith(quantity: 5);
      tester.state<NavigatorState>(find.byType(Navigator)).pop(updatedItem);
      await tester.pumpAndSettle();

      verify(() => mockRepo.updateInventoryItem(updatedItem)).called(1);
      verify(() => mockNotif.cancelReminders(existingItem.id!)).called(1);
      verify(
        () => mockNotif.scheduleExpiryReminders(
          updatedItem,
          productName: any(named: 'productName'),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
        ),
      ).called(1);
      // The snackbar says "Item updated."
      expect(find.textContaining('Item updated'), findsOneWidget);
    },
  );

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

  // --------------------------------------------------------------------------
  // Submission status chips (source = 'manual')
  // --------------------------------------------------------------------------

  testWidgets('shows submitted chip for manual product', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: submittedManualProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('Submitted to Open Food Facts'), findsOneWidget);
  });

  testWidgets('shows failed chip with retry for manual product', (
    tester,
  ) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: failedManualProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(
      find.text('Failed to submit product. Tap to retry.'),
      findsOneWidget,
    );
  });

  testWidgets('shows pending chip for manual product', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: pendingManualProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
      settle: false,
    );
    await tester.pump();
    expect(find.text('Pending submission to Open Food Facts'), findsOneWidget);
  });

  testWidgets('shows not submitted chip for manual product', (tester) async {
    setLargeScreen(tester);
    await pumpApp(
      tester,
      const ProductDetailScreen(product: notSubmittedManualProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );
    expect(find.text('Not submitted to Open Food Facts'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Quantity dialog
  // --------------------------------------------------------------------------

  testWidgets('quantity dialog opens and saves new value', (tester) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1, quantity: 5);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);
    when(
      () => mockRepo.updateInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.textContaining('5 pcs'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.updateInventoryItem(
        any(that: predicate<InventoryItem>((i) => i.quantity == 3)),
      ),
    ).called(1);
  });

  testWidgets('quantity dialog cancel does not change quantity', (
    tester,
  ) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1, quantity: 5);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.textContaining('5 pcs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  // --------------------------------------------------------------------------
  // Quantity increment / decrement buttons
  // --------------------------------------------------------------------------

  testWidgets('increment button increases quantity', (tester) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);
    when(
      () => mockRepo.updateInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.updateInventoryItem(
        any(that: predicate<InventoryItem>((i) => i.quantity == 3)),
      ),
    ).called(1);
  });

  testWidgets('decrement button when qty>1 decreases quantity', (
    tester,
  ) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1, quantity: 3);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);
    when(
      () => mockRepo.updateInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.updateInventoryItem(
        any(that: predicate<InventoryItem>((i) => i.quantity == 2)),
      ),
    ).called(1);
  });

  testWidgets('decrement button when qty==1 triggers delete', (
    tester,
  ) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1, quantity: 1);
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

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete item?'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Error handling in operations
  // --------------------------------------------------------------------------

  testWidgets('save failure shows error snackbar', (tester) async {
    setLargeScreen(tester);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [makeItem(id: 1)]);
    when(
      () => mockRepo.updateInventoryItem(any()),
    ).thenThrow(Exception('DB error'));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to save'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Undo delete flow
  // --------------------------------------------------------------------------

  testWidgets('undo delete restores item', (tester) async {
    setLargeScreen(tester);
    final item = makeItem(id: 1, quantity: 1);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [item]);
    when(
      () => mockRepo.deleteInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(1));
    when(
      () => mockRepo.addInventoryItem(any()),
    ).thenAnswer((_) => Future<int>.value(2));

    await pumpApp(
      tester,
      const ProductDetailScreen(product: testProduct),
      overrides: screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
    );

    // Delete the item.
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // The undo snackbar appears.
    expect(find.textContaining('Item removed'), findsOneWidget);

    // Tap the undo action (the SnackBar action button).
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.addInventoryItem(any())).called(1);
  });

  // --------------------------------------------------------------------------
  // Retry submission
  // --------------------------------------------------------------------------

  testWidgets('retry submission on failed chip', (tester) async {
    setLargeScreen(tester);
    final mockSubmission = MockProductSubmissionService();
    when(
      () => mockSubmission.submitProduct(any()),
    ).thenAnswer(
      (_) async => const Product(
        barcode: '234567890',
        name: 'Manual Failed',
        source: 'manual',
        submissionStatus: 'submitted',
      ),
    );

    await pumpApp(
      tester,
      const ProductDetailScreen(product: failedManualProduct),
      overrides: screenOverrides(
        mockRepo: mockRepo,
        mockNotif: mockNotif,
        mockSubmissionService: mockSubmission,
      ),
    );

    // Tap the refresh icon on the failed chip.
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    verify(() => mockSubmission.submitProduct(any())).called(1);
  });

  testWidgets(
    'add to inventory passes non-null id to scheduleExpiryReminders',
    (tester) async {
      setLargeScreen(tester);
      when(
        () => mockRepo.getInventoryForBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepo.addInventoryItem(any()),
      ).thenAnswer((_) => Future<int>.value(42));
      when(
        () => mockRepo.cacheProduct(any()),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ProductDetailScreen(product: testProduct),
        overrides: screenOverrides(
          mockRepo: mockRepo,
          mockNotif: mockNotif,
          mockDb: mockDb,
        ),
      );

      await tester.tap(find.text('Add to Inventory'));
      await tester.pumpAndSettle();
      expect(find.byType(AddToInventoryScreen), findsOneWidget);

      // Pop with an item that has null id (matching AddToInventoryScreen
      // for a new item).
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pop(
            InventoryItem(barcode: testProduct.barcode),
          );
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockNotif.scheduleExpiryReminders(
          captureAny<InventoryItem>(),
          productName: any(named: 'productName'),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
        ),
      ).captured;
      final remindedItem = captured.first as InventoryItem;
      expect(remindedItem.id, isNotNull);
      expect(remindedItem.id, 42);
    },
  );

  // --------------------------------------------------------------------------
  // Imperial unit conversion
  // --------------------------------------------------------------------------

  testWidgets(
    'converts serving size to imperial when settings specify imperial',
    (
      tester,
    ) async {
      // Use a product with structured serving data for conversion.
      const juice = Product(
        barcode: '4001234567890',
        name: 'Juice',
        servingSize: '250 ml',
        servingQuantity: 250,
      );
      setLargeScreen(tester);
      await pumpApp(
        tester,
        const ProductDetailScreen(product: juice),
        overrides: [
          ...screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
          settingsProvider.overrideWith(FakeSettingsNotifierImperial.new),
        ],
      );
      // 250 ml -> ~8.5 fl oz
      expect(find.textContaining('8.5 fl oz'), findsOneWidget);
    },
  );

  testWidgets(
    'converts inventory quantities to imperial when settings specify imperial',
    (
      tester,
    ) async {
      setLargeScreen(tester);
      final items = [
        makeItem(
          id: 1,
          quantity: 1,
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
        overrides: [
          ...screenOverrides(mockRepo: mockRepo, mockNotif: mockNotif),
          settingsProvider.overrideWith(FakeSettingsNotifierImperial.new),
        ],
      );
      // 1 L -> ~33.8 fl oz
      expect(find.textContaining('33.8 fl oz'), findsOneWidget);
      // 1 pcs should remain unchanged
      expect(find.textContaining('1 pcs'), findsOneWidget);
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
