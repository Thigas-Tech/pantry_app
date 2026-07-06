import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('SettingsScreen golden', (tester) async {
    await pumpApp(tester, const SettingsScreen());

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
}
