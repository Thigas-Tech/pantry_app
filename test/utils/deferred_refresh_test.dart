import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/deferred_refresh.dart';

void main() {
  testWidgets('afterFrame does not run synchronously', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var ran = false;
    afterFrame(() => ran = true);

    expect(ran, isFalse);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(ran, isTrue);
  });

  testWidgets('afterFrame defers each action to the end of a frame', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    var first = false;
    var second = false;
    afterFrame(() => first = true);
    afterFrame(() => second = true);

    tester.binding.scheduleFrame();
    await tester.pump();
    expect(first, isTrue);
    expect(second, isTrue);
  });
}
