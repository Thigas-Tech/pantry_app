import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/widgets/produce_search_sheet.dart';

import '../helpers/pump_app.dart';

class _MockUsdaApiClient extends Mock implements UsdaApiClient {}

class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              await ProduceSearchSheet.show(ctx);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

void main() {
  late _MockUsdaApiClient mockUsda;

  setUp(() {
    mockUsda = _MockUsdaApiClient();
    when(() => mockUsda.searchFood(any())).thenAnswer((_) async => []);
  });

  Future<void> showSheet(WidgetTester tester) async {
    await pumpApp(
      tester,
      const _SheetHost(),
      overrides: [
        usdaApiClientProvider.overrideWithValue(mockUsda),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> doSearch(WidgetTester tester, String query) async {
    await showSheet(tester);
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  }

  testWidgets('empty query does not call the USDA API', (tester) async {
    await showSheet(tester);
    verifyNever(() => mockUsda.searchFood(any()));
  });

  testWidgets('shows search hint before any query', (tester) async {
    await showSheet(tester);
    expect(find.text('Search by name or barcode'), findsOneWidget);
  });

  testWidgets('shows results after a query', (tester) async {
    when(() => mockUsda.searchFood('tomato')).thenAnswer(
      (_) async => const [Product(barcode: 'plu-1', name: 'Tomato')],
    );
    await doSearch(tester, 'tomato');
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('shows not-found state when no results', (tester) async {
    await doSearch(tester, 'zzzz');
    expect(
      find.text('No produce found. Try a different name.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a result closes the sheet', (tester) async {
    when(() => mockUsda.searchFood('banana')).thenAnswer(
      (_) async => const [Product(barcode: 'plu-2', name: 'Banana')],
    );
    await doSearch(tester, 'banana');
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(find.byType(ProduceSearchSheet), findsNothing);
  });
}
