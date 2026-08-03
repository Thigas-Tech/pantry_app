import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/currency_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/feedback_screen.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/utils/changelog_loader.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                subtitle: Text(l10n.localizeThemeMode(themeMode.name)),
                onTap: () => _showThemeDialog(context, ref),
              ),
              SwitchListTile(
                title: Text(l10n.amoledDarkMode),
                subtitle: Text(l10n.amoledDarkModeExplanation),
                value: settings.amoledDarkMode,
                onChanged: (value) {
                  logInfo('AMOLED dark mode toggled: $value');
                  ref
                      .read(settingsProvider.notifier)
                      .setAmoledDarkMode(value: value);

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
            leading: const Icon(Icons.straighten),
            title: Text(l10n.units),
            children: [
              RadioGroup<UnitSystem>(
                groupValue: settings.unitSystem,
                onChanged: (v) {
                  if (v != null) {
                    logInfo('Unit system changed to: ${v.name}');
                    ref.read(settingsProvider.notifier).setUnitSystem(v);
                    if (context.mounted) {
                      SnackbarHelper.showInfo(
                        context,
                        l10n.unitSystemChanged(
                          v == UnitSystem.metric
                              ? l10n.unitSystemMetric
                              : l10n.unitSystemImperial,
                        ),
                      );
                    }
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<UnitSystem>(
                      title: Text(l10n.unitSystemMetric),
                      value: UnitSystem.metric,
                    ),
                    RadioListTile<UnitSystem>(
                      title: Text(l10n.unitSystemImperial),
                      value: UnitSystem.imperial,
                    ),
                  ],
                ),
              ),
              const Divider(),
              ExpansionTile(
                title: Text(l10n.perContextOverrides),
                leading: const Icon(Icons.swap_horiz),
                    children: [
                  _contextOverrideTile(
                    context,
                    l10n: l10n,
                    label: l10n.servingSizeContext,
                    value: settings.unitSystemServingSize,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setUnitSystemServingSize(v);
                    },
                  ),
                  _contextOverrideTile(
                    context,
                    l10n: l10n,
                    label: l10n.recipeIngredientsContext,
                    value: settings.unitSystemRecipeIngredients,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setUnitSystemRecipeIngredients(v);
                    },
                  ),
                  _contextOverrideTile(
                    context,
                    l10n: l10n,
                    label: l10n.inventoryContext,
                    value: settings.unitSystemInventory,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setUnitSystemInventory(v);
                    },
                  ),
                ],
              ),
              if (_usesImperialInAnyContext(settings)) ...[
                const Divider(),
                ExpansionTile(
                  title: Text(l10n.imperialPreferences),
                  leading: const Icon(Icons.tune),
                  initiallyExpanded: true,
                  children: [
                    ListTile(
                      title: Text(l10n.weightPreference),
                      subtitle: Text(
                        _weightPrefLabel(settings.preferredWeightUnit, l10n),
                      ),
                      onTap: () => _showWeightPrefDialog(context, ref),
                    ),
                    ListTile(
                      title: Text(l10n.volumePreference),
                      subtitle: Text(
                        _volumePrefLabel(settings.preferredVolumeUnit, l10n),
                      ),
                      onTap: () => _showVolumePrefDialog(context, ref),
                    ),
                  ],
                ),
              ],
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
                  if (!context.mounted) return;
                  final proceed = await _showPermissionRationaleIfNeeded(
                    context,
                    l10n,
                  );
                  if (!proceed) return;
                  final notifService = ref.read(notificationServiceProvider);
                  final granted = await notifService.requestPermission();
                  if (granted != false) {
                    await notifService.showTestNotification(
                      title: l10n.testNotificationTitle,
                      body: l10n.testNotificationBody,
                      channelName: l10n.generalNotificationChannelName,
                      channelDescription:
                          l10n.generalNotificationChannelDescription,
                    );
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
                subtitle: FutureBuilder<bool?>(
                  future: ref
                      .read(notificationServiceProvider)
                      .canScheduleExactNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.data == false) {
                      return Text(
                        l10n.exactAlarmsDeniedHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                onTap: () async {
                  if (!context.mounted) return;
                  final proceed = await _showPermissionRationaleIfNeeded(
                    context,
                    l10n,
                  );
                  if (!proceed) return;
                  final notifService = ref.read(notificationServiceProvider);
                  final granted = await notifService.requestPermission();
                  if (granted != false) {
                    await notifService.scheduleTestNotification(
                      title: l10n.testScheduledTitle,
                      body: l10n.testScheduledBody,
                      channelName: l10n.generalNotificationChannelName,
                      channelDescription:
                          l10n.generalNotificationChannelDescription,
                    );
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
                    if (!context.mounted) return;
                    final proceed = await _showPermissionRationaleIfNeeded(
                      context,
                      l10n,
                    );
                    if (!proceed) return;
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
                    // Reschedule all items when re-enabled
                    unawaited(_rescheduleAllItems(ref, l10n));
                  } else {
                    final notifService = ref.read(
                      notificationServiceProvider,
                    );
                    await notifService.cancelAllReminders();
                  }
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(value: value);

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
                    if (!context.mounted) return;
                    final proceed = await _showPermissionRationaleIfNeeded(
                      context,
                      l10n,
                    );
                    if (!proceed) return;
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
                  ref
                      .read(settingsProvider.notifier)
                      .setInactivityReminderEnabled(value: value);

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
                  ref
                      .read(settingsProvider.notifier)
                      .setPriceTrackingEnabled(value: value);

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
                  ref
                      .read(settingsProvider.notifier)
                      .setPricesHidden(value: value);

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
                  ref
                      .read(settingsProvider.notifier)
                      .setOpenPricesSyncEnabled(value: value);
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
                          _formatBytes(snapshot.data!, l10n),
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
                          title: Text(l10n.pendingFeedback(count)),
                          trailing: TextButton(
                            onPressed: () async {
                              final result = await service.flushQueue();
                              if (context.mounted) {
                                SnackbarHelper.showInfo(
                                  context,
                                  l10n.submissionResult(
                                    result.failed,
                                    result.submitted,
                                  ),
                                );
                              }
                            },
                            child: Text(l10n.retryNow),
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

  Widget _contextOverrideTile(
    BuildContext context, {
    required AppLocalizations l10n,
    required String label,
    required UnitSystem? value,
    required void Function(UnitSystem?) onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(_overrideLabel(value, l10n)),
      onTap: () => _showOverrideDialog(
        context,
        l10n,
        label,
        value,
        onChanged,
      ),
    );
  }

  String _overrideLabel(UnitSystem? value, AppLocalizations l10n) {
    if (value == null) return l10n.systemDefault;
    return value == UnitSystem.metric
        ? l10n.unitSystemMetric
        : l10n.unitSystemImperial;
  }

  Future<void> _showOverrideDialog(
    BuildContext context,
    AppLocalizations l10n,
    String label,
    UnitSystem? current,
    void Function(UnitSystem?) onChanged,
  ) async {
    final result = await showDialog<UnitSystem?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(label),
        children: [
          RadioGroup<UnitSystem?>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<UnitSystem?>(
                  title: Text(l10n.systemDefault),
                  value: null,
                ),
                RadioListTile<UnitSystem?>(
                  title: Text(l10n.unitSystemMetric),
                  value: UnitSystem.metric,
                ),
                RadioListTile<UnitSystem?>(
                  title: Text(l10n.unitSystemImperial),
                  value: UnitSystem.imperial,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != current && context.mounted) {
      onChanged(result);
    }
  }

  bool _usesImperialInAnyContext(Settings settings) {
    if (settings.unitSystem == UnitSystem.imperial) return true;
    if (settings.unitSystemServingSize == UnitSystem.imperial) return true;
    if (settings.unitSystemRecipeIngredients == UnitSystem.imperial) {
      return true;
    }
    if (settings.unitSystemInventory == UnitSystem.imperial) return true;
    return false;
  }

  String _weightPrefLabel(
    WeightUnitPreference pref,
    AppLocalizations l10n,
  ) {
    switch (pref) {
      case WeightUnitPreference.ounces:
        return l10n.weightOz;
      case WeightUnitPreference.pounds:
        return l10n.weightLb;
      case WeightUnitPreference.auto:
        return l10n.weightAuto;
    }
  }

  String _volumePrefLabel(
    VolumeUnitPreference pref,
    AppLocalizations l10n,
  ) {
    switch (pref) {
      case VolumeUnitPreference.fluidOunces:
        return l10n.volumeFlOz;
      case VolumeUnitPreference.cups:
        return l10n.volumeCup;
      case VolumeUnitPreference.tablespoons:
        return l10n.volumeTbsp;
      case VolumeUnitPreference.teaspoons:
        return l10n.volumeTsp;
      case VolumeUnitPreference.auto:
        return l10n.volumeAuto;
    }
  }

  Future<void> _showWeightPrefDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(settingsProvider).preferredWeightUnit;
    final result = await showDialog<WeightUnitPreference>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SimpleDialog(
          title: Text(l10n.weightPreference),
          children: [
            RadioGroup<WeightUnitPreference>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<WeightUnitPreference>(
                    title: Text(l10n.weightOz),
                    value: WeightUnitPreference.ounces,
                  ),
                  RadioListTile<WeightUnitPreference>(
                    title: Text(l10n.weightLb),
                    value: WeightUnitPreference.pounds,
                  ),
                  RadioListTile<WeightUnitPreference>(
                    title: Text(l10n.weightAuto),
                    value: WeightUnitPreference.auto,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (result != null && context.mounted) {
      ref.read(settingsProvider.notifier).setPreferredWeightUnit(result);
    }
  }

  Future<void> _showVolumePrefDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(settingsProvider).preferredVolumeUnit;
    final result = await showDialog<VolumeUnitPreference>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SimpleDialog(
          title: Text(l10n.volumePreference),
          children: [
            RadioGroup<VolumeUnitPreference>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<VolumeUnitPreference>(
                    title: Text(l10n.volumeFlOz),
                    value: VolumeUnitPreference.fluidOunces,
                  ),
                  RadioListTile<VolumeUnitPreference>(
                    title: Text(l10n.volumeCup),
                    value: VolumeUnitPreference.cups,
                  ),
                  RadioListTile<VolumeUnitPreference>(
                    title: Text(l10n.volumeTbsp),
                    value: VolumeUnitPreference.tablespoons,
                  ),
                  RadioListTile<VolumeUnitPreference>(
                    title: Text(l10n.volumeTsp),
                    value: VolumeUnitPreference.teaspoons,
                  ),
                  RadioListTile<VolumeUnitPreference>(
                    title: Text(l10n.volumeAuto),
                    value: VolumeUnitPreference.auto,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (result != null && context.mounted) {
      ref.read(settingsProvider.notifier).setPreferredVolumeUnit(result);
    }
  }

  Future<void> _showWhatsNew(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final raw = await loadLocalizedChangelog(
        Localizations.localeOf(context),
      );
      if (!context.mounted) return;

      await showWhatsNewSheet(context, rawChangelog: raw);
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
                  title: Text(l10n.localizeThemeMode(option.name)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      logInfo('Theme changed to ${selected.name}');
      ref.read(themeModeProvider.notifier).setThemeMode(selected);

      if (context.mounted) {
        SnackbarHelper.showInfo(
          context,
          l10n.themeChanged(l10n.localizeThemeMode(selected.name)),
        );
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
      ref.read(settingsProvider.notifier).setRetentionDays(days);

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
      ref.read(settingsProvider.notifier).setExpiringSoonDays(days);

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
      ref.read(settingsProvider.notifier).setBaseCurrency(selected);

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
      ref.read(settingsProvider.notifier).setPriceRetentionDays(days);

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
          decoration: InputDecoration(
            hintText: l10n.bearerTokenLabel,
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
      ref.read(settingsProvider.notifier).setOpenPricesToken(result);

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
      ref.read(settingsProvider.notifier).setInactivityThresholdDays(days);

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
          ref.invalidate(pantryProvider);
        });
      } else {
        logInfo('Offline — products will appear with barcode as name');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(pantryProvider);
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

  /// Reschedules all expiry reminders for every inventory item.
  Future<void> _rescheduleAllItems(
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      final notifService = ref.read(notificationServiceProvider);
      final db = DatabaseHelper();
      final database = await db.database;
      final inventories = await db.getInventories();
      final items = <InventoryItem>[];
      for (final inv in inventories) {
        final invItems = await db.inventoryDao.list(
          database,
          inventoryId: inv['id'] as int,
        );
        items.addAll(invItems);
      }
      final settings = ref.read(settingsProvider);
      await notifService.rescheduleAllItems(
        items,
        expiringSoonTitle: l10n.expiringSoon,
        expiringTodayTitle: l10n.expiringToday,
        buildExpiringSoonBody: l10n.expiresTomorrow,
        buildExpiringTodayBody: l10n.expiresToday,
        notificationsEnabled: settings.notificationsEnabled,
      );
    } on Exception catch (e) {
      logError('Failed to reschedule notifications on toggle: $e');
    }
  }

  /// Shows the notification rationale dialog on first permission request.
  ///
  /// Returns true if the user tapped "Allow" (or rationale was already
  /// shown), false if the user tapped "Not now".
  Future<bool> _showPermissionRationaleIfNeeded(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('notification_rationale_shown') == true;
    if (alreadyShown) return true;
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationRationaleTitle),
        content: Text(l10n.notificationRationaleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notificationRationaleNotNow),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.notificationRationaleAllow),
          ),
        ],
      ),
    );

    await prefs.setBool('notification_rationale_shown', true);
    return result ?? false;
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

String _formatBytes(int bytes, AppLocalizations l10n) {
  if (bytes < 1024) return l10n.bytesUnit(bytes);
  if (bytes < 1024 * 1024) {
    return l10n.kbUnit((bytes / 1024).toStringAsFixed(1));
  }
  return l10n.mbUnit((bytes / (1024 * 1024)).toStringAsFixed(1));
}
