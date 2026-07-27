import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/onboarding_provider.dart'
    show OnboardingNotifier, onboardingProvider;
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  int _lastSetValue = 1;

  int getRecordedLastSetValue() => _lastSetValue;

  @override
  int build() => 1;

  @override
  void setActiveInventory(int newValue) {
    _lastSetValue = newValue;
    super.setActiveInventory(newValue);
  }
}

Map<String, dynamic> itemToRow(InventoryWithProduct item) {
  return {
    'id': item.id,
    'barcode': item.barcode,
    'quantity': item.quantity,
    'unit': item.unit,
    'expiry_date': item.expiryDate,
    'location': item.location,
    'notes': item.notes,
    'date_added': item.dateAdded,
    'inventory_id': item.inventoryId,
    'product_name': item.productName,
    'product_image_url': item.productImageUrl,
    'inventory_name': item.inventoryName,
    'nutriscore_grade': item.nutriscoreGrade,
    'nutriscore_not_applicable_category': item.nutriscoreNotApplicableCategory,
    'product_category': item.productCategory,
    'product_search_text': item.productSearchText,
    'product_type': item.productType?.name,
  };
}

/// Creates a single [InventoryWithProduct] test fixture with the given
/// [name], [barcode], [expiryDate], [id], and [inventoryId].
InventoryWithProduct testItem(
  String name, {
  String? barcode,
  DateTime? expiryDate,
  int id = 1,
  int inventoryId = 1,
}) {
  return InventoryWithProduct(
    id: id,
    barcode: barcode ?? name,
    quantity: 1,
    unit: 'pcs',
    location: 'pantry',
    productName: name,
    expiryDate: expiryDate?.toIso8601String().substring(0, 10),
    inventoryId: inventoryId,
  );
}

/// Creates a MockDatabaseHelper that returns [items] from
/// getInventoryWithProduct and [inventories] from getInventories.
_MockDatabaseHelper _createMockDb({
  List<InventoryWithProduct> items = const [],
  List<Map<String, dynamic>> inventories = const [],
}) {
  final mockDb = _MockDatabaseHelper();
  when(mockDb.getInventories).thenAnswer((_) async => inventories);
  when(
    () => mockDb.getInventoryWithProduct(
      inventoryId: any(named: 'inventoryId'),
    ),
  ).thenAnswer((_) async => items.map(itemToRow).toList());
  return mockDb;
}

/// Common overrides for HomeScreen tests. Mocks DB, inventory list, and repo.
class FakeOnboardingNotifier extends OnboardingNotifier {
  FakeOnboardingNotifier({required this.initialValue});
  final bool initialValue;

  @override
  bool build() => initialValue;
}

List<Override> _homeScreenOverrides({
  required _MockDatabaseHelper mockDb,
  List<Map<String, dynamic>> inventories = const [],
  MockProductRepository? mockRepo,
  bool online = false,
  ActiveInventoryNotifier Function()? activeInventoryFactory,
  bool onboardingComplete = false,
}) {
  return [
    databaseProvider.overrideWithValue(mockDb),
    inventoryListProvider.overrideWith((ref) => inventories),
    onboardingProvider.overrideWith(
      () => FakeOnboardingNotifier(initialValue: onboardingComplete),
    ),
    if (activeInventoryFactory != null)
      activeInventoryProvider.overrideWith(activeInventoryFactory)
    else
      activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
    productRepositoryProvider.overrideWithValue(
      mockRepo ?? createMockProductRepository(),
    ),
    if (online) hasConnectionProvider.overrideWith((ref) => Future.value(true)),
    averageNutriscoreProvider.overrideWith((ref) => Future.value()),
  ];
}

void main() {
  late MockImageCacheService mockImageCache;

  setUp(() {
    mockImageCache = MockImageCacheService();
    when(
      () => mockImageCache.cacheImage(any(), any()),
    ).thenAnswer((_) async => null);
  });

  testWidgets('shows loading spinner when inventory is loading', (
    tester,
  ) async {
    final completer = Completer<List<InventoryWithProduct>>();
    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer(
      (_) => completer.future.then((items) => items.map(itemToRow).toList()),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      settle: false,
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        inventoryListProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows error message when inventory fails', (tester) async {
    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenThrow(Exception('DB error'));

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(mockDb: mockDb),
    );

    expect(find.text('Failed to load inventory.'), findsAtLeast(1));
  });

  testWidgets('shows empty state when inventory list is empty', (tester) async {
    final mockDb = _createMockDb(items: [], inventories: []);
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(mockDb: mockDb, onboardingComplete: true),
    );

    expect(find.text('Your pantry is empty'), findsOneWidget);
  });

  testWidgets(
    'shows OnboardingFlow when inventory is empty and onboarding not complete',
    (
      tester,
    ) async {
      final mockDb = _createMockDb(items: [], inventories: []);
      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: _homeScreenOverrides(mockDb: mockDb),
      );

      expect(find.byType(OnboardingFlow), findsOneWidget);
    },
  );

  testWidgets('shows inventory items grouped by expiry', (tester) async {
    final now = DateTime.now();
    final items = [
      testItem(
        'expired',
        barcode: '1',
        expiryDate: now.subtract(const Duration(days: 1)),
      ),
      testItem(
        'expiringSoon',
        barcode: '2',
        expiryDate: now.add(const Duration(days: 1)),
        id: 2,
      ),
      testItem(
        'good',
        barcode: '3',
        expiryDate: now.add(const Duration(days: 30)),
        id: 3,
      ),
      testItem('no expiry', barcode: '4', id: 4),
    ];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
      ),
    );

    expect(find.text('Expired'), findsAtLeast(1));
    expect(find.text('Expiring soon'), findsAtLeast(1));
    expect(find.text('Good'), findsAtLeast(1));
  });

  testWidgets('shows inventory switcher when multiple inventories exist', (
    tester,
  ) async {
    final mockDb = _createMockDb(
      inventories: [
        {'id': 1, 'name': 'Home'},
        {'id': 2, 'name': 'Work'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
          {'id': 2, 'name': 'Work'},
        ],
      ),
    );

    expect(find.byType(InventorySwitcherCard), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
  });

  testWidgets('FAB is + icon and opens action sheet on tap', (tester) async {
    final mockDb = _createMockDb();
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(mockDb: mockDb, onboardingComplete: true),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .child,
      isA<Icon>().having((i) => i.icon, 'icon', Icons.add),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Register a recipe'), findsOneWidget);
    expect(find.text('Market trip'), findsOneWidget);
  });

  testWidgets('action sheet scan barcode navigates to scanner', (tester) async {
    final mockDb = _createMockDb();
    final mockRepo = createMockProductRepository();
    when(() => mockRepo.getProduct('123')).thenAnswer(
      (_) async => const Product(barcode: '123', name: 'Test'),
    );
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        ..._homeScreenOverrides(
          mockDb: mockDb,
          mockRepo: mockRepo,
          onboardingComplete: true,
        ),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Barcode'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ScannerScreen), findsOneWidget);
  });

  testWidgets('action sheet add product navigates to SearchScreen', (
    tester,
  ) async {
    final mockDb = _createMockDb();
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(mockDb: mockDb, onboardingComplete: true),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('action sheet register recipe navigates to RecipeListScreen', (
    tester,
  ) async {
    final mockDb = _createMockDb();
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        onboardingComplete: true,
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register a recipe'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeListScreen), findsOneWidget);
  });

  testWidgets('shows stock count badges with item counts', (tester) async {
    final now = DateTime.now();
    final items = [
      testItem(
        'Item 1',
        barcode: '1',
        expiryDate: now.add(const Duration(days: 10)),
      ),
      testItem(
        'Item 2',
        barcode: '2',
        expiryDate: now.add(const Duration(days: 1)),
        id: 2,
      ),
      testItem(
        'Item 3',
        barcode: '3',
        expiryDate: now.subtract(const Duration(days: 1)),
        id: 3,
      ),
    ];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
      ),
    );

    expect(find.textContaining('Total items: 3'), findsOneWidget);
    expect(find.textContaining('Expiring soon: 1'), findsOneWidget);
    expect(find.textContaining('Added this week: 0'), findsOneWidget);
  });

  testWidgets('search filters items and shows clear button', (tester) async {
    final items = [
      testItem('Milk', barcode: '111'),
      testItem('Bread', barcode: '222', id: 2),
    ];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
      ),
    );

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsOneWidget);

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Milk');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsNothing);

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsOneWidget);
  });

  testWidgets('shows no items match message when search yields empty', (
    tester,
  ) async {
    final items = [testItem('Milk', barcode: '111')];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
      ),
    );

    await tester.enterText(find.byType(TextField), 'XYZ');
    await tester.pumpAndSettle();

    expect(find.text('No items match your search'), findsOneWidget);
  });

  testWidgets('inventory switcher popup selects a different inventory', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final fakeNotifier = FakeActiveInventoryNotifier();
    final mockDb = _createMockDb(
      inventories: [
        {'id': 1, 'name': 'Home'},
        {'id': 2, 'name': 'Work'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        ..._homeScreenOverrides(
          mockDb: mockDb,
          inventories: [
            {'id': 1, 'name': 'Home'},
            {'id': 2, 'name': 'Work'},
          ],
          online: true,
          activeInventoryFactory: () => fakeNotifier,
        ),
      ],
    );

    final card = find.byType(InventorySwitcherCard);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();

    expect(fakeNotifier.getRecordedLastSetValue(), 2);
  });

  testWidgets(
    'FAB scanner flow: opens the scanner screen',
    (tester) async {
      final mockDb = _createMockDb();
      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          ..._homeScreenOverrides(mockDb: mockDb, onboardingComplete: true),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        ],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Barcode'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ScannerScreen), findsOneWidget);
    },
  );

  testWidgets('FAB scanner flow: leaving scanner returns to home', (
    tester,
  ) async {
    final mockDb = _createMockDb();
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        ..._homeScreenOverrides(mockDb: mockDb, onboardingComplete: true),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Barcode'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ScannerScreen), findsOneWidget);

    // Trigger the scanner confirmation dialog via maybePop
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(nav.maybePop());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Stop scanning?'), findsOneWidget);

    // Tap Leave to dismiss the scanner
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ScannerScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('long-press enters selection mode and selects item', (
    tester,
  ) async {
    final items = [
      testItem('Item A', barcode: '1'),
      testItem('Item B', barcode: '2', id: 2),
    ];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
        mockRepo: createMockProductRepository(),
      ),
    );

    await tester.longPress(find.byType(InventoryCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNWidgets(2));

    final firstCheckbox = tester.widget<Checkbox>(
      find.byType(Checkbox).first,
    );
    expect(firstCheckbox.value, isTrue);
  });

  testWidgets('tap still navigates when not in selection mode', (tester) async {
    final mockRepo = createMockProductRepository();
    const product = Product(barcode: '1', name: 'Item A');
    when(() => mockRepo.getProduct('1')).thenAnswer((_) async => product);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    final items = [
      testItem('Item A', barcode: '1'),
    ];

    final mockDb = _createMockDb(
      items: items,
      inventories: [
        {'id': 1, 'name': 'Home'},
      ],
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: _homeScreenOverrides(
        mockDb: mockDb,
        inventories: [
          {'id': 1, 'name': 'Home'},
        ],
        mockRepo: mockRepo,
      ),
    );

    await tester.tap(find.byType(InventoryCard));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  group('quick-add produce carousel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'tapping produce chip resolves and navigates to ProductDetailScreen',
      (tester) async {
        final mockRepo = createMockProductRepository();
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
          source: 'manual',
        );
        when(
          () => mockRepo.resolveProduceProduct('Apple'),
        ).thenAnswer((_) async => product);
        when(
          () => mockRepo.getInventoryForBarcode(
            any(),
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => <InventoryItem>[]);

        final mockDb = _createMockDb();
        await pumpApp(
          tester,
          const HomeScreen(),
          imageCacheMock: mockImageCache,
          overrides: _homeScreenOverrides(mockDb: mockDb, mockRepo: mockRepo),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(find.text('Apple'), findsOneWidget);

        await tester.tap(find.text('Apple'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        verify(() => mockRepo.resolveProduceProduct('Apple')).called(1);
        expect(find.byType(ProductDetailScreen), findsOneWidget);
        final detailScreen = tester.widget<ProductDetailScreen>(
          find.byType(ProductDetailScreen),
        );
        expect(detailScreen.product.barcode, 'produce-Apple');

        // Pop back to home screen to verify invalidation doesn't crash
        Navigator.of(tester.element(find.byType(ProductDetailScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('shows loading spinner on tapped chip while resolving', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      final mockDb = _createMockDb();
      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: _homeScreenOverrides(mockDb: mockDb, mockRepo: mockRepo),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when resolveProduceProduct fails', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenThrow(Exception('Network error'));

      final mockDb = _createMockDb();
      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: _homeScreenOverrides(mockDb: mockDb, mockRepo: mockRepo),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load product details.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('rapid tap same chip does not call resolve twice', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      final mockDb = _createMockDb();
      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: _homeScreenOverrides(mockDb: mockDb, mockRepo: mockRepo),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      await tester.tap(find.byType(ActionChip).first);
      await tester.pump();

      verify(() => mockRepo.resolveProduceProduct('Apple')).called(1);
    });
  });

  testWidgets('overdue cache refresh does not crash during init', (
    tester,
  ) async {
    final mockRepo = createMockProductRepository();
    when(mockRepo.isCacheOverdue).thenAnswer((_) async => true);
    when(() => mockRepo.refreshInventoryProducts(any())).thenAnswer(
      (_) async => 0,
    );
    when(mockRepo.setLastRefreshTime).thenAnswer((_) async {});

    // Keep DB pending so that the post-frame callback fires while
    // pantryProvider is still loading, then resolve it to overlap
    // the rebuild with the invalidation from refreshIfOverdue.
    final pantryCompleter = Completer<List<InventoryWithProduct>>();
    final mockDb = _MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer(
      (_) => pantryCompleter.future.then(
        (items) => items.map(itemToRow).toList(),
      ),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      settle: false,
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        inventoryListProvider.overrideWith(
          (ref) => [
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(
          FakeActiveInventoryNotifier.new,
        ),
        productRepositoryProvider.overrideWithValue(mockRepo),
        hasConnectionProvider.overrideWith(
          (ref) => Future.value(true),
        ),
        onboardingProvider.overrideWith(
          () => FakeOnboardingNotifier(initialValue: true),
        ),
      ],
    );

    // Post-frame callback has now fired and refreshIfOverdue is running.
    // Complete the DB to trigger a widget rebuild while refreshIfOverdue
    // is also completing its async work.
    pantryCompleter.complete([]);
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
