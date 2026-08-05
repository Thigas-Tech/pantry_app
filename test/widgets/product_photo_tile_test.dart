import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import '../helpers/pump_app.dart';

/// A minimal 1x1 transparent PNG so [Image.file] decodes in tests.
final Uint8List kTransparentPng = Uint8List.fromList(const <int>[
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
  0x0D,
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
]);

void main() {
  late Directory tempDir;
  late File imageFile;
  var onAddCalls = 0;
  var onTapCalls = 0;
  var onDeleteCalls = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tile_test_');
    imageFile = File('${tempDir.path}/photo.png')
      ..writeAsBytesSync(kTransparentPng);
    onAddCalls = 0;
    onTapCalls = 0;
    onDeleteCalls = 0;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpTile(WidgetTester tester, {File? image}) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ProductPhotoTile(
          label: 'Nutrition table photo',
          image: image,
          onAdd: () => onAddCalls++,
          onTap: () => onTapCalls++,
          onDelete: () => onDeleteCalls++,
        ),
      ),
    );
  }

  group('ProductPhotoTile', () {
    testWidgets('empty state shows label and add affordance', (tester) async {
      await pumpTile(tester);

      expect(find.text('Nutrition table photo'), findsOneWidget);
      final addButton = find.byIcon(Icons.add_a_photo);
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      expect(onAddCalls, 1);
    });

    testWidgets('empty state exposes an add action via semantics', (
      tester,
    ) async {
      await pumpTile(tester);

      final semantics = tester.getSemantics(
        find.byType(ProductPhotoTile),
      );
      expect(
        semantics.label,
        contains('Add photo'),
        reason: 'Empty slot must be announced as an add action',
      );
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('filled state shows thumbnail and label', (tester) async {
      await pumpTile(tester, image: imageFile);

      expect(find.text('Nutrition table photo'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Add photo'), findsNothing);
    });

    testWidgets('tapping a filled tile fires onTap', (tester) async {
      await pumpTile(tester, image: imageFile);

      await tester.tap(find.byType(ProductPhotoTile));
      expect(onTapCalls, 1);
    });

    testWidgets('filled state exposes a preview action via semantics', (
      tester,
    ) async {
      await pumpTile(tester, image: imageFile);

      final semantics = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Preview photo')),
      );
      expect(
        semantics.label,
        contains('Preview photo'),
        reason: 'Filled tile must be announced as a preview action',
      );
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('delete button fires onDelete and has a tooltip', (
      tester,
    ) async {
      await pumpTile(tester, image: imageFile);

      final deleteButton = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline,
      );
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      expect(onDeleteCalls, 1);

      expect(find.byTooltip('Delete photo'), findsOneWidget);
    });
  });
}
