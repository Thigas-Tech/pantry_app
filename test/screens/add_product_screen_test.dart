import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import '../helpers/pump_app.dart';

class MockProductImageService extends Mock implements ProductImageService {}

class MockProductSubmissionService extends Mock
    implements ProductSubmissionService {}

/// A terminal [SubmissionProgress] snapshot representing a successful
/// submission, used to make the mocked service pop the screen.
const completedProgress = SubmissionProgress(
  barcode: '123',
  step: SubmissionStep.completed,
);

/// Stubs a submission so it emits the given [SubmissionProgress] snapshots
/// then returns, so the screen's save flow runs to completion.
void stubSubmission(
  MockProductSubmissionService service, {
  List<SubmissionProgress> progress = const [],
  Product? result,
}) {
  when(
    () => service.submitProduct(
      any(),
      onProgress: any(named: 'onProgress'),
    ),
  ).thenAnswer((invocation) async {
    final onProgress =
        invocation.namedArguments[#onProgress]
            as void Function(SubmissionProgress)?;
    if (onProgress != null) {
      progress.forEach(onProgress);
    }
    return result ?? const Product(barcode: '123', name: 'Test');
  });
}

/// Pumps [screen] with a viewport tall enough so all [ListView] children
/// are built. Resets the viewport on teardown.
Future<void> pumpTall(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await pumpApp(tester, screen);
  await tester.pumpAndSettle();
}

void main() {
  late MockProductImageService imageService;

  setUpAll(() {
    registerFallbackValue(const ProductPhotoSlots.empty());
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  setUp(() {
    imageService = MockProductImageService();
  });

  /// Pumps the screen with a mocked image service so the save flow never
  /// touches the filesystem (real I/O does not settle under testWidgets
  /// FakeAsync). Real file persistence is covered by the service unit tests.
  ///
  /// A mocked repository is provided so [ProductRepository.cacheProduct] is
  /// a no-op. Pass [submissionService] to assert on submission behavior and
  /// set [stubSubmissionAsSuccess] to make it emit a completed progress so
  /// the submit flow pops the screen as in production.
  Future<void> pumpSaveScreen(
    WidgetTester tester,
    Widget screen, {
    MockProductSubmissionService? submissionService,
    bool stubSubmissionAsSuccess = false,
  }) async {
    when(
      () => imageService.save(
        any(),
        barcode: any(named: 'barcode'),
      ),
    ).thenAnswer(
      (_) async => (
        nutrition: null,
        ingredients: null,
        product: null,
      ),
    );
    when(
      () => imageService.cleanupUncommitted(
        any(),
        barcode: any(named: 'barcode'),
        committedPaths: any(named: 'committedPaths'),
      ),
    ).thenAnswer((_) async {});

    final service = submissionService ?? MockProductSubmissionService();
    if (stubSubmissionAsSuccess) {
      stubSubmission(service, progress: [completedProgress]);
    }
    final repo = createMockProductRepository();
    when(() => repo.cacheProduct(any())).thenAnswer((_) async {});

    await pumpApp(
      tester,
      screen,
      overrides: [
        productImageServiceProvider.overrideWithValue(imageService),
        productSubmissionServiceProvider.overrideWithValue(service),
        productRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  group('AddProductScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.byType(AddProductScreen), findsOneWidget);
    });

    testWidgets('renders both actions always', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      expect(find.text('Save to inventory'), findsOneWidget);
      expect(find.text('Submit to Open Food Facts'), findsOneWidget);
    });

    testWidgets('save to inventory is primary by default', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      final saveButton = find.ancestor(
        of: find.text('Save to inventory'),
        matching: find.byType(ElevatedButton),
      );
      final submitButton = find.ancestor(
        of: find.text('Submit to Open Food Facts'),
        matching: find.byType(ElevatedButton),
      );
      expect(saveButton, findsOneWidget);
      expect(submitButton, findsNothing);
    });

    testWidgets('submit to OFF is primary when submitToOff is true', (
      tester,
    ) async {
      await pumpTall(
        tester,
        const AddProductScreen(barcode: '123', submitToOff: true),
      );

      final saveButton = find.ancestor(
        of: find.text('Save to inventory'),
        matching: find.byType(ElevatedButton),
      );
      final submitButton = find.ancestor(
        of: find.text('Submit to Open Food Facts'),
        matching: find.byType(ElevatedButton),
      );
      expect(saveButton, findsNothing);
      expect(submitButton, findsOneWidget);
    });

    testWidgets('shows product name field', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Product name'), findsOneWidget);
    });

    testWidgets('shows nutrition section', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Nutrition (per 100 g / 100 ml)'), findsOneWidget);
    });

    testWidgets('shows all nutrition field labels', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      for (final label in [
        'Energy',
        'Protein',
        'Carbs',
        'Fat',
        'Fiber',
        'Salt',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('shows brand and category fields', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('shows serving size field', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Serving size'), findsOneWidget);
    });

    testWidgets('shows below-the-fold content', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Save to inventory'), findsOneWidget);
      expect(find.text('Submit to Open Food Facts'), findsOneWidget);
      expect(find.text('Nutrition table photo'), findsOneWidget);
      expect(find.text('Ingredients list photo'), findsOneWidget);
      expect(find.text('Product photo'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('entering name and saving pops the route', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final submission = MockProductSubmissionService();
      await pumpSaveScreen(
        tester,
        const AddProductScreen(barcode: '123'),
        submissionService: submission,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsNothing);
      verifyZeroInteractions(submission);
    });

    testWidgets('saves all nutrition fields and serving size', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Product? captured;

      await pumpSaveScreen(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      // Fill every editable field.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Brand'),
        'Test Brand',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categories'),
        'Test Category',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serving size'),
        '100',
      );

      // Nutrition fields — identify each by its label Text sibling in a Row.
      Future<void> enterNutrition(String label, String value) async {
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(Row),
        );
        await tester.enterText(
          find.descendant(of: row, matching: find.byType(TextFormField)),
          value,
        );
      }

      await enterNutrition('Energy', '200');
      await enterNutrition('Protein', '10');
      await enterNutrition('Carbs', '30');
      await enterNutrition('Fat', '8');
      await enterNutrition('Fiber', '2');
      await enterNutrition('Salt', '0.5');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredients'),
        'Milk, Sugar',
      );

      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.barcode, '123');
      expect(captured!.name, 'Test Product');
      expect(captured!.brand, 'Test Brand');
      expect(captured!.category, 'Test Category');
      expect(captured!.servingSize, '100 g');
      expect(captured!.energyKcal, 200);
      expect(captured!.proteinG, 10);
      expect(captured!.carbsG, 30);
      expect(captured!.fatG, 8);
      expect(captured!.fiberG, 2);
      expect(captured!.saltG, 0.5);
      expect(captured!.ingredients, 'Milk, Sugar');
      expect(captured!.source, 'manual');
      expect(captured!.nutriscoreGrade, isNull);
    });

    testWidgets('saves with empty optional fields as null', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Product? captured;

      await pumpSaveScreen(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      // Only fill the required name field, leave everything else empty.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Minimal Product',
      );

      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.name, 'Minimal Product');
      expect(captured!.brand, isNull);
      expect(captured!.category, isNull);
      expect(captured!.servingSize, isNull);
      expect(captured!.energyKcal, isNull);
      expect(captured!.proteinG, isNull);
      expect(captured!.carbsG, isNull);
      expect(captured!.fatG, isNull);
      expect(captured!.fiberG, isNull);
      expect(captured!.saltG, isNull);
      expect(captured!.ingredients, isNull);
      expect(captured!.source, 'manual');
      expect(captured!.nutriscoreGrade, isNull);
    });

    testWidgets('saves serving size with a selected mg unit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Product? captured;

      await pumpSaveScreen(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serving size'),
        '250',
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mg').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.servingSize, '250 mg');
    });

    testWidgets('shows an error for a non-numeric serving size', (
      tester,
    ) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serving size'),
        'abc',
      );
      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a positive number'), findsOneWidget);
    });

    testWidgets('shows an error for a zero serving size', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serving size'),
        '0',
      );
      await tester.tap(find.text('Save to inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a positive number'), findsOneWidget);
    });
  });

  group('AddProductScreen submission progress', () {
    /// Pumps the screen in a tall viewport with the given submission service.
    Future<void> pumpForm(
      WidgetTester tester,
      MockProductSubmissionService service,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      when(
        () => imageService.save(any(), barcode: any(named: 'barcode')),
      ).thenAnswer(
        (_) async => (
          nutrition: null,
          ingredients: null,
          product: null,
        ),
      );
      when(
        () => imageService.cleanupUncommitted(
          any(),
          barcode: any(named: 'barcode'),
          committedPaths: any(named: 'committedPaths'),
        ),
      ).thenAnswer((_) async {});
      final repo = createMockProductRepository();
      when(() => repo.cacheProduct(any())).thenAnswer((_) async {});
      await pumpApp(
        tester,
        const AddProductScreen(barcode: '123'),
        overrides: [
          productImageServiceProvider.overrideWithValue(imageService),
          productSubmissionServiceProvider.overrideWithValue(service),
          productRepositoryProvider.overrideWithValue(repo),
        ],
      );
    }

    /// Pumps the screen inside a pushed route backed by a [Scaffold] so a
    /// success snackbar remains visible after the screen pops.
    Future<void> pumpPushedForm(
      WidgetTester tester,
      MockProductSubmissionService service,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      when(
        () => imageService.save(any(), barcode: any(named: 'barcode')),
      ).thenAnswer(
        (_) async => (
          nutrition: null,
          ingredients: null,
          product: null,
        ),
      );
      when(
        () => imageService.cleanupUncommitted(
          any(),
          barcode: any(named: 'barcode'),
          committedPaths: any(named: 'committedPaths'),
        ),
      ).thenAnswer((_) async {});
      final repo = createMockProductRepository();
      when(() => repo.cacheProduct(any())).thenAnswer((_) async {});
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddProductScreen(barcode: '123'),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
        overrides: [
          productImageServiceProvider.overrideWithValue(imageService),
          productSubmissionServiceProvider.overrideWithValue(service),
          productRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
    }

    Future<void> fillName(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
    }

    testWidgets('shows inline progress while submitting', (tester) async {
      final service = MockProductSubmissionService();
      final completer = Completer<Product>();
      when(
        () => service.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) {
        final onProgress =
            invocation.namedArguments[#onProgress]
                as void Function(SubmissionProgress)?;
        onProgress?.call(
          const SubmissionProgress(
            barcode: '123',
            step: SubmissionStep.uploadingNutrition,
            completedImageCount: 2,
            totalImageCount: 3,
          ),
        );
        return completer.future;
      });

      await pumpForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pump();

      expect(find.text('Uploading photo 3 of 3…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete(const Product(barcode: '123', name: 'Test'));
      await tester.pumpAndSettle();
    });

    testWidgets('ignores a second submit while a submission is in flight', (
      tester,
    ) async {
      final service = MockProductSubmissionService();
      final completer = Completer<Product>();
      when(
        () => service.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pump();

      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pump();

      verify(
        () => service.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      completer.complete(const Product(barcode: '123', name: 'Test'));
      await tester.pumpAndSettle();
    });

    testWidgets('pops with a success snackbar when submission completes', (
      tester,
    ) async {
      final service = MockProductSubmissionService();
      stubSubmission(service, progress: [completedProgress]);

      await pumpPushedForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsNothing);
      expect(
        find.text('Product submitted to Open Food Facts.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('stays open with a retry button on transient failure', (
      tester,
    ) async {
      final service = MockProductSubmissionService();
      stubSubmission(
        service,
        progress: const [
          SubmissionProgress(
            barcode: '123',
            step: SubmissionStep.failed,
            errorCategory: SubmissionErrorCategory.network,
            retryAvailable: true,
          ),
        ],
      );

      await pumpForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(
        find.text(
          'Could not reach Open Food Facts. Check your connection and retry.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry now'), findsOneWidget);
    });

    testWidgets('shows an error without retry for permanent rejection', (
      tester,
    ) async {
      final service = MockProductSubmissionService();
      stubSubmission(
        service,
        progress: const [
          SubmissionProgress(
            barcode: '123',
            step: SubmissionStep.failed,
            errorCategory: SubmissionErrorCategory.serverRejected,
          ),
        ],
      );

      await pumpForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pumpAndSettle();

      expect(
        find.text('Open Food Facts rejected the product data.'),
        findsOneWidget,
      );
      expect(find.text('Retry now'), findsNothing);
    });

    testWidgets(
      'shows the credentials message without retry for wrong credentials',
      (
        tester,
      ) async {
        final service = MockProductSubmissionService();
        stubSubmission(
          service,
          progress: const [
            SubmissionProgress(
              barcode: '123',
              step: SubmissionStep.failed,
              errorCategory: SubmissionErrorCategory.wrongCredentials,
            ),
          ],
        );

        await pumpForm(tester, service);
        await fillName(tester);
        await tester.tap(find.text('Submit to Open Food Facts'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Open Food Facts rejected your credentials. '
            'Submission is disabled. Check the Open Food Facts credentials '
            'in the app configuration and use your username, not your email.',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry now'), findsNothing);
      },
    );

    testWidgets('retry re-submits and pops on success', (tester) async {
      final service = MockProductSubmissionService();
      var callCount = 0;
      when(
        () => service.submitProduct(
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        callCount++;
        final onProgress =
            invocation.namedArguments[#onProgress]
                as void Function(SubmissionProgress)?;
        final firstCall = callCount == 1;
        onProgress?.call(
          SubmissionProgress(
            barcode: '123',
            step: firstCall ? SubmissionStep.failed : SubmissionStep.completed,
            errorCategory: firstCall
                ? SubmissionErrorCategory.network
                : SubmissionErrorCategory.none,
            retryAvailable: firstCall,
          ),
        );
        return const Product(barcode: '123', name: 'Test');
      });

      await pumpPushedForm(tester, service);
      await fillName(tester);
      await tester.tap(find.text('Submit to Open Food Facts'));
      await tester.pumpAndSettle();
      expect(find.text('Retry now'), findsOneWidget);

      await tester.tap(find.text('Retry now'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.byType(AddProductScreen), findsNothing);
    });
  });
}
