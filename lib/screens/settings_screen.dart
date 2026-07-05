import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A screen where the user can adjust application preferences.
///
/// Includes theme, notifications, data retention, and expiring‑soon
/// threshold settings, as well as a link to manage inventories.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen] widget.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(themeMode.name),
            leading: const Icon(Icons.brightness_6),
            onTap: () => _showThemeDialog(context, ref),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.expiryNotifications),
            subtitle: Text(l10n.remindBeforeExpiry),
            secondary: const Icon(Icons.notifications_active),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              logInfo('Notifications toggled: $value');
              final current = ref.read(settingsProvider);
              ref.read(settingsProvider.notifier).value = current.copyWith(
                notificationsEnabled: value,
              );
              if (context.mounted) {
                SnackbarHelper.showInfo(
                  context,
                  value
                      ? l10n.notificationsEnabled
                      : l10n.notificationsDisabled,
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.dataRetention),
            subtitle: Text(l10n.retentionDaysValue(settings.retentionDays)),
            leading: const Icon(Icons.timer),
            onTap: () => _showRetentionDialog(context, ref),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.expiringSoonDays),
            subtitle: Text(
              l10n.expiringSoonDaysValue(settings.expiringSoonDays),
            ),
            leading: const Icon(Icons.calendar_today),
            onTap: () => _showExpiringSoonDialog(context, ref),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.manageInventories),
            subtitle: Text(l10n.manageInventoriesSub),
            leading: const Icon(Icons.folder),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ManageInventoriesScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.flushCache),
            subtitle: Text(l10n.flushCacheSub),
            leading: const Icon(Icons.cleaning_services),
            onTap: () => _flushCache(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeModeOption>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chooseTheme),
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
        SnackbarHelper.showInfo(context, l10n.themeChanged(selected.name));
      }
    }
  }

  Future<void> _showRetentionDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final days = await _showDaysDialog(
      context,
      title: l10n.dataRetentionDialogTitle,
      initialValue: current.retentionDays,
    );
    if (days != null) {
      logInfo('Retention period changed to $days days');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        retentionDays: days,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(context, l10n.retentionPeriodSet(days));
      }
    }
  }

  Future<void> _showExpiringSoonDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final days = await _showDaysDialog(
      context,
      title: l10n.expiringSoonDaysDialogTitle,
      initialValue: current.expiringSoonDays,
    );
    if (days != null) {
      logInfo('Expiring soon threshold changed to $days days');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        expiringSoonDays: days,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(context, l10n.expiringSoonDaysSet(days));
      }
    }
  }

  Future<int?> _showDaysDialog(
    BuildContext context, {
    required String title,
    required int initialValue,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.daysLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(ctx, value);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _flushCache(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.flushCache),
        content: Text(l10n.flushCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.flushCache),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      logInfo('Flushing cache manually');
      await ImageCacheService().clearCache();
      await DatabaseHelper().clearCachedProducts();

      final isOnline = await InternetConnectionChecker.instance.hasConnection;
      if (isOnline) {
        logInfo('Online — re-fetching products for all inventories');
        final repo = ref.read(productRepositoryProvider);
        final db = ref.read(databaseProvider);
        final inventories = await db.getInventories();
        var totalRefreshed = 0;
        for (final inv in inventories) {
          final id = inv['id'] as int;
          totalRefreshed += await repo.refreshInventoryProducts(id);
        }
        logInfo('Re-fetched $totalRefreshed products after cache flush');
        ref.invalidate(inventoryWithProductProvider);
      } else {
        logInfo('Offline — products will appear with barcode as name');
        ref.invalidate(inventoryWithProductProvider);
      }

      if (context.mounted) {
        SnackbarHelper.showInfo(context, l10n.flushCacheSuccess);
      }
    } on Exception catch (e) {
      logError('Cache flush failed: $e');
      if (context.mounted) {
        SnackbarHelper.showError(context, l10n.flushCacheFailed);
      }
    }
  }
}
