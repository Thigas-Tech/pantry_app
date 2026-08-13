import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/ui_flags_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UiFlagsNotifier', () {
    test('defaults every flag to false', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flags = await container.read(uiFlagsProvider.future);

      expect(flags.notificationDeniedWarning, isFalse);
      expect(flags.amoledNudgeShown, isFalse);
      expect(flags.changelogShowPending, isFalse);
      expect(flags.notificationRationaleShown, isFalse);
    });

    test('loads persisted flags', () async {
      SharedPreferences.setMockInitialValues({
        'notification_denied_warning': true,
        'amoled_nudge_shown': true,
        'changelog_show_pending': 'true',
        'notification_rationale_shown': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flags = await container.read(uiFlagsProvider.future);

      expect(flags.notificationDeniedWarning, isTrue);
      expect(flags.amoledNudgeShown, isTrue);
      expect(flags.changelogShowPending, isTrue);
      expect(flags.notificationRationaleShown, isTrue);
    });

    test('setters persist to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(uiFlagsProvider.notifier)
          .setNotificationDeniedWarning(
            value: true,
          );
      container.read(uiFlagsProvider.notifier).setAmoledNudgeShown(value: true);
      container
          .read(uiFlagsProvider.notifier)
          .setChangelogShowPending(
            value: true,
          );
      container
          .read(uiFlagsProvider.notifier)
          .setNotificationRationaleShown(value: true);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notification_denied_warning'), isTrue);
      expect(prefs.getBool('amoled_nudge_shown'), isTrue);
      expect(prefs.getString('changelog_show_pending'), 'true');
      expect(prefs.getBool('notification_rationale_shown'), isTrue);
    });

    test('a new container reads the persisted values back', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ProviderContainer();
      addTearDown(first.dispose);
      first.read(uiFlagsProvider.notifier).setAmoledNudgeShown(value: true);
      await Future<void>.delayed(Duration.zero);

      final second = ProviderContainer();
      addTearDown(second.dispose);
      final flags = await second.read(uiFlagsProvider.future);

      expect(flags.amoledNudgeShown, isTrue);
    });
  });
}
