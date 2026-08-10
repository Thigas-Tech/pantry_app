import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/camera_capture_result.dart';
import 'package:pantry_app/screens/camera_capture_screen.dart';
import 'package:pantry_app/services/camera_image_processor.dart';

class MockCameraController extends Mock implements CameraController {}

class FakeProcessor extends CameraImageProcessor {
  FakeProcessor(this.output);

  final File output;

  @override
  Future<File> resizeToStandard(File source) async => output;
}

void main() {
  const backCamera = CameraDescription(
    name: 'back',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  CameraValue initializedValue({bool isTakingPicture = false}) {
    return const CameraValue.uninitialized(backCamera).copyWith(
      isInitialized: true,
      previewSize: const Size(1080, 1920),
      isTakingPicture: isTakingPicture,
    );
  }

  MockCameraController createController({
    CameraValue? value,
  }) {
    final controller = MockCameraController();
    when(() => controller.value).thenReturn(value ?? initializedValue());
    when(controller.initialize).thenAnswer((_) async {});
    when(controller.dispose).thenAnswer((_) async {});
    when(
      controller.buildPreview,
    ).thenReturn(const SizedBox.expand());
    return controller;
  }

  /// Builds a [MaterialApp] with localizations so the screen can resolve
  /// [AppLocalizations].
  Widget app({required Widget home, GlobalKey<NavigatorState>? navigatorKey}) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  /// Pumps a host that pushes [screen] and returns the future that resolves to
  /// the result popped from the route.
  Future<Future<Object?>> openScreen(
    WidgetTester tester,
    CameraCaptureScreen screen,
  ) async {
    final popped = Completer<Object?>();
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      app(
        navigatorKey: navKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  popped.complete(
                    await Navigator.of(context).push<CameraCaptureResult>(
                      MaterialPageRoute<CameraCaptureResult>(
                        builder: (_) => screen,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return popped.future;
  }

  testWidgets('shows a progress indicator while the camera initializes', (
    tester,
  ) async {
    final controller = createController();
    final completer = Completer<void>();
    when(controller.initialize).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      app(
        home: CameraCaptureScreen(
          camera: backCamera,
          controllerFactory: (_) => controller,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CameraPreview), findsOneWidget);
  });

  testWidgets('shows the camera preview once initialized', (tester) async {
    final controller = createController();
    await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
      ),
    );

    expect(find.byType(CameraPreview), findsOneWidget);
    verify(controller.initialize).called(1);
  });

  testWidgets('capturing a photo pops with the processed file', (tester) async {
    final capturedFile = File('/tmp/captured_resized.jpg');
    final controller = createController();
    when(
      controller.takePicture,
    ).thenAnswer((_) async => XFile('/tmp/captured_raw.jpg'));

    final popped = await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
        processor: FakeProcessor(capturedFile),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_camera));
    await tester.pumpAndSettle();

    final result = await popped;
    expect(result, isA<CameraCaptured>());
    expect((result! as CameraCaptured).file.path, capturedFile.path);
  });

  testWidgets('cancel pops with a cancelled result', (tester) async {
    final popped = await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => createController(),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(await popped, isA<CameraCaptureCancelled>());
  });

  testWidgets('shows an error state and pops unavailable on init failure', (
    tester,
  ) async {
    final controller = createController();
    when(
      controller.initialize,
    ).thenThrow(CameraException('CameraAccessDenied', 'denied'));

    final popped = await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
      ),
    );

    expect(find.text('Camera not available on this device.'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(await popped, isA<CameraCaptureUnavailable>());
  });

  testWidgets('does not capture twice while a capture is in flight', (
    tester,
  ) async {
    final controller = createController();
    final completer = Completer<XFile>();
    when(controller.takePicture).thenAnswer((_) => completer.future);

    final popped = await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
        processor: FakeProcessor(File('/tmp/captured_resized.jpg')),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_camera));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.photo_camera));
    await tester.pump();

    verify(controller.takePicture).called(1);

    completer.complete(XFile('/tmp/captured_raw.jpg'));
    await tester.pumpAndSettle();
    expect(await popped, isA<CameraCaptured>());
  });

  testWidgets('releases the camera on pause and restarts on resume', (
    tester,
  ) async {
    final controller = createController();
    await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    verify(controller.dispose).called(1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    verify(controller.initialize).called(2);
  });

  testWidgets('disposes the controller when the screen is disposed', (
    tester,
  ) async {
    final controller = createController();
    final popped = await openScreen(
      tester,
      CameraCaptureScreen(
        camera: backCamera,
        controllerFactory: (_) => controller,
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    verify(controller.dispose).called(1);
    expect(await popped, isA<CameraCaptureCancelled>());
  });
}
