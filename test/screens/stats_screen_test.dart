import 'package:filegate/filegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'; // Override
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/csv_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/filegate_provider.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/csv_service.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockCsvService extends Mock implements CsvService {}

class MockFilegate extends Mock implements Filegate {}

class FakeActiveInventoryNotifier extends Notifier<int>
    implements ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  int get value => state;

  @override
  set value(int id) => state = id;
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockCsvService mockCsv;
  late MockFilegate mockFilegate;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockCsv = MockCsvService();
    mockFilegate = MockFilegate();

    when(() => mockDb.getProductCount()).thenAnswer((_) async => 5);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 10);
  });

  List<Override> baseOverrides() => [
    databaseProvider.overrideWithValue(mockDb),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
    csvServiceProvider.overrideWithValue(mockCsv),
    filegateProvider.overrideWithValue(mockFilegate),
  ];

  testWidgets('shows product and inventory counts', (tester) async {
    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    expect(find.textContaining('Total products'), findsOneWidget);
    expect(find.textContaining('Inventory items'), findsOneWidget);
  });

  testWidgets('shows export and import buttons', (tester) async {
    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Export as CSV'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Import CSV'),
      findsOneWidget,
    );
  });

  testWidgets('displays count of zero', (tester) async {
    when(() => mockDb.getProductCount()).thenAnswer((_) async => 0);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 0);

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    expect(find.textContaining('Total products: 0'), findsOneWidget);
    expect(find.textContaining('Inventory items: 0'), findsOneWidget);
  });

  testWidgets('export with empty CSV shows info snackbar', (tester) async {
    when(
      () => mockCsv.generateCsv(inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => '');

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Export as CSV'));
    await tester.pumpAndSettle();

    expect(find.text('No data to export.'), findsOneWidget);
  });

  testWidgets('export with generateCsv throwing shows error snackbar', (
    tester,
  ) async {
    when(
      () => mockCsv.generateCsv(inventoryId: any(named: 'inventoryId')),
    ).thenThrow(Exception('fail'));

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Export as CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Export failed'), findsOneWidget);
  });

  testWidgets('import with null pick does nothing', (tester) async {
    when(
      () => mockFilegate.pickFiles(
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => null);

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Import CSV'));
    await tester.pumpAndSettle();

    // No snackbar and no crash — widget is still rendered.
    expect(find.byType(StatsScreen), findsOneWidget);
  });

  testWidgets('import with importCsvFromFile throwing shows error snackbar', (
    tester,
  ) async {
    when(
      () => mockFilegate.pickFiles(
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer(
      (_) async => [
        const PickedEntry(
          path: 'test.csv',
          name: 'test.csv',
          kind: PickedEntryKind.file,
        ),
      ],
    );
    when(
      () => mockCsv.importCsvFromFile(
        any(),
        inventoryId: any(named: 'inventoryId'),
        filegate: any(named: 'filegate'),
      ),
    ).thenThrow(Exception('fail'));

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Import CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CSV import failed'), findsOneWidget);
  });
}
