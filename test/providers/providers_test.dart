import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mock of [DatabaseHelper] used to override [databaseProvider].
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

/// Tests for Riverpod providers.
///
/// Each test creates a fresh [ProviderContainer] and overrides the
/// dependencies with mocks so the providers are fully isolated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(isOptional: true, mergeWith: {});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('databaseProvider', () {
    test('returns a DatabaseHelper instance', () {
      /// The provider should be overridable and return a non‑null instance.
      final db = container.read(databaseProvider);
      expect(db, isNotNull);
    });
  });

  group('activeInventoryProvider', () {
    late ProviderContainer mockContainer;
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
      when(mockDb.getInventories).thenAnswer(
        (_) async => [
          {'id': 1, 'name': 'Home', 'created_at': 1},
        ],
      );
      mockContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) => mockDb),
        ],
      );
    });

    tearDown(() {
      mockContainer.dispose();
    });

    test('defaults to 1', () {
      /// The active inventory ID should initially be 1 (the "Home" inventory).
      final id = mockContainer.read(activeInventoryProvider);
      expect(id, 1);
    });

    test('can be changed', () {
      /// Changing the notifier’s state updates the provider’s value.
      mockContainer.read(activeInventoryProvider.notifier).value = 2;
      final id = mockContainer.read(activeInventoryProvider);
      expect(id, 2);
    });
  });

  group('settingsProvider', () {
    test('defaults to sensible values', () {
      /// Notifications are enabled and retention is 60 days by default.
      final settings = container.read(settingsProvider);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.retentionDays, 60);
    });
  });

  group('themeModeProvider', () {
    test('defaults to system', () {
      /// The initial theme mode should follow the system setting.
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeModeOption.system);
    });
  });

  group('inventoryListProvider', () {
    test('returns inventories from the database', () async {
      /// Override [databaseProvider] with a mock that returns a known list.
      final mockDb = MockDatabaseHelper();
      final inventories = [
        {'id': 1, 'name': 'Home', 'created_at': 12345},
        {'id': 2, 'name': 'Work', 'created_at': 67890},
      ];
      when(mockDb.getInventories).thenAnswer((_) async => inventories);

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(inventoryListProvider.future);
      expect(list.length, 2);
      expect(list.first['name'], 'Home');
    });
  });

  group('inventoryWithProductProvider', () {
    test('returns joined rows for the active inventory', () async {
      /// Override [databaseProvider] with a mock, then switch the active
      /// inventory to 2.
      final mockDb = MockDatabaseHelper();
      when(mockDb.getInventories).thenAnswer(
        (_) async => [
          {'id': 1, 'name': 'Home', 'created_at': 1},
          {'id': 2, 'name': 'Work', 'created_at': 2},
        ],
      );
      final rows = [
        {
          'id': 1,
          'barcode': '123',
          'quantity': 2,
          'unit': 'pcs',
          'expiry_date': '2026-06-01',
          'location': 'fridge',
          'notes': null,
          'date_added': 123456,
          'inventory_id': 2,
          'product_name': 'Milk',
          'product_image_url': null,
          'inventory_name': 'Work',
        },
      ];
      when(
        () => mockDb.getInventoryWithProduct(inventoryId: 2),
      ).thenAnswer((_) async => rows);

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      // Simulate switching to inventory 2 (Work).
      container.read(activeInventoryProvider.notifier).value = 2;

      final items = await container.read(inventoryWithProductProvider.future);
      expect(items.length, 1);
      final item = items.first;
      expect(item.inventoryId, 2);
      expect(item.productName, 'Milk');
      expect(item.inventoryName, 'Work');
    });
  });
  group('apiServiceProvider', () {
    test('returns an OffAdapter instance', () {
      final api = container.read(apiServiceProvider);
      expect(api, isNotNull);
    });
  });

  group('productSubmissionServiceProvider', () {
    test('returns a ProductSubmissionService instance', () {
      final svc = container.read(productSubmissionServiceProvider);
      expect(svc, isNotNull);
    });
  });

  group('productRepositoryProvider', () {
    test('returns a ProductRepository instance', () {
      final repo = container.read(productRepositoryProvider);
      expect(repo, isNotNull);
    });
  });

  group('notificationServiceProvider', () {
    test('returns a NotificationService instance', () {
      final svc = container.read(notificationServiceProvider);
      expect(svc, isNotNull);
    });
  });

  group('imageCacheProvider', () {
    test('returns an ImageCacheService instance', () {
      final svc = container.read(imageCacheProvider);
      expect(svc, isNotNull);
    });
  });

  group('inventoryCountProvider', () {
    /// Verifies [inventoryCountProvider] returns the length of the
    /// [inventoryWithProductProvider] list.
    test('returns item count from inventoryWithProductProvider', () async {
      final mockDb = MockDatabaseHelper();
      when(mockDb.getInventories).thenAnswer(
        (_) async => [
          {'id': 1, 'name': 'Home', 'created_at': 1},
        ],
      );
      final rows = <Map<String, dynamic>>[
        {
          'id': 1,
          'barcode': '001',
          'quantity': 1,
          'unit': 'pcs',
          'inventory_id': 1,
          'product_name': 'Milk',
        },
        {
          'id': 2,
          'barcode': '002',
          'quantity': 2,
          'unit': 'kg',
          'inventory_id': 1,
          'product_name': 'Bread',
        },
      ];
      when(
        () => mockDb.getInventoryWithProduct(inventoryId: 1),
      ).thenAnswer((_) async => rows);

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(inventoryCountProvider.future);
      expect(count, 2);
    });
  });

  group('averageNutriscoreProvider', () {
    /// Verifies [averageNutriscoreProvider] returns null when none of
    /// the products have a NutriScore grade.
    test('returns null when no products have NutriScore', () async {
      final mockDb = MockDatabaseHelper();
      when(mockDb.getInventories).thenAnswer(
        (_) async => [
          {'id': 1, 'name': 'Home', 'created_at': 1},
        ],
      );
      when(
        () => mockDb.getInventoryWithProduct(inventoryId: 1),
      ).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'barcode': '001',
            'inventory_id': 1,
            'product_name': 'Milk',
          },
        ],
      );

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      final grade = await container.read(averageNutriscoreProvider.future);
      expect(grade, isNull);
    });

    /// Verifies [averageNutriscoreProvider] returns the correct letter
    /// grade when products have NutriScore grades.
    test('returns correct grade for mixed scores', () async {
      final mockDb = MockDatabaseHelper();
      when(mockDb.getInventories).thenAnswer(
        (_) async => [
          {'id': 1, 'name': 'Home', 'created_at': 1},
        ],
      );
      when(
        () => mockDb.getInventoryWithProduct(inventoryId: 1),
      ).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'barcode': '001',
            'inventory_id': 1,
            'product_name': 'Milk',
            'nutriscore_grade': 'a',
          },
          {
            'id': 2,
            'barcode': '002',
            'inventory_id': 1,
            'product_name': 'Candy',
            'nutriscore_grade': 'e',
          },
        ],
      );

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      // a=5, e=1 → avg=3 → rounded=3 → grade='c'
      final grade = await container.read(averageNutriscoreProvider.future);
      expect(grade, 'c');
    });
  });
}
