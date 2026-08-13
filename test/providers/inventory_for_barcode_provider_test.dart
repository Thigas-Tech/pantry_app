import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/inventory_for_barcode_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/product_repository.dart';


class _MockProductRepository extends Mock implements ProductRepository {
  _MockProductRepository() {
    when(
      () => getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);
    when(isCacheOverdue).thenAnswer((_) async => false);
    when(getLastRefreshTime).thenAnswer((_) async => null);
    when(() => getProductFromCache(any())).thenAnswer((_) async => null);
  }
}

void main() {
  test('caches the query result across reads for the same key', () async {
    final repo = _MockProductRepository();
    when(
      () => repo.getInventoryForBarcode(
        '001',
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer(
      (_) async => const [InventoryItem(barcode: '001', quantity: 2)],
    );

    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final first = await container.read(
      inventoryForBarcodeProvider(('001', 1)).future,
    );
    final second = await container.read(
      inventoryForBarcodeProvider(('001', 1)).future,
    );

    expect(first, hasLength(1));
    expect(second, hasLength(1));
    verify(
      () => repo.getInventoryForBarcode(
        '001',
        inventoryId: any(named: 'inventoryId'),
      ),
    ).called(1);
  });

  test('refetches after invalidation', () async {
    final repo = _MockProductRepository();
    when(
      () => repo.getInventoryForBarcode(
        '001',
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(inventoryForBarcodeProvider(('001', 1)).future);
    container.invalidate(inventoryForBarcodeProvider(('001', 1)));
    await container.read(inventoryForBarcodeProvider(('001', 1)).future);

    verify(
      () => repo.getInventoryForBarcode(
        '001',
        inventoryId: any(named: 'inventoryId'),
      ),
    ).called(2);
  });

  test('uses an independent cache per (barcode, inventoryId) key', () async {
    final repo = _MockProductRepository();
    when(
      () => repo.getInventoryForBarcode(
        '001',
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(inventoryForBarcodeProvider(('001', 1)).future);
    await container.read(inventoryForBarcodeProvider(('001', 2)).future);
    await container.read(inventoryForBarcodeProvider(('002', 1)).future);

    verify(
      () => repo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).called(3);
  });
}
