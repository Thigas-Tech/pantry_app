import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

/// A host that reads the by-inventory family and exposes a button to call
/// [invalidateShoppingListForInventory], so the refresh behavior is tested
/// through the same [WidgetRef] path the app uses.
class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  int _count = 0;

  void _refresh() {
    invalidateShoppingListForInventory(ref, 1);
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingListByInventoryProvider(1));
    final length = items.asData?.value.length ?? -1;
    return Column(
      children: [
        Text('count:$_count'),
        Text('items:$length'),
        TextButton(onPressed: _refresh, child: const Text('refresh')),
      ],
    );
  }
}

/// Verifies that [invalidateShoppingListForInventory] refreshes the
/// per-inventory family provider used by the market trip, so items added
/// during a trip appear without leaving the screen.
void main() {
  late _MockDatabaseHelper db;

  setUp(() {
    db = _MockDatabaseHelper();
    when(
      () => db.getShoppingList(inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => []);
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeInventoryProvider.overrideWith(
            _FakeActiveInventoryNotifier.new,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: _Host())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'invalidateShoppingListForInventory refetches the by-inventory family',
    (tester) async {
      await pumpHost(tester);
      expect(find.text('items:0'), findsOneWidget);

      // The DB now has one item; the family provider must re-query on
      // invalidation instead of returning its stale cached value.
      when(
        () => db.getShoppingList(inventoryId: any(named: 'inventoryId')),
      ).thenAnswer((_) async => const [ShoppingItem(name: 'Milk')]);

      await tester.tap(find.text('refresh'));
      await tester.pumpAndSettle();

      expect(find.text('items:1'), findsOneWidget);
      verify(() => db.getShoppingList(inventoryId: 1)).called(2);
    },
  );
}
