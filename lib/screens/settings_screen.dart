import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A screen where the user can adjust application preferences.
///
/// - **Theme**: choose between system, light, or dark mode.
/// - **Notifications**: enable or disable expiry reminders.
/// - **Data retention**: set how many days before old items are cleaned up.
/// - **Manage Inventories**: create, rename, or delete pantries.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen] widget.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeMode.name),
            leading: const Icon(Icons.brightness_6),
            onTap: () => _showThemeDialog(context, ref),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Expiry notifications'),
            subtitle: const Text('Remind before food expires'),
            secondary: const Icon(Icons.notifications_active),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              logInfo('Notifications toggled: $value');
              ref.read(settingsProvider.notifier).value = Settings(
                notificationsEnabled: value,
              );
              if (context.mounted) {
                SnackbarHelper.showInfo(
                  context,
                  value ? 'Notifications enabled.' : 'Notifications disabled.',
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Data retention'),
            subtitle: Text('${settings.retentionDays} days'),
            leading: const Icon(Icons.timer),
            onTap: () => _showRetentionDialog(context, ref),
          ),
          const Divider(),

          /// Opens the [ManageInventoriesScreen] where the user can create,
          /// rename, or delete pantries.
          ListTile(
            title: const Text('Manage Inventories'),
            subtitle: const Text('Create, rename, or delete pantries'),
            leading: const Icon(Icons.folder),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ManageInventoriesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shows a dialog with the three theme options.
  ///
  /// When the user picks a theme, [themeModeProvider] is updated and the
  /// entire app rebuilds with the new theme.
  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeModeOption>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose theme'),
        children: [
          RadioGroup<ThemeModeOption>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(ctx, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ThemeModeOption.values.map((option) {
                return RadioListTile<ThemeModeOption>(
                  value: option,
                  title: Text(option.name),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      logInfo('Theme changed to ${selected.name}');
      ref.read(themeModeProvider.notifier).value = selected;
      if (context.mounted) {
        SnackbarHelper.showInfo(context, 'Theme: ${selected.name}');
      }
    }
  }

  /// Shows a dialog that lets the user type a new retention period in days.
  ///
  /// The value must be a positive integer. If the user enters a valid value
  /// and taps Save, [settingsProvider] is updated.
  Future<void> _showRetentionDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).retentionDays.toString(),
    );
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data retention (days)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '60',
            labelText: 'Days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (days != null) {
      logInfo('Retention period changed to $days days');
      ref.read(settingsProvider.notifier).value = Settings(retentionDays: days);
      if (context.mounted) {
        SnackbarHelper.showInfo(
          context,
          'Retention period set to $days days.',
        );
      }
    }
  }
}
