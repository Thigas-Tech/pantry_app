import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/gallery_permission_dialog.dart';
import '../helpers/pump_app.dart';

void main() {
  group('showGalleryPermissionDialog', () {
    testWidgets('shows title, body, cancel and open-settings actions', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showGalleryPermissionDialog(context),
            child: const Text('Open dialog'),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Gallery access needed'), findsOneWidget);
      expect(
        find.text(
          'Pantry needs access to your photos to choose an existing photo. '
          'Open Settings to allow access.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('open-settings button calls openAppSettings', (tester) async {
      var openedSettings = false;
      var dialogShown = true;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showGalleryPermissionDialog(
              context,
              openSettings: () async {
                openedSettings = true;
                dialogShown = false;
                return true;
              },
            ),
            child: const Text('Open dialog'),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(openedSettings, isTrue);
      expect(dialogShown, isFalse);
    });

    testWidgets('cancel does not open settings', (tester) async {
      var openedSettings = false;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showGalleryPermissionDialog(
              context,
              openSettings: () async {
                openedSettings = true;
                return true;
              },
            ),
            child: const Text('Open dialog'),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(openedSettings, isFalse);
    });
  });
}
