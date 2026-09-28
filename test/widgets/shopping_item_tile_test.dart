import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:pantry_app/widgets/shopping_item_tile.dart';

import '../helpers/pump_app.dart';

class MockShoppingListService extends Mock implements ShoppingListService {}

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this.settings);

  final Settings settings;

  @override
  Future<Settings> build() async => settings;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ShoppingItem(name: ''));
  });

  Future<void> pumpTile(
    WidgetTester tester, {
    required ShoppingItem item,
    Settings settings = const Settings(),
    bool marketTripMode = false,
  }) async {
    await pumpApp(
      tester,
      ShoppingItemTile(item: item, marketTripMode: marketTripMode),
      overrides: [
        settingsProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
        activeInventoryProvider.overrideWith(
          _FakeActiveInventoryNotifier.new,
        ),
        shoppingListServiceProvider.overrideWithValue(
          MockShoppingListService(),
        ),
        shoppingListProvider.overrideWith((ref) => <ShoppingItem>[]),
        if (item.barcode != null)
          productByBarcodeProvider(item.barcode!).overrideWith(
            (ref) => null,
          ),
      ],
    );
  }

  group('ShoppingItemTile', () {
    testWidgets('does not overflow a purchased item with a long name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const item = ShoppingItem(
        name: 'Creme de Leite Qualitá Ultra Pasteurizado',
        barcode: '123',
        isPurchased: true,
      );
      await pumpTile(tester, item: item);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a leading product image when one is cached', (
      tester,
    ) async {
      const item = ShoppingItem(name: 'Milk', barcode: '123');
      // A minimal 1x1 transparent PNG so Image.file decodes in tests.
      const pngBytes = <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('tile_image'),
      ))!;
      final img = (await tester.runAsync(
        () async {
          final file = File('${dir.path}/milk.png');
          await file.writeAsBytes(Uint8List.fromList(pngBytes));
          return file;
        },
      ))!;
      addTearDown(() async {
        if (await img.exists()) {
          await img.delete();
        }
        await dir.delete(recursive: true);
      });

      await pumpApp(
        tester,
        const ShoppingItemTile(
          item: ShoppingItem(name: 'Milk', barcode: '123'),
        ),
        settle: false,
        overrides: [
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const Settings()),
          ),
          activeInventoryProvider.overrideWith(
            _FakeActiveInventoryNotifier.new,
          ),
          shoppingListServiceProvider.overrideWithValue(
            MockShoppingListService(),
          ),
          shoppingListProvider.overrideWith((ref) => <ShoppingItem>[]),
          productByBarcodeProvider(item.barcode!).overrideWith(
            (ref) => const Product(
              barcode: '123',
              name: 'Milk',
              imageUrl: 'https://example.com/milk.jpg',
            ),
          ),
          cachedImageProvider((
            'https://example.com/milk.jpg',
            '123',
          )).overrideWith((ref) => img.path),
        ],
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('keeps the checkbox leading when no product image exists', (
      tester,
    ) async {
      const item = ShoppingItem(name: 'Milk', barcode: '123');
      await pumpTile(tester, item: item);

      expect(find.byType(Image), findsNothing);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets(
      'market trip mode renders no checkbox or add-again on a purchased item',
      (tester) async {
        const item = ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
        );
        await pumpTile(tester, item: item, marketTripMode: true);

        expect(find.byType(Checkbox), findsNothing);
        expect(find.text('Add again'), findsNothing);
        expect(find.byIcon(Icons.attach_money_outlined), findsNothing);
        // Delete remains available in the trip.
        expect(find.byIcon(Icons.delete), findsOneWidget);
        // The trip placeholder replaces the checkbox.
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      'market trip mode hides quantity steppers even for pending items',
      (tester) async {
        const item = ShoppingItem(name: 'Milk', barcode: '123');
        await pumpTile(tester, item: item, marketTripMode: true);

        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
        expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      },
    );

    testWidgets('shows the expiry date in the subtitle when set', (
      tester,
    ) async {
      const item = ShoppingItem(
        name: 'Milk',
        barcode: '123',
        isPurchased: true,
        expiryDate: '2026-12-31',
      );
      await pumpTile(tester, item: item);

      expect(find.text('Exp: 2026-12-31'), findsOneWidget);
    });

    testWidgets('hides the expiry line when no expiry is set', (tester) async {
      const item = ShoppingItem(name: 'Milk', barcode: '123');
      await pumpTile(tester, item: item);

      expect(find.textContaining('Exp:'), findsNothing);
    });
  });
}
