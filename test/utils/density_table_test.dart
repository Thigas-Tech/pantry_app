import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/density_table.dart';

void main() {
  group('DensityTable.gramsPerMilliliter', () {
    test('returns the known density for oil', () {
      expect(DensityTable.gramsPerMilliliter('olive oil'), 0.91);
      expect(DensityTable.gramsPerMilliliter('Canola Oil'), 0.92);
    });

    test('returns the known density for honey and flour', () {
      expect(DensityTable.gramsPerMilliliter('honey'), 1.42);
      expect(DensityTable.gramsPerMilliliter('all purpose flour'), 0.59);
    });

    test('matches by substring within a longer ingredient name', () {
      expect(DensityTable.gramsPerMilliliter('unsalted butter'), 0.92);
    });

    test('defaults to water density for unknown ingredients', () {
      expect(DensityTable.gramsPerMilliliter('milk'), 1.0);
      expect(DensityTable.gramsPerMilliliter(''), 1.0);
    });
  });
}
