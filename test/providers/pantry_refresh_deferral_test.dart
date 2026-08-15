import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/product_repository.dart';

import '../helpers/pump_app.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

/// A shared counter of [Pantry.build] invocations.
class _BuildCounter {
  int value = 0;
}

/// A [Pantry] fake that records how many times it rebuilt.
class _FakePantry extends Pantry {
  _FakePantry(this.counter);

  final _BuildCounter counter;

  @override
  Future<List<InventoryWithProduct>> build() async {
    counter.value++;
    return const <InventoryWithProduct>[];
  }
}

void main() {
  testWidgets('Pantry.refresh defers its self-invalidation to a later frame', (
    tester,
  ) async {
    final repo = _MockProductRepository();
    when(() => repo.refreshInventoryProducts(any())).thenAnswer((_) async => 0);
    when(repo.setLastRefreshTime).thenAnswer((_) async {});

    final counter = _BuildCounter();
    final container = ProviderContainer(
      overrides: [
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(repo),
        pantryProvider.overrideWith(() => _FakePantry(counter)),
      ],
    );
    addTearDown(container.dispose);

    container.listen(
      pantryProvider,
      (_, _) {},
      fireImmediately: true,
    );
    expect(counter.value, 1);

    await container.read(pantryProvider.notifier).refresh();

    // The self-invalidation is deferred: the pantry must not rebuild
    // synchronously from refresh().
    expect(counter.value, 1);

    // The deferred invalidateSelf runs in the post-frame callback, then the
    // refresh task (timer-based for a bare container) fires on the next clock
    // advance, which rebuilds the pantry.
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(counter.value, 2);
  });
}
