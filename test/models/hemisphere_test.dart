import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/hemisphere.dart';

void main() {
  group('Hemisphere', () {
    test('has three values', () {
      expect(Hemisphere.values.length, 3);
      expect(Hemisphere.values, contains(Hemisphere.auto));
      expect(Hemisphere.values, contains(Hemisphere.northern));
      expect(Hemisphere.values, contains(Hemisphere.southern));
    });
  });
}
