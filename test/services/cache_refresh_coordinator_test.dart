import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/services/cache_refresh_coordinator.dart';
import 'package:pantry_app/services/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockProductRepository repo;
  late MockDatabaseHelper db;
  late bool hasConnection;

  CacheRefreshCoordinator buildCoordinator() {
    return CacheRefreshCoordinator(
      repo: repo,
      db: db,
      hasConnection: () async => hasConnection,
    );
  }

  setUp(() {
    repo = MockProductRepository();
    db = MockDatabaseHelper();
    hasConnection = true;
    when(() => repo.isCacheOverdue()).thenAnswer((_) async => true);
    when(() => repo.setLastRefreshTime()).thenAnswer((_) async {});
    when(() => db.getInventories()).thenAnswer((_) async => []);
  });

  test('returns 0 and does no work when offline', () async {
    hasConnection = false;

    final refreshed = await buildCoordinator().refreshIfOverdue();

    expect(refreshed, 0);
    verifyNever(() => repo.isCacheOverdue());
    verifyNever(() => repo.setLastRefreshTime());
    verifyNever(() => db.getInventories());
    verifyNever(() => repo.refreshInventoryProducts(any()));
  });

  test('returns 0 and does no work when the cache is fresh', () async {
    when(() => repo.isCacheOverdue()).thenAnswer((_) async => false);

    final refreshed = await buildCoordinator().refreshIfOverdue();

    expect(refreshed, 0);
    verifyNever(() => repo.setLastRefreshTime());
    verifyNever(() => db.getInventories());
    verifyNever(() => repo.refreshInventoryProducts(any()));
  });

  test('refreshes every inventory when online and overdue', () async {
    when(() => db.getInventories()).thenAnswer(
      (_) async => [
        {'id': 1},
        {'id': 2},
      ],
    );
    when(() => repo.refreshInventoryProducts(1)).thenAnswer((_) async => 3);
    when(() => repo.refreshInventoryProducts(2)).thenAnswer((_) async => 5);

    final refreshed = await buildCoordinator().refreshIfOverdue();

    expect(refreshed, 8);
    verifyInOrder([
      () => repo.setLastRefreshTime(),
      () => repo.refreshInventoryProducts(1),
      () => repo.refreshInventoryProducts(2),
    ]);
  });

  test('sets the refresh timestamp before firing refreshes', () async {
    when(() => db.getInventories()).thenAnswer(
      (_) async => [
        {'id': 1},
      ],
    );
    when(() => repo.refreshInventoryProducts(1)).thenAnswer((_) async => 1);

    await buildCoordinator().refreshIfOverdue();

    final invocationOrder = verifyInOrder([
      () => repo.setLastRefreshTime(),
      () => repo.refreshInventoryProducts(1),
    ]);
    expect(invocationOrder, isNotEmpty);
  });

  test('continues when one inventory refresh throws', () async {
    when(() => db.getInventories()).thenAnswer(
      (_) async => [
        {'id': 1},
        {'id': 2},
      ],
    );
    when(() => repo.refreshInventoryProducts(1)).thenThrow(
      Exception('boom'),
    );
    when(() => repo.refreshInventoryProducts(2)).thenAnswer((_) async => 4);

    final refreshed = await buildCoordinator().refreshIfOverdue();

    expect(refreshed, 4);
    verify(() => repo.refreshInventoryProducts(2)).called(1);
  });

  test('sets the timestamp even when no inventory exists', () async {
    final refreshed = await buildCoordinator().refreshIfOverdue();

    expect(refreshed, 0);
    verify(() => repo.setLastRefreshTime()).called(1);
  });
}
