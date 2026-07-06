import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/screens/coming_soon_screen.dart';

/// A placeholder screen for pantry statistics.
///
/// The original CSV import/export and aggregated statistics have been
/// temporarily removed. This screen will be restored with a proper
/// implementation in a future release.
class StatsScreen extends StatelessWidget {
  /// Creates a [StatsScreen].
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ComingSoonScreen(title: l10n.pantryStats);
  }
}
