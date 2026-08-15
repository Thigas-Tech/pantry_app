import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/cache_staleness_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CacheStalenessStore', () {
    test('lastRefresh is null when nothing has been recorded', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CacheStalenessStore(prefs);
      expect(await store.lastRefresh(), isNull);
    });

    test('recordRefresh stores the injected now time', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 1, 1, 12);
      final store = CacheStalenessStore(prefs, now: () => now);
      await store.recordRefresh();
      expect(await store.lastRefresh(), now);
    });

    test('isOverdue is true when nothing has been recorded', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CacheStalenessStore(prefs);
      expect(await store.isOverdue(const Duration(days: 5)), isTrue);
    });

    test(
      'isOverdue is false when the last refresh is within the window',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final base = DateTime(2026, 1, 1, 12);
        await CacheStalenessStore(prefs, now: () => base).recordRefresh();
        final store = CacheStalenessStore(
          prefs,
          now: () => base.add(const Duration(days: 4)),
        );
        expect(await store.isOverdue(const Duration(days: 5)), isFalse);
      },
    );

    test(
      'isOverdue is true when the last refresh is older than the window',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final base = DateTime(2026, 1, 1, 12);
        await CacheStalenessStore(prefs, now: () => base).recordRefresh();
        final store = CacheStalenessStore(
          prefs,
          now: () => base.add(const Duration(days: 6)),
        );
        expect(await store.isOverdue(const Duration(days: 5)), isTrue);
      },
    );

    test('isOverdue is true exactly at the window boundary', () async {
      final prefs = await SharedPreferences.getInstance();
      final base = DateTime(2026, 1, 1, 12);
      await CacheStalenessStore(prefs, now: () => base).recordRefresh();
      final store = CacheStalenessStore(
        prefs,
        now: () => base.add(const Duration(days: 5)),
      );
      expect(await store.isOverdue(const Duration(days: 5)), isTrue);
    });
  });
}
