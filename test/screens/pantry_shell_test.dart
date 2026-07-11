import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/pantry_shell.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('renders NavigationBar with 5 destinations', (tester) async {
    await pumpApp(
      tester,
      const PantryShell(),
      settle: false,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        inventoryCountProvider.overrideWith((ref) => 0),
        activeInventoryProvider.overrideWith(
          ActiveInventoryNotifier.new,
        ),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        connectivityProvider.overrideWith((ref) => const Stream.empty()),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
