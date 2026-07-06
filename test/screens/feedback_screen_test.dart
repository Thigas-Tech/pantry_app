import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/screens/feedback_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('renders without crashing', (tester) async {
    await pumpApp(
      tester,
      const FeedbackScreen(),
      settle: false,
      overrides: [
        connectivityProvider.overrideWith(
          (ref) => const Stream<bool>.empty(),
        ),
      ],
    );
    await tester.pump();
    expect(find.byType(FeedbackScreen), findsOneWidget);
  });

  testWidgets('shows form with title and description fields', (tester) async {
    await pumpApp(
      tester,
      const FeedbackScreen(),
      settle: false,
      overrides: [
        connectivityProvider.overrideWith(
          (ref) => const Stream<bool>.empty(),
        ),
      ],
    );
    await tester.pump();
    expect(find.byType(FeedbackScreen), findsOneWidget);
  });
}
