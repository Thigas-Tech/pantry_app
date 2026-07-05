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
/// Uses an [IndexedStack] so that each tab preserves its state when
/// the user switches between them.
class PantryShell extends ConsumerStatefulWidget {
  /// Creates a [PantryShell] widget.
  const PantryShell({super.key});

  @override
  ConsumerState<PantryShell> createState() => _PantryShellState();
}

class _PantryShellState extends ConsumerState<PantryShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          SearchScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
