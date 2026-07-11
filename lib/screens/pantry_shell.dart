import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/shopping_list_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/changelog_parser.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The root shell that holds the [NavigationBar] and switches between
/// the main app screens.
///
/// Tabs:
/// - **Home** — inventory dashboard with grouping by expiry status.
/// - **Search** — product search by name or barcode.
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
    unawaited(_showChangelogIfPending());
    unawaited(_showNotificationDeniedWarning());
    unawaited(_showAmoledNudge());
  }

  Future<void> _showNotificationDeniedWarning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showWarning = prefs.getBool('notification_denied_warning') == true;
      if (!showWarning) return;

      await prefs.setBool('notification_denied_warning', false);

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
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool('amoled_nudge_shown') == true;
      if (alreadyShown) return;
      if (!mounted) return;

      final brightness = MediaQuery.of(context).platformBrightness;
      if (brightness == Brightness.dark) return;

      await prefs.setBool('amoled_nudge_shown', true);

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
          ref.read(themeModeProvider.notifier).value = ThemeModeOption.dark;
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
    final online = next.asData?.value;
    if (online == true) {
      final feedbackService = ref.read(githubIssueServiceProvider);
      unawaited(feedbackService.flushQueue());
      final submissionService = ref.read(productSubmissionServiceProvider);
      unawaited(submissionService.flushQueue());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// The [SharedPreferences] key for tracking which version the user last
  /// saw in the auto‑displayed changelog sheet.
  static const _changelogLastSeenVersionKey = 'changelog_last_seen_version';

  Future<void> _showChangelogIfPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showPending = prefs.getString('changelog_show_pending') == 'true';
      if (!showPending) {
        logInfo('No changelog show pending — skipping');
        return;
      }

      final raw = await rootBundle.loadString('CHANGELOG.md');
      final parser = ChangelogParser();
      final allEntries = parser.parse(raw);

      if (allEntries.isEmpty) {
        logError('Changelog parsed but produced no entries');
        return;
      }

      // Show only the entries the user has NOT seen yet — not the
      // entire changelog history. [Unreleased] is always included.
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';
      final lastSeen = prefs.getString(_changelogLastSeenVersionKey) ?? '0.0.0';
      final unseen = parser.filterUnseen(allEntries, lastSeen, currentVersion);

      if (unseen.isEmpty) {
        logInfo('All changelog entries already seen — skipping');
        await prefs.setString('changelog_show_pending', 'false');
        return;
      }

      logInfo(
        'Showing changelog: ${unseen.length} entries '
        '(last seen $lastSeen → $currentVersion)',
      );

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showWhatsNewSheet(context, unseen);
        await prefs.setString('changelog_show_pending', 'false');
        await prefs.setString(
          _changelogLastSeenVersionKey,
          currentVersion,
        );
      });
    } on Exception catch (e) {
      logError('Failed to show changelog: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('changelog_show_pending', 'false');
      } on Exception catch (e) {
        logWarning('Failed to reset changelog flag during cleanup: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(connectivityProvider, _onConnectivityChanged);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          HomeScreen(),
          SearchScreen(),
          StatsScreen(),
          ShoppingListScreen(),
          SettingsScreen(),
        ],
      ),
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
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n.navSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
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
