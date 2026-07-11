import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/currency_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/feedback_screen.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/services/changelog_parser.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

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
          ExpansionTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.settingsAppearance),
            initiallyExpanded: true,
            children: [
              ListTile(
                title: Text(l10n.theme),
                subtitle: Text(themeMode.name),
                onTap: () => _showThemeDialog(context, ref),
              ),
              SwitchListTile(
                title: Text(l10n.amoledDarkMode),
                subtitle: Text(l10n.amoledDarkModeExplanation),
                value: settings.amoledDarkMode,
                onChanged: (value) {
                  logInfo('AMOLED dark mode toggled: $value');
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).value = current.copyWith(
                    amoledDarkMode: value,
                  );
                  if (context.mounted) {
                    SnackbarHelper.showInfo(
                      context,
                      value
                          ? l10n.amoledDarkModeEnabled
                          : l10n.amoledDarkModeDisabled,
                    );
                  }
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.notifications_active),
            title: Text(l10n.expiryNotifications),
            initiallyExpanded: true,
            children: [
              ListTile(
                title: Text(l10n.testNotification),
                onTap: () async {
                  final notifService = ref.read(notificationServiceProvider);
                  final granted = await notifService.requestPermission();
                  if (granted != false) {
                    await notifService.showTestNotification();
                    if (context.mounted) {
                      SnackbarHelper.showInfo(
                        context,
                        l10n.testNotificationSent,
                      );
                    }
                  }
                },
              ),
              ListTile(
                title: Text(l10n.testScheduledNotification),
                onTap: () async {
                  final notifService = ref.read(notificationServiceProvider);
                  final granted = await notifService.requestPermission();
                  if (granted != false) {
                    await notifService.scheduleTestNotification();
                    if (context.mounted) {
                      SnackbarHelper.showInfo(
                        context,
                        l10n.testNotificationScheduled,
                      );
                    }
                  }
                },
              ),
              SwitchListTile(
                title: Text(l10n.remindBeforeExpiry),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  logInfo('Notifications toggled: $value');
                  if (value) {
                    final notifService = ref.read(
                      notificationServiceProvider,
                    );
                    final granted = await notifService.requestPermission();
                    if (granted == false) {
                      if (context.mounted) {
                        await _showPermissionDeniedDialog(
                          context,
                          l10n,
                        );
                      }
                      return;
                    }
                  } else {
                    final notifService = ref.read(
                      notificationServiceProvider,
                    );
                    await notifService.cancelAllReminders();
                  }
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
              SwitchListTile(
                title: Text(l10n.inactivityReminderEnabled),
                value: settings.inactivityReminderEnabled,
                onChanged: (value) async {
                  logInfo('Inactivity reminder toggled: $value');
                  final notifService = ref.read(
                    notificationServiceProvider,
                  );
                  if (value) {
                    final granted = await notifService.requestPermission();
                    if (granted == false) {
                      if (context.mounted) {
                        await _showPermissionDeniedDialog(
                          context,
                          l10n,
                        );
                      }
                      return;
                    }
                  } else {
                    await notifService.cancelInactivityReminder();
                  }
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).value = current.copyWith(
                    inactivityReminderEnabled: value,
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
              ListTile(
                title: Text(l10n.inactivityThresholdDays),
                subtitle: Text(
                  l10n.expiringSoonDaysValue(settings.inactivityThresholdDays),
                ),
                onTap: () => _showInactivityThresholdDialog(context, ref),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.timer),
            title: Text(l10n.settingsDataManagement),
            children: [
              ListTile(
                title: Text(l10n.dataRetention),
                subtitle: Text(
                  l10n.retentionDaysValue(settings.retentionDays),
                ),
                onTap: () => _showRetentionDialog(context, ref),
              ),
              ListTile(
                title: Text(l10n.expiringSoonDays),
                subtitle: Text(
                  l10n.expiringSoonDaysValue(settings.expiringSoonDays),
                ),
                onTap: () => _showExpiringSoonDialog(context, ref),
              ),
              ListTile(
                title: Text(l10n.manageInventories),
                subtitle: Text(l10n.manageInventoriesSub),
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
          ExpansionTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.priceTracking),
            children: [
              SwitchListTile(
                title: Text(l10n.priceTrackingEnabled),
                value: settings.priceTrackingEnabled,
                onChanged: (value) {
                  logInfo('Price tracking toggled: $value');
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).value = current.copyWith(
                    priceTrackingEnabled: value,
                  );
                  if (context.mounted) {
                    SnackbarHelper.showInfo(
                      context,
                      value ? l10n.pricesVisible : l10n.pricesHidden,
                    );
                  }
                },
              ),
              ListTile(
                title: Text(l10n.baseCurrency),
                subtitle: Text(settings.baseCurrency),
                onTap: () => _showCurrencyPicker(context, ref),
              ),
              ListTile(
                title: Text(l10n.priceRetentionDays),
                subtitle: Text(
                  l10n.priceRetentionDaysValue(settings.priceRetentionDays),
                ),
                onTap: () => _showPriceRetentionDialog(context, ref),
              ),
              SwitchListTile(
                title: Text(l10n.hidePrices),
                subtitle: Text(l10n.hidePricesDescription),
                value: settings.pricesHidden,
                onChanged: (value) {
                  logInfo('Prices hidden toggled: $value');
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).value = current.copyWith(
                    pricesHidden: value,
                  );
                  if (context.mounted) {
                    SnackbarHelper.showInfo(
                      context,
                      value ? l10n.pricesHidden : l10n.pricesVisible,
                    );
                  }
                },
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.syncToOpenPrices),
                subtitle: Text(l10n.syncToOpenPricesDescription),
                value: settings.openPricesSyncEnabled,
                onChanged: (value) async {
                  if (value) {
                    final consent = await _showOpenPricesConsentDialog(
                      context,
                      l10n,
                    );
                    if (consent != true) return;
                  }
                  logInfo('Open Prices sync toggled: $value');
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).value = current.copyWith(
                    openPricesSyncEnabled: value,
                  );
                },
              ),
              if (settings.openPricesSyncEnabled) ...[
                ListTile(
                  title: Text(l10n.openPricesToken),
                  subtitle: Text(l10n.openPricesTokenDescription),
                  onTap: () => _showOpenPricesTokenDialog(context, ref),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.openPricesProofExplanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.cleaning_services),
            title: Text(l10n.settingsMaintenance),
            children: [
              ListTile(
                title: Text(l10n.flushCache),
                subtitle: Text(l10n.flushCacheSub),
                trailing: Consumer(
                  builder: (context, ref, child) {
                    return FutureBuilder<int>(
                      future: ref
                          .read(currencyServiceProvider)
                          .cacheSizeBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatBytes(snapshot.data!),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        );
                      },
                    );
                  },
                ),
                onTap: () => _flushCache(context, ref),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            children: [
              ListTile(
                title: Text(l10n.whatsNewTitle),
                subtitle: Text(l10n.whatsNewDismiss),
                onTap: () => _showWhatsNew(context),
              ),
              if (AppConfig.feedbackEnabled)
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l10n.sendFeedback),
                  onTap: () => _sendFeedback(context),
                ),
              if (AppConfig.feedbackEnabled)
                Consumer(
                  builder: (context, ref, _) {
                    final service = ref.watch(githubIssueServiceProvider);
                    return FutureBuilder<int>(
                      future: service.pendingCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return ListTile(
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: Text('Pending feedback: $count'),
                          trailing: TextButton(
                            onPressed: () async {
                              final result = await service.flushQueue();
                              if (context.mounted) {
                                SnackbarHelper.showInfo(
                                  context,
                                  'Submitted ${result.submitted}, '
                                  '${result.failed} failed',
                                );
                              }
                            },
                            child: const Text('Retry now'),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showWhatsNew(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final raw = await rootBundle.loadString('CHANGELOG.md');
      if (!context.mounted) return;
      final parser = ChangelogParser();
      final allEntries = parser.parse(raw);

      if (allEntries.isEmpty) {
        SnackbarHelper.showInfo(context, l10n.whatsNewDismiss);
        return;
      }

      if (!context.mounted) return;
      await showWhatsNewSheet(context, allEntries);
    } on Exception catch (e) {
      logError('Failed to show changelog from settings: $e');
      if (context.mounted) {
        SnackbarHelper.showError(context, l10n.flushCacheFailed);
      }
    }
  }

  void _sendFeedback(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const FeedbackScreen(),
        ),
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

  Future<void> _showCurrencyPicker(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final currencies = [
      'USD',
      'BRL',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'CHF',
      'CNY',
      'INR',
      'MXN',
      'ARS',
      'CLP',
      'COP',
      'ZAR',
      'NGN',
      'TRY',
      'ILS',
      'SGD',
      'HKD',
      'TWD',
      'KRW',
      'SEK',
      'NOK',
      'DKK',
      'PLN',
      'CZK',
      'RUB',
      'THB',
      'MYR',
      'PHP',
      'IDR',
      'VND',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.baseCurrency),
        children: [
          SizedBox(
            height: 320,
            width: 240,
            child: RadioGroup<String>(
              groupValue: current.baseCurrency,
              onChanged: (value) => Navigator.pop(ctx, value),
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (ctx, i) => RadioListTile<String>(
                  value: currencies[i],
                  title: Text(currencies[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current.baseCurrency) {
      logInfo('Base currency changed to $selected');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        baseCurrency: selected,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(
          context,
          '${l10n.currency}: $selected',
        );
      }
    }
  }

  Future<void> _showPriceRetentionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final days = await _showDaysDialog(
      context,
      title: l10n.priceRetentionDays,
      initialValue: current.priceRetentionDays,
    );
    if (days != null) {
      logInfo('Price retention changed to $days days');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        priceRetentionDays: days,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(
          context,
          l10n.priceRetentionDaysValue(days),
        );
      }
    }
  }

  Future<bool?> _showOpenPricesConsentDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.openPricesConsentTitle),
        content: Text(l10n.openPricesConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.iUnderstand),
          ),
        ],
      ),
    );
  }

  Future<void> _showOpenPricesTokenDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final controller = TextEditingController(text: current.openPricesToken);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.openPricesToken),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Bearer token',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null) {
      logInfo('Open Prices API token updated');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        openPricesToken: result,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(context, l10n.openPricesTokenSaved);
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

  Future<void> _showInactivityThresholdDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider);
    final days = await _showDaysDialog(
      context,
      title: l10n.inactivityThresholdDays,
      initialValue: current.inactivityThresholdDays,
    );
    if (days != null) {
      logInfo('Inactivity threshold changed to $days days');
      ref.read(settingsProvider.notifier).value = current.copyWith(
        inactivityThresholdDays: days,
      );
      if (context.mounted) {
        SnackbarHelper.showInfo(
          context,
          l10n.inactivityThresholdSet(days),
        );
      }
    }
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
      await ref.read(imageCacheProvider).clearCache();
      await ref.read(databaseProvider).clearCachedProducts();

      final isOnline = await ref.read(hasConnectionProvider.future);
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
        await repo.setLastRefreshTime();
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryWithProductProvider);
        });
      } else {
        logInfo('Offline — products will appear with barcode as name');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryWithProductProvider);
        });
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

  /// Shows a dialog explaining that notification permission was denied
  /// and offering to open the device settings.
  Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationPermissionTitle),
        content: Text(l10n.notificationPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    if (result == true) {
      await openAppSettings();
    }
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
