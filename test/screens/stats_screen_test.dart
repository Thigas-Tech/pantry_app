import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('renders without crashing', (tester) async {
    await pumpApp(tester, const StatsScreen(), settle: false);
    await tester.pump();
    expect(find.byType(StatsScreen), findsOneWidget);
  });
}
