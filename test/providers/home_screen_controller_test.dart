import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/home_screen_controller.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProductRepository mockRepo;

  setUp(() {
    mockRepo = createMockProductRepository();
  });

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('deleteSelected delegates to the product repository', () async {
    when(
      () => mockRepo.deleteInventoryItems([1, 2]),
    ).thenAnswer((_) async => 2);

    final container = containerWith();
    final notifier = container.read(homeScreenControllerProvider.notifier)
      ..toggleSelection(1)
      ..toggleSelection(2);

    await notifier.deleteSelected();

    verify(() => mockRepo.deleteInventoryItems([1, 2])).called(1);
    verifyNever(() => mockRepo.deleteInventoryItems(any()));
    expect(
      container.read(homeScreenControllerProvider).selectionMode,
      isFalse,
    );
  });

  test('deleteSelected with empty selection does nothing', () async {
    final container = containerWith();
    final notifier = container.read(homeScreenControllerProvider.notifier);

    await notifier.deleteSelected();

    verifyNever(() => mockRepo.deleteInventoryItems(any()));
  });

  test('moveSelected delegates to the product repository', () async {
    when(
      () => mockRepo.moveItemsToInventory([1, 2], 5),
    ).thenAnswer((_) async {});

    final container = containerWith();
    final notifier = container.read(homeScreenControllerProvider.notifier)
      ..toggleSelection(1)
      ..toggleSelection(2);

    await notifier.moveSelected(5);

    verify(() => mockRepo.moveItemsToInventory([1, 2], 5)).called(1);
    expect(
      container.read(homeScreenControllerProvider).selectionMode,
      isFalse,
    );
  });
}
