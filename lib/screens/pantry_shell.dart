import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/changelog_parser.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The root shell that holds the [NavigationBar] and switches between
/// the main app screens.
///
/// Tabs:
/// - **Home** — inventory dashboard with grouping by expiry status.
/// - **Search** — product search by name or barcode.
/// - **Stats** — inventory statistics and CSV export/import.
/// - **Settings** — application preferences.
///
/// Uses a [PageView] so that users can swipe horizontally between tabs.
/// Each tab uses `AutomaticKeepAliveClientMixin` to preserve its state.
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
  }

  void _onConnectivityChanged(
    AsyncValue<bool>? prev,
    AsyncValue<bool> next,
  ) {
    final online = next.asData?.value;
    if (online == true) {
      final service = ref.read(githubIssueServiceProvider);
      unawaited(service.flushQueue());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

      // Content-hash detection already guarantees this runs only when the
      // changelog content has changed. Show all parsed entries.
      logInfo('Showing changelog: ${allEntries.length} entries');

      // Wait for the first frame so the sheet overlay has a valid context.
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showWhatsNewSheet(context, allEntries);
        await prefs.setString('changelog_show_pending', 'false');
      });
    } on Exception catch (e) {
      logError('Failed to show changelog: $e');
      // Reset the flag so it doesn't block the next launch.
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
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
