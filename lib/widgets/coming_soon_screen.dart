import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// Placeholder shown in place of a feature that has not shipped yet.
///
/// Renders a centered icon, title, and description with no data access, so
/// the tab can exist in the navigation before its content is implemented.
class ComingSoonScreen extends StatelessWidget {
  /// Creates a [ComingSoonScreen].
  const ComingSoonScreen({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  /// The icon shown above the title.
  final IconData icon;

  /// The localized feature title.
  final String title;

  /// The localized explanation shown below the title.
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The statistics tab placeholder.
///
/// Uses [ComingSoonScreen] with the localized statistics strings so the
/// Stats tab stays navigable while the feature is not implemented.
class StatsComingSoonScreen extends StatelessWidget {
  /// Creates a [StatsComingSoonScreen].
  const StatsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ComingSoonScreen(
      icon: Icons.insert_chart_outlined,
      title: l10n.statsComingSoonTitle,
      description: l10n.statsComingSoonDescription,
    );
  }
}
