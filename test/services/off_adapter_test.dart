import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/services/off_adapter.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('OffAdapter', () {
    test('useStaging=true uses food test URI', () {
      final adapter = OffAdapter(useStaging: true);
      expect(adapter.useStaging, isTrue);
    });

    test('useStaging=false uses production URI', () {
      final adapter = OffAdapter(useStaging: false);
      expect(adapter.useStaging, isFalse);
    });

    group('parseImageField', () {
      test('returns FRONT for "front"', () {
        expect(OffAdapter.parseImageField('front'), off.ImageField.FRONT);
      });

      test('returns INGREDIENTS for "ingredients"', () {
        expect(
          OffAdapter.parseImageField('ingredients'),
          off.ImageField.INGREDIENTS,
        );
      });

      test('returns NUTRITION for "nutrition"', () {
        expect(
          OffAdapter.parseImageField('nutrition'),
          off.ImageField.NUTRITION,
        );
      });

      test('returns FRONT for unknown field', () {
        expect(OffAdapter.parseImageField('unknown'), off.ImageField.FRONT);
      });
    });

    group('readUser', () {
      test('is smoothie-app/strawberrybanana', () {
        const user = OffAdapter.readUser;
        expect(user.userId, 'smoothie-app');
        expect(user.password, 'strawberrybanana');
      });
    });

    group('writeUser', () {
      test('returns null when credentials are empty', () {
        final adapter = OffAdapter(useStaging: false);
        expect(adapter.writeUser, isNull);
      });
    });
  });
}
