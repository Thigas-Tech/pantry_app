import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/widgets/recent_scans_section.dart';
import '../helpers/pump_app.dart';

void main() {
  const milk = ScanHistoryEntry(
    id: 1,
    barcode: '1',
    name: 'Milk',
    scannedAt: 1000,
    imageUrl: 'https://example.com/milk.jpg',
  );
  const bread = ScanHistoryEntry(
    id: 2,
    barcode: '2',
    name: 'Bread',
    scannedAt: 900,
  );

  testWidgets('renders the header and each entry name', (tester) async {
    await pumpApp(
      tester,
      RecentScansSection(
        entries: const [milk, bread],
        onQuickAdd: (_) {},
        onTapEntry: (_) {},
      ),
    );

    expect(find.text('Recent scans'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('shows a quick-add button per entry', (tester) async {
    await pumpApp(
      tester,
      RecentScansSection(
        entries: const [milk, bread],
        onQuickAdd: (_) {},
        onTapEntry: (_) {},
      ),
    );

    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
  });

  testWidgets('quick-add invokes the callback with the entry', (tester) async {
    final added = <ScanHistoryEntry>[];
    await pumpApp(
      tester,
      RecentScansSection(
        entries: const [milk, bread],
        onQuickAdd: added.add,
        onTapEntry: (_) {},
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    expect(added, hasLength(1));
    expect(added.single.barcode, '1');
  });

  testWidgets('tapping a card invokes onTapEntry', (tester) async {
    final opened = <ScanHistoryEntry>[];
    await pumpApp(
      tester,
      RecentScansSection(
        entries: const [milk, bread],
        onQuickAdd: (_) {},
        onTapEntry: opened.add,
      ),
    );

    await tester.tap(find.text('Bread'));
    expect(opened, hasLength(1));
    expect(opened.single.barcode, '2');
  });

  testWidgets('renders a fallback icon when imageUrl is null', (tester) async {
    await pumpApp(
      tester,
      RecentScansSection(
        entries: const [bread],
        onQuickAdd: (_) {},
        onTapEntry: (_) {},
      ),
    );

    expect(find.byIcon(Icons.fastfood), findsOneWidget);
  });
}
