import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import '../helpers/pump_app.dart';

FakeSettingsNotifier _visible() => FakeSettingsNotifier();
FakeSettingsNotifier _hidden() =>
    FakeSettingsNotifier(const Settings(pricesHidden: true));

/// A fake notifier that starts with the given [Settings].
class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier([this.initial = const Settings()]);

  final Settings initial;

  @override
  Future<Settings> build() async => initial;
}

void main() {
  testWidgets('shows visibility icon when prices are visible', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: PriceVisibilityToggle()),
      overrides: [
        settingsProvider.overrideWith(_visible),
      ],
    );

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });

  testWidgets('shows visibility_off icon when prices are hidden', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(body: PriceVisibilityToggle()),
      overrides: [
        settingsProvider.overrideWith(_hidden),
      ],
    );

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);
  });

  testWidgets('toggles pricesHidden on tap', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: PriceVisibilityToggle()),
      overrides: [
        settingsProvider.overrideWith(_visible),
      ],
    );

    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);
  });

  testWidgets('shows snackbar on toggle', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: PriceVisibilityToggle()),
      overrides: [
        settingsProvider.overrideWith(_visible),
      ],
    );

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.text('Prices hidden.'), findsOneWidget);
  });
}
