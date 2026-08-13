import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceId', () {
    test('generates and persists a UUID on first use', () async {
      SharedPreferences.setMockInitialValues({});

      final id = await DeviceId.get();

      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(DeviceId.storageKey), id);
    });

    test('returns the same id across calls', () async {
      SharedPreferences.setMockInitialValues({});

      final first = await DeviceId.get();
      final second = await DeviceId.get();

      expect(second, first);
    });

    test('respects an already stored id', () async {
      SharedPreferences.setMockInitialValues({
        'device_id': 'already-stored-id',
      });

      expect(await DeviceId.get(), 'already-stored-id');
    });
  });
}
