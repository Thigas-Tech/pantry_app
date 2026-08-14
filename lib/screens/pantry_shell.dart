import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/providers/ui_flags_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/shopping_list_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/utils/changelog_loader.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';

/// The root shell that holds the [NavigationBar] and switches between
/// the main app screens.
///
/// Tabs:
/// - **Home** — inventory dashboard with grouping by expiry status.
/// - **Recipes** — saved recipes with cost tracking.
/// - **Stats** — inventory statistics.
/// - **List** — shopping list of items to buy.
/// - **Settings** — application preferences.
///
/// Uses a [PageView] so that users can swipe horizontally between tabs.
/// Each tab uses [AutomaticKeepAliveClientMixin] to preserve its state.
class PantryShell extends ConsumerStatefulWidget {
  /// Creates a [PantryShell] widget.
  const PantryShell({super.key});

  @override
  ConsumerState<PantryShell> createState() => _PantryShellState();
}

class _PantryShellState extends ConsumerState<PantryShell> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showChangelogIfPending());
    });
    unawaited(_showNotificationDeniedWarning());
    unawaited(_showAmoledNudge());
  }

  Future<void> _showNotificationDeniedWarning() async {
    try {
      final flags = await ref.read(uiFlagsProvider.future);
      if (!flags.notificationDeniedWarning) return;

      ref
          .read(uiFlagsProvider.notifier)
          .setNotificationDeniedWarning(
            value: false,
          );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showInfo(context, l10n.notificationDeniedWarning);
      });
    } on Exception catch (e) {
      logWarning('Failed to show notification denied warning: $e');
    }
  }

  Future<void> _showAmoledNudge() async {
    try {
      final flags = await ref.read(uiFlagsProvider.future);
      if (flags.amoledNudgeShown) return;
      if (!mounted) return;

      final brightness = MediaQuery.of(context).platformBrightness;
      if (brightness == Brightness.dark) return;

      ref.read(uiFlagsProvider.notifier).setAmoledNudgeShown(value: true);

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.amoledNudgeTitle),
            content: Text(l10n.amoledNudgeBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.amoledNudgeDismiss),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.amoledNudgeEnable),
              ),
            ],
          ),
        );
        if (result == true && mounted) {
          ref
              .read(themeModeProvider.notifier)
              .setThemeMode(ThemeModeOption.dark);

          if (mounted) {
            SnackbarHelper.showInfo(
              context,
              l10n.amoledDarkModeEnabled,
            );
          }
        }
      });
    } on Exception catch (e) {
      logWarning('Failed to show AMOLED nudge: $e');
    }
  }

  void _onConnectivityChanged(
    AsyncValue<bool>? prev,
    AsyncValue<bool> next,
  ) {
    // The one-shot check caches its first result for the whole session;
    // invalidate it on every connectivity change so the 8 call sites get
    // fresh answers (e.g. an app started offline sees the device come
    // online without a restart).
    ref.invalidate(hasConnectionProvider);

    final online = next.asData?.value;
    if (online == true) {
      final submissionService = ref.read(productSubmissionServiceProvider);
      unawaited(submissionService.flushQueue());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showChangelogIfPending() async {
    try {
      final locale = Localizations.localeOf(context);
      final flags = await ref.read(uiFlagsProvider.future);
      if (!flags.changelogShowPending) {
        logInfo('No changelog show pending — skipping');
        return;
      }

      final raw = await loadLocalizedChangelog(locale);

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showWhatsNewSheet(context, rawChangelog: raw);
        ref
            .read(uiFlagsProvider.notifier)
            .setChangelogShowPending(
              value: false,
            );
      });
    } on Exception catch (e) {
      logError('Failed to show changelog: $e');
      ref.read(uiFlagsProvider.notifier).setChangelogShowPending(value: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(connectivityProvider, _onConnectivityChanged);

    final pendingCount = ref.watch(pendingShoppingCountProvider).value ?? 0;

    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: TickerMode(
          enabled: true,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            children: const [
              HomeScreen(),
              RecipeListScreen(),
              StatsScreen(),
              ShoppingListScreen(),
              SettingsScreen(),
            ], // children
          ), // PageView
        ), // TickerMode
      ), // SafeArea
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          unawaited(
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: l10n.navRecipes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  )
                : const Icon(Icons.shopping_cart_outlined),
            selectedIcon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.shopping_cart),
                  )
                : const Icon(Icons.shopping_cart),
            label: l10n.navList,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
