import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
